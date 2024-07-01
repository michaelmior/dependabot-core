# typed: strict
# frozen_string_literal: true

require "nokogiri"
require "sorbet-runtime"

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module Sbt
    class FileFetcher < Dependabot::FileFetchers::Base
      extend T::Sig
      extend T::Helpers

      MODULE_SELECTOR = "project > modules > module, " \
                        "profile > modules > module"

      sig { override.params(filenames: T::Array[String]).returns(T::Boolean) }
      def self.required_files_in?(filenames)
        filenames.include?("build.sbt")
      end

      sig { override.returns(String) }
      def self.required_files_message
        "Repo must contain a build.sbt."
      end

      sig { override.returns(T::Array[DependencyFile]) }
      def fetch_files
        fetched_files = []
        fetched_files << build_sbt
        fetched_files << plugins if plugins
        fetched_files.uniq
      end

      private

      sig { returns(T.nilable(Dependabot::DependencyFile)) }
      def build_sbt
        @build_sbt ||= T.let(fetch_file_from_host("build.sbt"), T.nilable(Dependabot::DependencyFile))
      end

      sig { returns(T.nilable(Dependabot::DependencyFile)) }
      def plugins
        @plugins ||= T.let(fetch_file_if_present("project/plugins.sbt"), T.nilable(Dependabot::DependencyFile))
      end
    end
  end
end

Dependabot::FileFetchers.register("sbt", Dependabot::Sbt::FileFetcher)
