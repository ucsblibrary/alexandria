# coding: utf-8
# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::CLI do
  describe "::make_logger" do
    subject do
      described_class.make_logger(
        output: Rails.root.join("tmp", "honk.log"),
        level: loglevel
      ).level
    end

    context "with non-default log level" do
      let(:loglevel) { "Error" }

      it "sets the log level" do
        expect(subject).to eq Logger::ERROR
      end
    end

    context "with invalid log level" do
      let(:loglevel) { "HONK" }

      it "reverts to the default log level" do
        expect(subject).to eq Logger::INFO
      end
    end
  end
end
