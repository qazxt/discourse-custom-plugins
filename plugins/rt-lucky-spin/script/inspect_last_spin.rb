# frozen_string_literal: true
# 用法（Discourse 根目录，容器内 /src）: bin/rails runner plugins/rt-lucky-spin/script/inspect_last_spin.rb

puts "--- rt_lucky_spin_spin_events (最新 12 条，勿用 find_each 会打乱排序) ---"
RtLuckySpin::SpinEvent.order(id: :desc).limit(12).each do |r|
  puts "#{r.id}\tuser=#{r.user_id}\t#{r.event_type}\tpoints=#{r.points.inspect}\t#{r.awarded_at}"
end

if defined?(DiscourseGamification::GamificationScoreEvent)
  puts "\n--- gamification_score_events (最新 8 条) ---"
  DiscourseGamification::GamificationScoreEvent.order(id: :desc).limit(8).each do |r|
    desc = r.description.to_s.tr("\n", " ")[0, 40]
    puts "#{r.id}\tuser=#{r.user_id}\tpoints=#{r.points}\t#{desc}\t#{r.created_at}"
  end
end

if defined?(DiscourseGamification::GamificationScore)
  puts "\n--- gamification_scores 今天 (按 score 降序 前 8) ---"
  DiscourseGamification::GamificationScore.where(date: Date.today).order(score: :desc).limit(8).each do |r|
    puts "user=#{r.user_id}\tdate=#{r.date}\tscore=#{r.score}"
  end
end

puts "\n完成"
