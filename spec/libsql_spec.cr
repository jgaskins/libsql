require "./spec_helper"
require "uuid"

describe LibSQL do
  db = DB.open(ENV["DATABASE_URL"])

  it "can round-trip to the database" do
    db.query_one("SELECT 42", as: Int32).should eq 42
  end

  it "can query DB::Serializable objects" do
    id = UUID.v7
    email = "jamie@example.com"
    created_at = Time.utc

    user = db.query_one(<<-SQL, id, email, created_at, as: LibSQLSpec::User)
      SELECT
        CAST(? AS TEXT) AS id,
        CAST(? AS TEXT) AS email,
        3 AS login_count,
        CAST(? AS TEXT) as created_at
    SQL

    user.id.should eq id
    user.email.should eq "jamie@example.com"
    user.login_count.should eq 3
    user.created_at.should eq created_at
  end

  it "can handle empty result sets" do
    id = UUID.v7
    email = "jamie@example.com"
    created_at = Time.utc

    results = db.query_all(<<-SQL, id, email, created_at, as: LibSQLSpec::User)
      SELECT id, email, login_count, created_at
      FROM (
        SELECT
          ? AS id,
          ? AS email,
          0 AS login_count,
          ? as created_at
      )
      WHERE 1=0
    SQL

    results.should be_empty
  end
end

struct LibSQLSpec::User
  include DB::Serializable

  getter id : UUID
  getter email : String
  getter login_count : Int64
  getter created_at : Time
end
