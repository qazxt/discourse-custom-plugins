# frozen_string_literal: true

module ::RtLuckySpin
  class AdminController < ::ApplicationController
    requires_plugin ::RtLuckySpin::PLUGIN_NAME

    before_action :ensure_enabled
    before_action :ensure_admin

    def weekly
      week_start = RtLuckySpin::WeeklyPrizePicker.week_start_date
      prizes = RtLuckySpin::WeeklyPrize.includes(:winner).where(week_start_date: week_start).order(:prize_name)
      render_serialized(prizes, RtLuckySpin::WeeklyPrizeSerializer)
    end

    def update_shipping
      prize = RtLuckySpin::WeeklyPrize.find_by(id: params[:id])
      raise Discourse::NotFound if prize.blank?

      status = params.require(:shipping_status).to_s
      raise Discourse::InvalidParameters unless RtLuckySpin::WeeklyPrize.shipping_statuses.key?(status)

      prize.update!(
        shipping_status: status,
        shipping_note: (params[:shipping_note] if params.key?(:shipping_note))
      )

      render_serialized(prize, RtLuckySpin::WeeklyPrizeSerializer)
    end

    private

    def ensure_enabled
      raise Discourse::NotFound unless SiteSetting.rt_lucky_spin_enabled
    end

    def ensure_admin
      guardian.ensure_logged_in
      raise Discourse::InvalidAccess unless guardian.is_admin?
    end
  end
end

