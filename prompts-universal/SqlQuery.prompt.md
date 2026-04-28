---
name: "SqlQuery"
description: "Write or optimize SQL query for MS SQL Server"
tools: ['codebase']
---

## Task
${input:task:Describe what the query should do}

## Tables / Schema
```sql
${input:schema:Paste relevant table definitions or describe the schema}
```

## Requirements
- Target: MS SQL Server (T-SQL syntax)
- Include execution plan hints if needed
- Suggest appropriate indexes
- Handle NULLs explicitly
- Use CTEs for readability over nested subqueries
- Add comments for complex logic
- If this will be used in EF Core, show both raw SQL and LINQ versions
