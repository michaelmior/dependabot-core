# typed: strict
# frozen_string_literal: true

# These all need to be required so the various classes can be registered in a
# lookup table of package manager names to concrete classes.
require "dependabot/sbt/file_fetcher"
require "dependabot/sbt/requirement"
require "dependabot/sbt/version"

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler
  .register_label_details("sbt", name: "scala", colour: "ffa221")

require "dependabot/dependency"
Dependabot::Dependency
  .register_production_check("sbt", ->(groups) { groups != ["test"] })

Dependabot::Dependency
  .register_display_name_builder(
    "sbt",
    lambda { |name|
      _group_id, artifact_id = name.split(":")
      name.length <= 100 ? name : artifact_id
    }
  )
