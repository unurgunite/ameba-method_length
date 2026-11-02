require "../spec_helper"

module Ameba::Rule::Metrics
  describe MethodLength do
    subject = MethodLength.new

    # 15 lines: `def` + 13 body lines + `end`.
    method_with_15_lines = <<-CRYSTAL
      def hello
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
        a = 1
      end
      CRYSTAL

    it "passes for a short method" do
      expect_no_issues subject, <<-CRYSTAL
        def hello
          a = 1
          a
        end
        CRYSTAL
    end

    it "passes for a method exactly at the limit" do
      expect_no_issues subject, method_with_15_lines
    end

    it "reports an issue for a method over the limit" do
      source = Source.new(method_with_15_lines.sub("a = 1", "a = 1\n  a = 1"), "source.cr")
      subject.catch(source).should_not be_valid

      issue = source.issues.first
      issue.rule.should eq subject
      issue.location.to_s.should eq "source.cr:1:5"
      issue.end_location.to_s.should eq "source.cr:1:9"
      issue.message.should eq "Method is too long [16/15 lines]"
    end

    it "respects a custom max_lines" do
      rule = MethodLength.new
      rule.max_lines = 2

      expect_issue rule, <<-CRYSTAL
        def hello
          # ^^^^^ error: Method is too long [3/2 lines]
          a = 1
        end
        CRYSTAL
    end

    it "doesn't report an issue for an increased threshold" do
      rule = MethodLength.new
      rule.max_lines = 100

      expect_no_issues rule, method_with_15_lines
    end

    it "passes for an abstract def without an end location" do
      expect_no_issues subject, <<-CRYSTAL
        abstract class Foo
          abstract def hello
        end
        CRYSTAL
    end

    it "counts a multi-line body as source lines" do
      rule = MethodLength.new
      rule.max_lines = 2

      expect_issue rule, <<-CRYSTAL
        def hello
          # ^^^^^ error: Method is too long [4/2 lines]
          [1,
           2]
        end
        CRYSTAL
    end
  end
end
