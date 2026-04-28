---
applyTo: "**/Migrations/**/*.cs,**/*.sql"
---
# SQL / EF Migration Rules

## EF Migrations
- Always review generated migration SQL before applying
- Include `Down()` method for rollback capability
- Never modify published (deployed) migrations — create new one
- Use `migrationBuilder.Sql()` for raw SQL in migrations

## SQL Server Specific
- Use `NVARCHAR` for Unicode text, `VARCHAR` for ASCII-only
- Always specify column sizes (no `NVARCHAR(MAX)` unless truly needed)
- Include `NOT NULL` constraints where applicable
- Add indexes on foreign keys and frequently queried columns
- Use `CLUSTERED` index on primary key (default), `NONCLUSTERED` for secondary

## Performance
- Add indexes in migrations when adding new query patterns
- Use `INCLUDE` columns for covering indexes
- Consider filtered indexes for nullable columns
- Add `WITH (ONLINE = ON)` for large table index changes in production
