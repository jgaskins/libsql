require "./spec_helper"
require "uuid"

describe LibSQL do
  db = DB.open(ENV["DATABASE_URL"])

  it "can round-trip to the database" do
    db.query_one("SELECT 42", as: Int32).should eq 42
  end

  it "can create a table, insert a record, query the record, and drop the table" do
    table_name = "table_#{Random::Secure.hex}"
    db.exec <<-SQL
      CREATE TABLE #{table_name} (
        id UUID PRIMARY KEY,
        email TEXT,
        login_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT current_timestamp
      )
    SQL

    begin
      db.exec "INSERT INTO #{table_name} (id, email) VALUES (?, 'me@example.com')", UUID.v7
      user = db.query_one("SELECT id, email, login_count, created_at FROM #{table_name} LIMIT 1", as: LibSQLSpec::User)
      user.email.should eq "me@example.com"
      user.created_at.should be_within 1.second, of: Time.utc
    ensure
      db.exec "DROP TABLE #{table_name}"
    end
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

  it "can commit a transaction" do
    table_name = "table_#{Random::Secure.hex}"
    db.exec "CREATE TABLE #{table_name} (id INTEGER PRIMARY KEY, value TEXT)"

    begin
      db.transaction do |tx|
        tx.connection.exec "INSERT INTO #{table_name} (id, value) VALUES (1, 'hello')"
        tx.connection.exec "INSERT INTO #{table_name} (id, value) VALUES (2, 'world')"
      end

      results = db.query_all("SELECT value FROM #{table_name} ORDER BY id", as: String)
      results.should eq ["hello", "world"]
    ensure
      db.exec "DROP TABLE #{table_name}"
    end
  end

  it "can roll back a transaction" do
    table_name = "table_#{Random::Secure.hex}"
    db.exec "CREATE TABLE #{table_name} (id INTEGER PRIMARY KEY, value TEXT)"

    begin
      db.transaction do |tx|
        tx.connection.exec "INSERT INTO #{table_name} (id, value) VALUES (1, 'should_not_persist')"
        tx.rollback
      end

      results = db.query_all("SELECT value FROM #{table_name}", as: String)
      results.should be_empty
    ensure
      db.exec "DROP TABLE #{table_name}"
    end
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
