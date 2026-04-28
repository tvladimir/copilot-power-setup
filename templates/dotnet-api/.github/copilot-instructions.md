# .NET API Project

## Stack
- .NET 9 / ASP.NET Core (Controllers + Minimal API)
- Entity Framework Core + MS SQL Server
- xUnit for tests
- Deployed to OpenShift via Helm

## Commands (use these exact ones)
- Build: `dotnet build`
- Test: `dotnet test`
- New migration: `dotnet ef migrations add <PascalCaseName>`
- Apply migrations: `dotnet ef database update`
- Run: `dotnet run`

## Code Standards
- C# latest features (primary constructors, collection expressions, pattern matching)
- Nullable reference types ON
- Async/await for all I/O — name with `Async` suffix
- Built-in DI (`AddScoped` / `AddSingleton`); `IOptions<T>` for config
- One controller, one resource — split when a controller exceeds ~200 lines

## EF Core
- Always async (`ToListAsync`, `FirstOrDefaultAsync`) — sync calls block the thread pool
- Explicit `.Include()` only — lazy loading is OFF
- Index FKs and frequently queried columns in `OnModelCreating`
- Review the generated migration SQL before applying
- Never modify a migration that has been deployed — create a new one

## API Conventions
- Plural nouns + HTTP verbs (`GET /api/orders`, not `/api/getOrders`)
- ProblemDetails (RFC 7807) for error responses
- FluentValidation at the controller boundary
- Swagger / OpenAPI on every endpoint
- Versioning via URL path (`/api/v1/...`)

## Security
- `[Authorize]` attribute — never parse tokens manually
- Never log passwords / tokens / PII (Why: PII in logs is a GDPR finding)
- Parameterized queries only — EF does this; raw SQL must use parameters

## Don'ts
- No `.Result` / `.Wait()` on async — deadlock risk in ASP.NET request context
- No `catch (Exception)` swallow — catch the specific type or re-throw
- No raw exceptions for flow control — return `Result<T>` or `ActionResult<T>`
- No `NVARCHAR(MAX)` unless the column is genuinely unbounded
- No mocking of `DbContext` in tests — use the in-memory provider or testcontainers (Why: mocked tests miss EF translation bugs)
- No `string` for money / quantities — use `decimal`
