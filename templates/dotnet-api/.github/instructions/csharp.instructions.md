---
applyTo: "**/*.cs"
---
# C# Code Rules

## Style
- Use file-scoped namespaces
- Primary constructors where appropriate (.NET 8+)
- Collection expressions: `[1, 2, 3]` over `new List<int> { 1, 2, 3 }`
- Pattern matching over type casting
- `string.IsNullOrWhiteSpace()` over `== null || == ""`

## Async
- All I/O methods must be async (suffix with `Async`)
- Never use `.Result` or `.Wait()` — deadlock risk
- Use `CancellationToken` in all async methods that do I/O
- `ConfigureAwait(false)` in library code, not in ASP.NET controllers

## Error Handling
- Use specific exception types, not `Exception`
- Return `Result<T>` or `ActionResult<T>` — avoid exceptions for flow control
- Global exception handler for unhandled errors
- Log exceptions with structured logging (Serilog/NLog)

## DI
- Register services in `Program.cs` or extension methods
- Prefer `AddScoped` for request-scoped, `AddSingleton` for stateless
- Use interfaces for testability

## Testing
- Test class mirrors source class: `OrderService` → `OrderServiceTests`
- Use Moq or NSubstitute for mocking
- Arrange / Act / Assert pattern
- Test names: `MethodName_Condition_ExpectedResult`
