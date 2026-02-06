require "../src/libsql"
require "dotenv"
Dotenv.load?

db = DB.open(ENV["DATABASE_URL"])


