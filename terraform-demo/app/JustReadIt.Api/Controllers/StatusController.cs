using Microsoft.AspNetCore.Mvc;

namespace JustReadIt.Api.Controllers
{
    [ApiController]
    public class StatusController : ControllerBase
    {
        private readonly IWebHostEnvironment _environment;

        public StatusController(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        [HttpGet("status")]
        public IActionResult GetStatus()
        {
            return Ok(new { status = "healthy" });
        }

        [HttpGet("version")]
        public async Task<IActionResult> GetVersion()
        {
            var versionFilePath = Path.Combine(_environment.ContentRootPath, "version.txt");

            if (!System.IO.File.Exists(versionFilePath))
            {
                return Problem("version.txt was not found.", statusCode: StatusCodes.Status500InternalServerError);
            }

            var version = await System.IO.File.ReadAllTextAsync(versionFilePath);

            return Content(version, "text/plain");
        }
    }
}
