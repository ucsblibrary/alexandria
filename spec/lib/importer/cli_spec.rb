# coding: utf-8
# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::CLI do
  describe "::find_paths" do
    context "with a file in subdirectories" do
      subject { described_class.find_paths([tmpdir]) }

      let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

      it "finds the nested file" do
        FileUtils.mkdir_p tmpdir.join("nested", "directories")
        FileUtils.touch tmpdir.join("nested", "directories", "with_a_file")

        expect(subject).to(
          contain_exactly(
            tmpdir.join("nested", "directories", "with_a_file").to_s
          )
        )
      end
    end

    context "with no files" do
      subject { described_class.find_paths([tmpdir]) }

      let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

      it "finds nothing" do
        FileUtils.mkdir_p tmpdir.join("nested", "directories")

        expect(subject).to be_empty
      end
    end
  end

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
