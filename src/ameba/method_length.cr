require "ameba"

require "./method_length/version"

module Ameba::Rule::Metrics
  # A rule that disallows methods longer than `MaxLines` lines.
  # Long methods are hard to read, test, and maintain; they should be
  # split into smaller, well-named submethods.
  #
  # Lines are counted from the `def` keyword to the closing `end`, inclusive.
  #
  # YAML configuration example:
  #
  # ```
  # Metrics/MethodLength:
  #   Enabled: true
  #   MaxLines: 15
  # ```
  class MethodLength < Base
    properties do
      description "Disallows methods longer than `MaxLines` lines"
      max_lines 15
    end

    MSG = "Method is too long [%d/%d lines]"

    def test(source, node : Crystal::Def)
      loc = node.location
      end_loc = node.end_location
      return unless loc && end_loc

      lines = end_loc.line_number - loc.line_number + 1
      return unless lines > max_lines

      issue_for(node, MSG % {lines, max_lines}, prefer_name_location: true)
    end
  end
end
