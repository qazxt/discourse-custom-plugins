# frozen_string_literal: true

module ::RtLuckySpin
  class GamificationAdapter
    def self.enabled?
      defined?(::DiscourseGamification) || defined?(::Gamification)
    end

    def self.award_points!(user:, points:, label:)
      raise ::RtLuckySpin::Error, "gamification not available" unless enabled?
      raise ::RtLuckySpin::Error, "invalid points" unless points.to_i > 0

      # 多版本兼容：优先走“公开 API/服务对象”，否则回退到写入 gamification_scores。
      if defined?(::Gamification::ScoreManager) && ::Gamification::ScoreManager.respond_to?(:award_custom)
        ::Gamification::ScoreManager.award_custom(user, points, label)
        return
      end

      if defined?(::DiscourseGamification::ScoreManager) &&
           ::DiscourseGamification::ScoreManager.respond_to?(:award_custom)
        ::DiscourseGamification::ScoreManager.award_custom(user, points, label)
        return
      end

      if defined?(::GamificationScore) # 旧命名
        ::GamificationScore.create!(user_id: user.id, score: points, created_at: Time.zone.now, updated_at: Time.zone.now)
        return
      end

      if ActiveRecord::Base.connection.data_source_exists?("gamification_scores")
        ActiveRecord::Base.connection.exec_insert(
          "INSERT INTO gamification_scores (user_id, score, created_at, updated_at) VALUES ($1,$2,$3,$4)",
          "SQL",
          [
            [nil, user.id],
            [nil, points.to_i],
            [nil, Time.zone.now],
            [nil, Time.zone.now]
          ]
        )
        return
      end

      raise ::RtLuckySpin::Error, "no compatible gamification award method"
    end
  end
end

