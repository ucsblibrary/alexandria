# frozen_string_literal: true

require "rails_helper"

describe ApplicationController do
  def stub_remote_ip(ip_addr)
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip) { ip_addr }
  end

  describe "#on_campus?" do
    it "designates whether or not the user is on campus" do
      stub_remote_ip("123.456.789.111")
      expect(controller.on_campus?).to eq false

      stub_remote_ip("128.111.111.111")
      expect(controller.on_campus?).to eq true

      stub_remote_ip("169.231.111.111")
      expect(controller.on_campus?).to eq true

      stub_remote_ip(nil)
      expect(controller.on_campus?).to eq false
    end
  end
end
