# frozen_string_literal: true

# 为 /lucky-spin、/lucky-spin/admin 提供 HTML 外壳，供直接访问 Rails（:3000）、硬刷新或爬虫命中。
# 否则这些路径不会匹配任何 Rails 路由（permalink 仅在有 Permalink 记录时命中），会报 Routing Error。
module ::RtLuckySpin
  class LuckySpinHtmlController < ::ApplicationController
    requires_plugin ::RtLuckySpin::PLUGIN_NAME

    skip_before_action :check_xhr, only: %i[index admin]

    before_action :ensure_enabled
    before_action :ensure_logged_in

    def index
      respond_to do |format|
        format.html { render html: "", layout: application_layout }
      end
    end

    def admin
      raise Discourse::InvalidAccess unless guardian.is_admin?

      respond_to do |format|
        format.html { render html: "", layout: application_layout }
      end
    end

    private

    def ensure_enabled
      raise Discourse::NotFound unless SiteSetting.rt_lucky_spin_enabled
    end
  end
end
