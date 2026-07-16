using Scalar.AspNetCore;

namespace JustReadIt.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            // Add services to the container.
            builder.Services.AddControllers();

            var app = builder.Build();

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
    }
}
