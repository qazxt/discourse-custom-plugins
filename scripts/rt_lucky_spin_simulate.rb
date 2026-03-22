# frozen_string_literal: true
u = User.first
abort("no user") unless u

RtLuckySpin::DailyGrant.grant_if_needed!(u)
grants = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :daily_grant).count
consumes = RtLuckySpin::SpinEvent.where(user_id: u.id, event_type: :spin_consumed).count
avail = [grants - consumes, 0].max
puts "ok grants=#{grants} consumes=#{consumes} avail=#{avail}"
