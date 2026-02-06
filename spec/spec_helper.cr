require "spec"
require "dotenv"
require "../src/libsql"

Dotenv.load?

def be_within(delta, of value)
  be_close value, delta
end
