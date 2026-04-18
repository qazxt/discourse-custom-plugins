# frozen_string_literal: true

module ::RtLuckySpin
  class SpinsController < ::ApplicationController
    requires_plugin ::RtLuckySpin::PLUGIN_NAME

    # Ember dev proxy（4200）等场景下可能缺少 XHR / JSON Accept，会触发 ApplicationController#check_xhr → RenderEmpty，
    # 在挂载引擎里偶发表现为 500。此处为纯 JSON API，跳过 xhr 检查。
    skip_before_action :check_xhr, only: %i[state history spin]

    before_action :ensure_enabled
    # 勿在本控制器定义 ensure_logged_in 去调 guardian.ensure_logged_in：Guardian 无该方法，会 NoMethodError。
    # 使用 ApplicationController#ensure_logged_in 即可。
    before_action :ensure_logged_in

    def state
      maybe_grant_daily!
      # 勿对 Hash 使用 render_serialized：ApplicationSerializer 需要带属性的对象，否则易 500
      render json: {
               available_spins: available_spins_for(current_user),
               today_granted: today_granted?(current_user),
               segments: wheel_segments_config,
               rules_title:
                 SiteSetting.rt_lucky_spin_rules_title.to_s.presence ||
                   I18n.t("js.rt_lucky_spin.rules_title"),
               rules_html: cooked_rules_html,
               prize_image_url: prize_image_url,
               prize_intro_html: cooked_prize_intro_html,
             }
    end

    def history
      events = RtLuckySpin::SpinEvent.where(user_id: current_user.id).order(id: :desc).limit(50)
      render_serialized(events, RtLuckySpin::SpinEventSerializer)
    end

    def spin
      maybe_grant_daily!

      if available_spins_for(current_user) <= 0
        render json: { error: "no_spins" }, status: 422
        return
      end

      result = pick_result

      ActiveRecord::Base.transaction do
        RtLuckySpin::SpinEvent.create!(
          user_id: current_user.id,
          event_type: RtLuckySpin::SpinEvent.event_types[:spin_consumed],
          awarded_at: Time.zone.now
        )

        case result[:type]
        when :points
          points = result[:points]
          RtLuckySpin::GamificationAdapter.award_points!(
            user: current_user,
            points: points,
            label: SiteSetting.rt_lucky_spin_points_source_label
          )

          RtLuckySpin::SpinEvent.create!(
            user_id: current_user.id,
            event_type: RtLuckySpin::SpinEvent.event_types[:spin_points],
            points: points,
            awarded_at: Time.zone.now
          )

          send_user_pm!("你抽中了 #{points} 分奖励。")
          render json: { type: "points", points: points }
        when :no_prize
          RtLuckySpin::SpinEvent.create!(
            user_id: current_user.id,
            event_type: RtLuckySpin::SpinEvent.event_types[:spin_no_prize],
            awarded_at: Time.zone.now
          )
          send_user_pm!("Better luck next time!")
          render json: { type: "no_prize" }
        when :product
          prize_name = RtLuckySpin::WeeklyPrizePicker.claim_product_prize_for_user!(
            user: current_user
          )

          if prize_name.present?
            RtLuckySpin::SpinEvent.create!(
              user_id: current_user.id,
              event_type: RtLuckySpin::SpinEvent.event_types[:spin_product_prize],
              product_prize_name: prize_name,
              awarded_at: Time.zone.now
            )
            send_user_pm!("你抽中了产品奖励：#{prize_name}。管理员会联系你进行发货。")
            notify_admin_for_product!(prize_name)
            render json: { type: "product", name: prize_name }
          else
            # 处理并发竞争：本轮 wheel 选中了 product 扇区，但名额刚好被别的请求先消耗完。
            RtLuckySpin::SpinEvent.create!(
              user_id: current_user.id,
              event_type: RtLuckySpin::SpinEvent.event_types[:spin_no_prize],
              awarded_at: Time.zone.now
            )
            send_user_pm!("Better luck next time!")
            render json: { type: "no_prize" }
          end
        else
          raise ::RtLuckySpin::Error, "unknown result"
        end
      end
    rescue ::RtLuckySpin::Error => e
      render json: { error: e.message }, status: 500
    rescue StandardError => e
      Rails.logger.error(
        "[rt-lucky-spin] spins#spin #{e.class}: #{e.message}\n#{e.backtrace&.first(20)&.join("\n")}"
      )
      render json: { error: e.message, error_class: e.class.name }, status: 500
    end

    private

    def ensure_enabled
      raise Discourse::NotFound unless SiteSetting.rt_lucky_spin_enabled
    end

    def today
      Time.zone.today
    end

    def today_granted?(user)
      RtLuckySpin::SpinEvent.exists?(user_id: user.id, event_type: RtLuckySpin::SpinEvent.event_types[:daily_grant], grant_date: today)
    end

    def maybe_grant_daily!
      RtLuckySpin::DailyGrant.grant_if_needed!(current_user)
    end

    def available_spins_for(user)
      grants = RtLuckySpin::SpinEvent.where(user_id: user.id, event_type: RtLuckySpin::SpinEvent.event_types[:daily_grant]).count
      consumes = RtLuckySpin::SpinEvent.where(user_id: user.id, event_type: RtLuckySpin::SpinEvent.event_types[:spin_consumed]).count
      [grants - consumes, 0].max
    end

    def pick_result
      now = Time.zone.now
      product_eligible = RtLuckySpin::WeeklyPrizePicker.product_prize_eligible?(now: now)

      # 方案 A：末尾窗口（weekly_force_window_hours）且本周还没人中产品奖时，直接保底出一次 product。
      # 这里不提前消耗名额，真正写 winner_user_id 在 :product 分支里 claim。
      if product_eligible && RtLuckySpin::WeeklyPrizePicker.force_window?(now)
        return { type: :product }
      end

      weights = wheel_segments_config.filter_map do |seg|
        weight = seg[:weight].to_i
        next if weight <= 0
        next if seg[:type] == "product" && !product_eligible

        if seg[:type] == "points"
          { type: :points, points: seg[:points].to_i, weight: weight }
        elsif seg[:type] == "product"
          { type: :product, weight: weight }
        else
          { type: :no_prize, weight: weight }
        end
      end

      total = weights.sum { |w| w[:weight] }
      raise ::RtLuckySpin::Error, "invalid weights" if total <= 0

      r = SecureRandom.random_number(total)
      weights.each do |w|
        r -= w[:weight]
        return w if r < 0
      end

      weights.last
    end

    def wheel_segments_config
      [
        points_segment(1),
        points_segment(2),
        points_segment(3),
        {
          key: "product",
          type: "product",
          label: SiteSetting.rt_lucky_spin_segment_product_label.to_s.presence || "Product",
          weight: SiteSetting.rt_lucky_spin_segment_product_weight.to_i
        },
        {
          key: "no_prize",
          type: "no_prize",
          label: SiteSetting.rt_lucky_spin_segment_no_prize_label.to_s.presence || "No prize",
          weight: SiteSetting.rt_lucky_spin_segment_no_prize_weight.to_i
        }
      ]
    end

    def points_segment(idx)
      label = SiteSetting.public_send("rt_lucky_spin_segment_points_#{idx}_label").to_s
      points = SiteSetting.public_send("rt_lucky_spin_segment_points_#{idx}_value").to_i
      weight = SiteSetting.public_send("rt_lucky_spin_segment_points_#{idx}_weight").to_i
      {
        key: "points_#{idx}",
        type: "points",
        label: label.presence || points.to_s,
        points: [points, 1].max,
        weight: weight
      }
    end

    def cooked_rules_html
      raw = SiteSetting.rt_lucky_spin_rules_rich_text.to_s
      return "" if raw.blank?

      PrettyText.cook(raw).to_s
    end

    def prize_image_url
      raw = SiteSetting.rt_lucky_spin_prize_image
      upload_id =
        if raw.respond_to?(:id)
          raw.id
        else
          raw.to_i
        end

      return nil if upload_id <= 0

      Upload.find_by(id: upload_id)&.url
    end

    def cooked_prize_intro_html
      raw = SiteSetting.rt_lucky_spin_prize_intro.to_s
      return "" if raw.blank?

      PrettyText.cook(raw).to_s
    end

    def send_user_pm!(raw)
      PostCreator.create!(
        Discourse.system_user,
        target_usernames: current_user.username,
        archetype: Archetype.private_message,
        title: "Lucky Spin",
        raw: raw
      )
    rescue StandardError => e
      # 开发环境常见：用户未开私信、rate limit、站点配置等；不应导致抽奖 API 500
      Rails.logger.warn("[rt-lucky-spin] send_user_pm! failed: #{e.class} #{e.message}")
    end

    def notify_admin_for_product!(prize_name)
      username = SiteSetting.rt_lucky_spin_admin_notify_username.to_s.strip
      return if username.blank?

      admin = User.find_by(username: username)
      return if admin.blank?

      PostCreator.create!(
        Discourse.system_user,
        target_usernames: admin.username,
        archetype: Archetype.private_message,
        title: "Lucky Spin - 产品奖提醒",
        raw: "用户 @#{current_user.username} 抽中了产品奖励：#{prize_name}，请安排发货。"
      )
    rescue StandardError => e
      Rails.logger.warn("[rt-lucky-spin] notify_admin_for_product! failed: #{e.class} #{e.message}")
    end
  end
end

