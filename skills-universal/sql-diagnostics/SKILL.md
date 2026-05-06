---
name: sql-diagnostics
description: Diagnose slow MS SQL Server queries using DMVs — find top time-consumers, missing indexes, table bloat. Use when a query is slow, a stored proc regressed, or you need a baseline read of what SQL Server is spending time on. Targets MS SQL Server (T-SQL syntax). Read-only.
---

# SQL Server diagnostics

Snapshot of MS SQL Server runtime state via dynamic management views (DMVs). All queries are **read-only** and safe to run on production. They expose query plan cache, index recommendations, and table sizing.

## When to use this skill

- "This stored proc became slow last week."
- "We added an index and queries got worse — what happened?"
- "I need a one-page report of the slowest queries on this server."
- A user asks DBDoctor for a diagnosis and there's no specific query yet.

## How to use

Run the SQL below against the target database. Each block is self-contained. Combine the output into a diagnosis: top expensive queries → check whether they have missing-index hints → check table sizes for context.

### 1. Top expensive queries (cache-resident)

```sql
SELECT TOP 20
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_us,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_reads,
    SUBSTRING(qt.text, qs.statement_start_offset/2 + 1,
        (CASE WHEN qs.statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
            ELSE qs.statement_end_offset END - qs.statement_start_offset)/2 + 1) AS query_text,
    DB_NAME(qt.dbid) AS db_name
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_elapsed_us DESC;
```

### 2. Missing-index recommendations (with impact)

```sql
SELECT TOP 20
    mid.statement AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_user_impact,
    migs.user_seeks,
    migs.avg_user_impact * migs.user_seeks AS impact_score
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups       mig  ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats  migs ON mig.index_group_handle = migs.group_handle
WHERE migs.avg_user_impact > 50
ORDER BY impact_score DESC;
```

### 3. Table sizes (data + index pages)

```sql
SELECT
    t.name AS table_name,
    p.rows,
    SUM(a.total_pages) * 8 / 1024 AS total_mb,
    SUM(CASE WHEN i.index_id IN (0,1) THEN a.total_pages ELSE 0 END) * 8 / 1024 AS data_mb,
    SUM(CASE WHEN i.index_id NOT IN (0,1) THEN a.total_pages ELSE 0 END) * 8 / 1024 AS index_mb
FROM sys.tables t
JOIN sys.indexes          i ON t.object_id = i.object_id
JOIN sys.partitions       p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name, p.rows
ORDER BY total_mb DESC;
```

### 4. Index usage (find unused indexes)

```sql
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id)        AS table_name,
    i.name                          AS index_name,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE i.type_desc <> 'HEAP'
  AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY ius.user_updates DESC, ius.user_seeks ASC;
```

## Interpretation rules

- A query with `avg_elapsed_us > 1_000_000` (1s) on the top-20 list is a candidate for tuning.
- A missing-index recommendation with `impact_score > 100_000` is worth creating immediately.
- An index with high `user_updates` and zero `user_seeks` is dead weight — drop after a 30-day observation window.
- `WITH (NOLOCK)` is acceptable on **read-only analytical** queries; never on transactional paths.
- Prefer **covering** indexes over many single-column indexes (read amplification).
