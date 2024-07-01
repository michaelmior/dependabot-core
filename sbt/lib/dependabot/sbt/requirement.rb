# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

require "dependabot/requirement"
require "dependabot/utils"
require "dependabot/sbt/version"

module Dependabot
  module Sbt
    class Requirement < Dependabot::Requirement
      extend T::Sig

      quoted = OPS.keys.map { |k| Regexp.quote k }.join("|")
      OR_SYNTAX = /(?<=\]|\)),/
      PATTERN_RAW = "\\s*(#{quoted})?\\s*(#{Sbt::Version::VERSION_PATTERN})\\s*".freeze
      PATTERN = /\A#{PATTERN_RAW}\z/

      def self.parse(obj)
        return ["=", Sbt::Version.new(obj.to_s)] if obj.is_a?(Gem::Version)

        unless (matches = PATTERN.match(obj.to_s))
          msg = "Illformed requirement [#{obj.inspect}]"
          raise BadRequirementError, msg
        end

        return DefaultRequirement if matches[1] == ">=" && matches[2] == "0"

        [matches[1] || "=", Sbt::Version.new(T.must(matches[2]))]
      end

      sig { override.params(requirement_string: T.nilable(String)).returns(T::Array[Requirement]) }
      def self.requirements_array(requirement_string)
        split_scala_requirement(requirement_string).map do |str|
          new(str)
        end
      end

      def initialize(*requirements)
        requirements = requirements.flatten.flat_map do |req_string|
          convert_scala_constraint_to_ruby_constraint(req_string)
        end

        super(requirements)
      end

      def satisfied_by?(version)
        version = Sbt::Version.new(version.to_s)
        super
      end

      private

      def self.split_scala_requirement(req_string)
        return [req_string] unless req_string.match?(OR_SYNTAX)

        req_string.split(OR_SYNTAX).flat_map do |str|
          next str if str.start_with?("(", "[")

          exacts, *rest = str.split(/,(?=\[|\()/)
          [*exacts.split(","), *rest]
        end
      end
      private_class_method :split_scala_requirement

      def convert_scala_constraint_to_ruby_constraint(req_string)
        return unless req_string

        if self.class.send(:split_scala_requirement, req_string).count > 1
          raise "Can't convert multiple Scala reqs to a single Ruby one"
        end

        # NOTE: Support ruby-style version requirements that are created from
        # PR ignore conditions
        version_reqs = req_string.split(",").map(&:strip)
        if req_string.include?(",") && !version_reqs.all? { |s| PATTERN.match?(s) }
          convert_scala_range_to_ruby_range(req_string) if req_string.include?(",")
        else
          version_reqs.map { |r| convert_scala_equals_req_to_ruby(r) }
        end
      end

      def convert_scala_range_to_ruby_range(req_string)
        lower_b, upper_b = req_string.split(",").map(&:strip)

        lower_b =
          if ["(", "["].include?(lower_b) then nil
          elsif lower_b.start_with?("(") then "> #{lower_b.sub(/\(\s*/, '')}"
          else
            ">= #{lower_b.sub(/\[\s*/, '').strip}"
          end

        upper_b =
          if [")", "]"].include?(upper_b) then nil
          elsif upper_b.end_with?(")") then "< #{upper_b.sub(/\s*\)/, '')}"
          else
            "<= #{upper_b.sub(/\s*\]/, '').strip}"
          end

        [lower_b, upper_b].compact
      end

      def convert_scala_equals_req_to_ruby(req_string)
        return convert_wildcard_req(req_string) if req_string&.end_with?("+")

        # If a soft requirement is being used, treat it as an equality matcher
        return req_string unless req_string&.start_with?("[")

        req_string.gsub(/[\[\]\(\)]/, "")
      end

      def convert_wildcard_req(req_string)
        version = req_string.split("+").first
        return ">= 0" if version.nil? || version.empty?

        version += "0" if version.end_with?(".")
        "~> #{version}"
      end
    end
  end
end

Dependabot::Utils
  .register_requirement_class("sbt", Dependabot::Sbt::Requirement)
