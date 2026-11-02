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

    describe "defaults" do
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

      it "doesn't report an issue for an increased threshold" do
        rule = MethodLength.new
        rule.max_lines = 100

        expect_no_issues rule, method_with_15_lines
      end
    end

    describe "line counting" do
      it "counts a multi-line body by physical source lines" do
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

      it "counts a heredoc by its physical source lines" do
        rule = MethodLength.new
        rule.max_lines = 3

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [6/3 lines]
            a = <<-TXT
            one
            TXT
            a
          end
          CRYSTAL
      end

      it "counts a one-line method as one line" do
        rule = MethodLength.new
        rule.max_lines = 1

        expect_no_issues rule, "def hello; a; end"
      end

      it "counts an operator method" do
        rule = MethodLength.new
        rule.max_lines = 2

        expect_issue rule, <<-CRYSTAL
          def [](index)
            # ^^ error: Method is too long [3/2 lines]
            @items[index]
          end
          CRYSTAL
      end

      it "counts a setter method" do
        rule = MethodLength.new
        rule.max_lines = 2

        expect_issue rule, <<-CRYSTAL
          def value=(value)
            # ^^^^^^ error: Method is too long [3/2 lines]
            @value = value
          end
          CRYSTAL
      end

      it "counts a method containing a block" do
        rule = MethodLength.new
        rule.max_lines = 4

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [5/4 lines]
            a.each do |x|
              x
            end
          end
          CRYSTAL
      end

      it "counts a method containing rescue and ensure" do
        rule = MethodLength.new
        rule.max_lines = 4

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [7/4 lines]
            a
          rescue
            b
          ensure
            c
          end
          CRYSTAL
      end

      it "passes for an abstract def without an end location" do
        expect_no_issues subject, <<-CRYSTAL
          abstract class Foo
            abstract def hello
          end
          CRYSTAL
      end
    end

    describe "ExcludeLimit" do
      it "excludes the def line from the count" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.exclude_limit = true

        expect_no_issues rule, <<-CRYSTAL
          def hello
            a = 1
            a
          end
          CRYSTAL
      end

      it "reports the body length without the def line" do
        rule = MethodLength.new
        rule.max_lines = 2
        rule.exclude_limit = true

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [3/2 lines]
            a = 1
            a
          end
          CRYSTAL
      end
    end

    describe "AllowedMethods" do
      it "skips an allowed method" do
        rule = MethodLength.new
        rule.max_lines = 2
        rule.allowed_methods = %w[initialize]

        expect_no_issues rule, <<-CRYSTAL
          def initialize
            a = 1
            b = 2
            a + b
          end
          CRYSTAL
      end

      it "still reports other methods" do
        rule = MethodLength.new
        rule.max_lines = 2
        rule.allowed_methods = %w[initialize]

        expect_issue rule, <<-CRYSTAL
          def configure
            # ^^^^^^^^^ error: Method is too long [5/2 lines]
            a = 1
            b = 2
            a + b
          end
          CRYSTAL
      end
    end

    describe "IgnoreComments" do
      it "does not count comment-only lines" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.ignore_comments = true

        expect_no_issues rule, <<-CRYSTAL
          def hello
            # one
            # two
            a = 1
          end
          CRYSTAL
      end

      it "counts comments by default" do
        rule = MethodLength.new
        rule.max_lines = 3

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [5/3 lines]
            # one
            # two
            a = 1
          end
          CRYSTAL
      end
    end

    describe "CountAsOne" do
      it "folds a multi-line array into a single line" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.count_as_one = %w[array]

        expect_no_issues rule, <<-CRYSTAL
          def hello
            a = [
              1,
              2,
            ]
          end
          CRYSTAL
      end

      it "folds a multi-line hash into a single line" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.count_as_one = %w[hash]

        expect_no_issues rule, <<-CRYSTAL
          def hello
            a = {
              1 => 2,
            }
          end
          CRYSTAL
      end

      it "folds a heredoc into a single line" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.count_as_one = %w[heredoc]

        expect_no_issues rule, <<-CRYSTAL
          def hello
            a = <<-TXT
            one
            two
            TXT
          end
          CRYSTAL
      end

      it "still counts arrays when only hash is folded" do
        rule = MethodLength.new
        rule.max_lines = 3
        rule.count_as_one = %w[hash]

        expect_issue rule, <<-CRYSTAL
          def hello
            # ^^^^^ error: Method is too long [6/3 lines]
            a = [
              1,
              2,
            ]
          end
          CRYSTAL
      end
    end

    describe ".new" do
      it "rejects an unknown CountAsOne value from config" do
        expect_raises(Exception, /unknown CountAsOne "bogus"/) do
          config_yaml(<<-YAML)
            Metrics/MethodLength:
              CountAsOne:
                - bogus
            YAML
        end
      end

      it "accepts every documented CountAsOne value" do
        rule = config_yaml(<<-YAML).select(MethodLength).first
          Metrics/MethodLength:
            CountAsOne:
              - array
              - hash
              - heredoc
          YAML

        rule.count_as_one.should eq %w[array hash heredoc]
      end
    end
  end
end
