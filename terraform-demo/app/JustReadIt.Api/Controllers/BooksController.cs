using Microsoft.AspNetCore.Mvc;
using JustReadIt.Api.Models;

namespace JustReadIt.Api.Controllers
{
    [Route("demo")]
    [ApiController]
    public class BooksController : ControllerBase
    {
        [HttpGet("book")]
        public async Task<BookModel> GetDemoBookAsync()
        {
            var demoBook = new BookModel
            {
                Id = 1,
                Title = "The Terraform Reader",
                Author = "JustReadIt Demo Library",
                Description = "A small demo book record. In the real app this would come from your ECS API backed by RDS/Postgres.",
                CoverUrl = "/demo-cover.svg",
                PublishedYear = 2026,
                Pages = 128
            };
            return demoBook;
        }
    }
}
