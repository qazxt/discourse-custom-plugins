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
      product_eligible = RtLuckySpin::WeeklyPrizePicker.product_prize_eligible?(now: Time.zone.now)

      weights = [
        { type: :points, points: 100, weight: SiteSetting.rt_lucky_spin_points_100_weight.to_i },
        { type: :points, points: 25, weight: SiteSetting.rt_lucky_spin_points_25_weight.to_i },
        { type: :points, points: 5, weight: SiteSetting.rt_lucky_spin_points_5_weight.to_i },
        { type: :no_prize, weight: SiteSetting.rt_lucky_spin_no_prize_weight.to_i }
      ].select { |w| w[:weight].to_i > 0 }
      weights << { type: :product, weight: 1 } if product_eligible

      total = weights.sum { |w| w[:weight] }
      raise ::RtLuckySpin::Error, "invalid weights" if total <= 0

      r = SecureRandom.random_number(total)
      weights.each do |w|
        r -= w[:weight]
        return w if r < 0
      end

      weights.last
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

