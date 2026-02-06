require "db"

require "./connection"

DB.register_driver "libsql", LibSQL::Driver

module LibSQL
  class Driver < ::DB::Driver
    def connection_builder(uri : URI) : ::DB::ConnectionBuilder
      params = HTTP::Params.parse(uri.query || "")

      ConnectionBuilder.new(connection_options(params), uri)
    end

    class ConnectionBuilder < ::DB::ConnectionBuilder
      getter options : ::DB::Connection::Options
      getter uri : URI

      def initialize(@options, @uri)
      end

      def build : ::DB::Connection
        Connection.new(options, uri)
      end
    end
  end
end
