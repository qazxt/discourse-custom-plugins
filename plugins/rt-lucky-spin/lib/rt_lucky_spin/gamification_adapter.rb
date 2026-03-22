# frozen_string_literal: true

module ::RtLuckySpin
  class GamificationAdapter
    def self.enabled?
      defined?(::DiscourseGamification) || defined?(::Gamification)
    end

    def self.award_points!(user:, points:, label:)
      raise ::RtLuckySpin::Error, "gamification not available" unless enabled?
      raise ::RtLuckySpin::Error, "invalid points" unless points.to_i > 0

      pts = points.to_i
      desc = label.to_s.presence || "Lucky Spin"

      # 新版 discourse-gamification：GamificationScoreEvent + 重算（无 ScoreManager.award_custom）
      if defined?(::DiscourseGamification::GamificationScoreEvent) &&
           ActiveRecord::Base.connection.data_source_exists?("gamification_score_events")
        ::DiscourseGamification::GamificationScoreEvent.create!(
          user_id: user.id,
          date: Time.zone.today,
          points: pts,
          description: desc
        )
        if defined?(::DiscourseGamification::GamificationScore) &&
             ::DiscourseGamification::GamificationScore.respond_to?(:calculate_scores)
          ::DiscourseGamification::GamificationScore.calculate_scores(since_date: Time.zone.today)
        end
        return
      end

      # 多版本兼容：旧 ScoreManager API
      if defined?(::Gamification::ScoreManager) && ::Gamification::ScoreManager.respond_to?(:award_custom)
        ::Gamification::ScoreManager.award_custom(user, pts, desc)
        return
      end

      if defined?(::DiscourseGamification::ScoreManager) &&
           ::DiscourseGamification::ScoreManager.respond_to?(:award_custom)
        ::DiscourseGamification::ScoreManager.award_custom(user, pts, desc)
        return
      end

      if defined?(::GamificationScore) # 旧命名
        ::GamificationScore.create!(user_id: user.id, score: pts, created_at: Time.zone.now, updated_at: Time.zone.now)
        return
      end

      # gamification_scores 表结构为 (user_id, date, score)，勿用 created_at 列
      if ActiveRecord::Base.connection.data_source_exists?("gamification_scores")
        today = Time.zone.today
        sql = ActiveRecord::Base.sanitize_sql_array(
          [
            <<~SQL.squish,
              INSERT INTO gamification_scores (user_id, date, score)
              VALUES (?, ?, ?)
              ON CONFLICT (user_id, date) DO UPDATE SET score = gamification_scores.score + EXCLUDED.score
            SQL
            user.id,
            today,
            pts
          ]
        )
        ActiveRecord::Base.connection.execute(sql)
        return
      end

      raise ::RtLuckySpin::Error, "no compatible gamification award method"
    end
  end
end

