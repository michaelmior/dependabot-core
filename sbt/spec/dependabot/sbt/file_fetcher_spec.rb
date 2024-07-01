# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/sbt/file_fetcher"
require_common_spec "file_fetchers/shared_examples_for_file_fetchers"

RSpec.describe Dependabot::Sbt::FileFetcher do
  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:url) { github_url + "repos/scala/scala3-example-project/contents/" }
  let(:github_url) { "https://api.github.com/" }
  let(:directory) { "/" }
  let(:file_fetcher_instance) do
    described_class.new(source: source, credentials: credentials)
  end
  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "scala/scala3-example-project",
      directory: directory
    )
  end

  it_behaves_like "a dependency file fetcher"

  describe ".required_files_in?" do
    subject { described_class.required_files_in?(filenames) }

    context "with only a build.sbt" do
      let(:filenames) { %w(build.sbt) }

      it { is_expected.to be(true) }
    end
    context "with a non .sbt file" do
      let(:filenames) { %w(nonsbt.txt) }

      it { is_expected.to be(false) }
    end

    context "with no files passed" do
      let(:filenames) { %w() }

      it { is_expected.to be(false) }
    end
  end

  context "with a basic build.sbt" do
    before do
      stub_request(:get, File.join(url, "build.sbt?ref=sha"))
        .with(headers: { "Authorization" => "token token" })
        .to_return(
          status: 200,
          body: fixture("github", "contents_scala_basic__build_sbt.json"),
          headers: { "content-type" => "application/json" }
        )
    end
  end
end
