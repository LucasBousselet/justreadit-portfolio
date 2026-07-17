using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using JustReadIt.Api.Data;
using JustReadIt.Api.Models;

namespace JustReadIt.Api.Controllers
{
    [Route("demo")]
    [ApiController]
    public class BooksController : ControllerBase
    {
        private readonly JustReadItDbContext _dbContext;

        public BooksController(JustReadItDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet("book")]
        public async Task<ActionResult<BookModel>> GetDemoBookAsync()
        {
            var demoBook = await _dbContext.Books
                .AsNoTracking()
                .Include(book => book.Author)
                .OrderBy(book => book.Id)
                .FirstOrDefaultAsync();

            if (demoBook is null)
            {
                return NotFound();
            }

            return demoBook;
        }
    }
}
