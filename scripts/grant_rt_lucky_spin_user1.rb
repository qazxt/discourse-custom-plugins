# frozen_string_literal: true
# 一次性脚本：给 user1 增加转盘次数（daily_grant）。用法：在 Discourse 根目录 ./d/rails runner /path/to/本文件

u = User.find_by(username: "user1")
raise "user user1 not found" unless u

ADD = 20
ADD.times do
  RtLuckySpin::SpinEvent.create!(
    user_id: u.id,
    event_type: :daily_grant,
    grant_date: Date.current
  )
end

grants = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :daily_grant).count
cons = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :spin_consumed).count

puts "user=#{u.username} daily_grants=#{grants} spin_consumed=#{cons} available=#{grants - cons}"
