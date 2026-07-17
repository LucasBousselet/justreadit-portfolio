using Scalar.AspNetCore;
using JustReadIt.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace JustReadIt.Api
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            var postgresConnectionString = await PostgresConnectionStringFactory.CreateAsync(
                builder.Configuration);

            // Add services to the container.
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            // Add services to the container.
            builder.Services.AddControllers();
            builder.Services.AddDbContext<JustReadItDbContext>(options =>
                options.UseNpgsql(postgresConnectionString));

            var app = builder.Build();

            await ApplyMigrationsAsync(app);

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
                // Available at: base url + /scalar/v1
                app.MapScalarApiReference();
            }

            app.UsePathBase(new PathString("/api"));
            app.UseHttpsRedirection();

            app.MapControllers();
            
            app.Run();
        }

        private static async Task ApplyMigrationsAsync(WebApplication app)
        {
            var databaseOptions = app.Configuration
                .GetSection(DatabaseOptions.SectionName)
                .Get<DatabaseOptions>() ?? new DatabaseOptions();

            if (!databaseOptions.ApplyMigrationsOnStartup)
            {
                return;
            }

            await using var scope = app.Services.CreateAsyncScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<JustReadItDbContext>();
            await dbContext.Database.MigrateAsync();
        }
    }
}
