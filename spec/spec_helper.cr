require "spec"

require "../src/ameba-method_length"
require "ameba/spec/support"

# Loads an `.ameba.yml` snippet through the same path a real project uses, so
# rule construction and validation are exercised end to end.
def config_yaml(yaml : String, dir : String = "config") : Array(Ameba::Rule::Base)
  root = Path[Dir.tempdir, "ameba_method_length_#{dir}"]
  FileUtils.mkdir_p(root)
  File.write(root / ".ameba.yml", yaml)

  Ameba::Config.load(root: root).rules
end
