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

  it "can use Bool values as DB::Serializable properties" do
    result = db.query_one(<<-SQL, as: LibSQLSpec::BoolRow)
      SELECT
        1 AS active,
        0 AS deleted
    SQL

    result.active.should be_true
    result.deleted.should be_false
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

  it "can handle nilable/union types with DB::Serializable" do
    id = UUID.v7
    # Truncate time subseconds to match SQLite's precision in RFC3339 if needed,
    # but let's just use a clean Time.utc
    now = Time.utc
    time = Time.utc(now.year, now.month, now.day, now.hour, now.minute, now.second)

    # Test with non-nil values
    result = db.query_one(<<-SQL, time, id, as: LibSQLSpec::NilableRow)
      SELECT
        1 AS active,
        'test@example.com' AS email,
        42 AS login_count,
        ? AS created_at,
        ? AS id
    SQL

    result.active.should be_true
    result.email.should eq "test@example.com"
    result.login_count.should eq 42
    result.created_at.should eq time
    result.id.should eq id

    # Test with nil values
    result_nil = db.query_one(<<-SQL, as: LibSQLSpec::NilableRow)
      SELECT
        NULL AS active,
        NULL AS email,
        NULL AS login_count,
        NULL AS created_at,
        NULL AS id
    SQL

    result_nil.active.should be_nil
    result_nil.email.should be_nil
    result_nil.login_count.should be_nil
    result_nil.created_at.should be_nil
    result_nil.id.should be_nil
  end

  it "can deserialize various integer and float sizes with DB::Serializable" do
    result = db.query_one(<<-SQL, as: LibSQLSpec::AllTypesRow)
      SELECT
        127 AS i8,
        32767 AS i16,
        2147483647 AS i32,
        9223372036854775807 AS i64,
        255 AS u8,
        65535 AS u16,
        4294967295 AS u32,
        9223372036854775807 AS u64,
        3.14 AS f32,
        3.141592653589793 AS f64
    SQL

    result.i8.should eq 127_i8
    result.i16.should eq 32767_i16
    result.i32.should eq 2147483647_i32
    result.i64.should eq 9223372036854775807_i64
    result.u8.should eq 255_u8
    result.u16.should eq 65535_u16
    result.u32.should eq 4294967295_u32
    result.u64.should eq 9223372036854775807_u64
    result.f32.should be_close(3.14_f32, 0.001)
    result.f64.should eq 3.141592653589793_f64
  end
end

struct LibSQLSpec::AllTypesRow
  include DB::Serializable

  getter i8 : Int8
  getter i16 : Int16
  getter i32 : Int32
  getter i64 : Int64
  getter u8 : UInt8
  getter u16 : UInt16
  getter u32 : UInt32
  getter u64 : UInt64
  getter f32 : Float32
  getter f64 : Float64
end

struct LibSQLSpec::NilableRow
  include DB::Serializable

  getter active : Bool?
  getter email : String?
  getter login_count : Int32?
  getter created_at : Time?
  getter id : UUID?
end

struct LibSQLSpec::BoolRow
  include DB::Serializable

  getter active : Bool
  getter deleted : Bool
end

struct LibSQLSpec::User
  include DB::Serializable

  getter id : UUID
  getter email : String
  getter login_count : Int64
  getter created_at : Time
end
