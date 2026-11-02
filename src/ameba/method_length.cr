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
  #   CountAsOne:
  #     - array
  #     - hash
  #     - heredoc
  #   ExcludeLimit: true
  #   AllowedMethods:
  #     - initialize
  # ```
  class MethodLength < Base
    properties do
      description "Disallows methods longer than `MaxLines` lines"

      max_lines 15

      # Method names exempt from the rule, e.g. a long `initialize`.
      allowed_methods %w[]

      # Excludes the `def` line itself from the count.
      exclude_limit false

      # Multi-line literals folded into a single counted line.
      # Accepted values: `array`, `hash`, `heredoc`.
      count_as_one %w[]

      # Comment-only lines are not counted towards the limit.
      ignore_comments false
    end

    COUNT_AS_ONE_VALUES = %w[array hash heredoc]

    MSG = "Method is too long [%d/%d lines]"

    # Builds the rule and rejects a `CountAsOne` value it cannot honour, so a
    # typo in `.ameba.yml` fails loudly instead of silently counting wrong.
    def self.new(config = nil)
      previous_def.tap(&.validate_config)
    end

    def test(source, node : Crystal::Def)
      return if allowed_methods.includes?(node.name)

      loc = node.location
      end_loc = node.end_location
      return unless loc && end_loc

      lines = lines_in(source, node, loc.line_number, end_loc.line_number)
      lines -= 1 if exclude_limit?

      return unless lines > max_lines

      issue_for(node, MSG % {lines, max_lines}, prefer_name_location: true)
    end

    # Raises `ArgumentError` when `CountAsOne` contains a value the rule
    # cannot honour.
    def validate_config
      unknown = count_as_one - COUNT_AS_ONE_VALUES
      return if unknown.empty?

      raise ArgumentError.new(
        "Metrics/MethodLength: unknown CountAsOne #{unknown.join(", ").inspect}, " \
        "expected any of #{COUNT_AS_ONE_VALUES.join(", ").inspect}"
      )
    end

    private def lines_in(source, node : Crystal::Def, first_line, last_line) : Int32
      lines = last_line - first_line + 1
      lines -= folded_lines(node)
      lines -= comment_lines(source, first_line, last_line)
      # Nested literals fold twice; a method can never be shorter than one line.
      lines.clamp(1, Int32::MAX)
    end

    # Each folded literal counts as one line instead of its physical span.
    private def folded_lines(node : Crystal::Def) : Int32
      return 0 if count_as_one.empty?

      folder = LiteralFolder.new(count_as_one)
      node.accept(folder)
      folder.saved
    end

    private def comment_lines(source, first_line, last_line) : Int32
      return 0 unless ignore_comments?

      source.lines[first_line..last_line].count(&.lstrip.starts_with?('#'))
    end

    # Sums the lines saved by folding multi-line literals.
    private class LiteralFolder < Crystal::Visitor
      getter saved = 0

      def initialize(@kinds : Array(String))
      end

      def visit(node : Crystal::ArrayLiteral)
        fold(node) if @kinds.includes?("array")
        true
      end

      def visit(node : Crystal::HashLiteral)
        fold(node) if @kinds.includes?("hash")
        true
      end

      # `{a: 1}` is a `NamedTupleLiteral`, not a `HashLiteral`, but it looks like
      # a hash to anyone writing the config, so `hash` covers both.
      def visit(node : Crystal::NamedTupleLiteral)
        fold(node) if @kinds.includes?("hash")
        true
      end

      def visit(node : Crystal::StringLiteral)
        fold(node) if @kinds.includes?("heredoc")
        true
      end

      # A heredoc with `#{}` is a `StringLiteral` wrapped in a
      # `StringInterpolation`, and both carry the same span. Return false so the
      # wrapper's children are not folded a second time.
      def visit(node : Crystal::StringInterpolation)
        fold(node) if @kinds.includes?("heredoc")
        !(@kinds.includes?("heredoc") && heredoc?(node))
      end

      # Only skip children when the wrapper really spans multiple lines, so
      # a single-line `"a#{b}"` keeps being visited normally.
      private def heredoc?(node : Crystal::StringInterpolation) : Bool
        loc = node.location
        end_loc = node.end_location
        !!(loc && end_loc && end_loc.line_number > loc.line_number)
      end

      def visit(node : Crystal::ASTNode)
        true
      end

      private def fold(node)
        loc = node.location
        end_loc = node.end_location
        return unless loc && end_loc

        @saved += end_loc.line_number - loc.line_number
      end
    end
  end
end
