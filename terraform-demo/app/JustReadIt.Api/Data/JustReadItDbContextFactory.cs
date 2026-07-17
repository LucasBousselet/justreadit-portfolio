using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace JustReadIt.Api.Data
{
    // EF Core uses this factory only for design-time commands such as
    // `dotnet ef migrations add`, `dotnet ef migrations script`, and
    // `dotnet ef database update`. The running API does not use this class.
    public class JustReadItDbContextFactory : IDesignTimeDbContextFactory<JustReadItDbContext>
    {
        public JustReadItDbContext CreateDbContext(string[] args)
        {
            // Prefer an explicit migrations-only connection string when one is supplied.
            // `ConnectionStrings__Postgres` is the broader local/dev override that the
            // running API also understands. The final localhost value keeps EF commands
            // usable for local migration generation even when no environment is configured.
            var connectionString =
                Environment.GetEnvironmentVariable("JUSTREADIT_MIGRATIONS_CONNECTION_STRING")
                ?? Environment.GetEnvironmentVariable("ConnectionStrings__Postgres")
                ?? "Host=localhost;Port=5432;Database=justreadit_db;Username=postgres_admin;Password=postgres";

            var options = new DbContextOptionsBuilder<JustReadItDbContext>()
                .UseNpgsql(connectionString)
                .Options;

            return new JustReadItDbContext(options);
        }
    }
}
