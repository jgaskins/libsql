# libsql

A Crystal database driver for LibSQL / Turso databases, implementing the standard [crystal-db](https://github.com/crystal-lang/crystal-db) abstraction layer.

It communicates with the LibSQL server using the `/v3/pipeline` HTTP protocol, providing a type-safe interface for edge-native, distributed SQLite databases.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     libsql:
       github: jgaskins/libsql
   ```

2. Run `shards install`

## Usage

```crystal
require "db"
require "libsql"

# Connect to a remote Turso database using Bearer token authentication (token is passed as password)
DB.open("libsql://your-db-host.turso.io?password=your-auth-token") do |db|
  # Simple queries
  val = db.query_one("SELECT 42", as: Int32)
  puts val # => 42

  # Transactions
  db.transaction do |tx|
    tx.connection.exec("INSERT INTO users (name) VALUES (?)", "Alice")
  end
end
```

## Development

To run the specs locally, you can spin up a local `libsql-server` instance using Podman/Docker:

```bash
podman run --name libsql-test -p 28080:8080 -d ghcr.io/tursodatabase/libsql-server:latest
```

Then, run the tests against it by configuring `DATABASE_URL` and disabling TLS:

```bash
DATABASE_URL="libsql://127.0.0.1:28080?tls=false" crystal spec
```

## Contributing

1. Fork it (<https://github.com/jgaskins/libsql/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
