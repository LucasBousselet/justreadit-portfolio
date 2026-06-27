using Microsoft.AspNetCore.Mvc;
using JustReadIt.Api.Models;

namespace JustReadIt.Api.Controllers
{
    [Route("weather")]
    [ApiController]
    public class WeatherController : ControllerBase
    {
        [HttpGet("forecast")]
        public async Task<WeatherForecastModel[]> GetWeatherForecast()
        {
            var summaries = new[]
            {
                "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
            };

            var forecast =  Enumerable.Range(1, 5).Select(index =>
                new WeatherForecastModel
                (
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    Random.Shared.Next(-20, 55),
                    summaries[Random.Shared.Next(summaries.Length)]
                ))
                .ToArray();
            return forecast;
        }
    }
}
