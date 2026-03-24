# frozen_string_literal: true
# 给 user1 增加若干次「签到赠送」次数（daily_grant）。用法：./d/rails runner plugins/rt-lucky-spin/script/grant_extra_spins.rb

u = User.find_by(username: "user1")
raise "user user1 not found" unless u

ADD = 30
ADD.times do
  RtLuckySpin::SpinEvent.create!(
    user_id: u.id,
    event_type: :daily_grant,
    grant_date: Date.current
  )
end

grants = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :daily_grant).count
cons = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :spin_consumed).count

puts "已增加 #{ADD} 次 grants。user=#{u.username} daily_grants=#{grants} spin_consumed=#{cons} available=#{grants - cons}"
