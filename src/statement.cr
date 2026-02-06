require "./result_set"

module LibSQL
  class Statement < ::DB::Statement
    def initialize(connection : Connection, command : String)
      super(connection, command)
    end

    protected def perform_query(args : Enumerable) : ::DB::ResultSet
      result = conn.execute_sql(command, args)
      ResultSet.new(self, result)
    end

    protected def perform_exec(args : Enumerable) : ::DB::ExecResult
      result = conn.execute_sql(command, args)
      ::DB::ExecResult.new(result.affected_row_count, result.last_insert_rowid || 0_i64)
    end

    private def conn : Connection
      connection.as(Connection)
    end
  end
end
