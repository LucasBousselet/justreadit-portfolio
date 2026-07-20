using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using JustReadIt.Api.Data;
using JustReadIt.Api.Models;
using Microsoft.Extensions.Options;

namespace JustReadIt.Api.Controllers
{
    [Route("demo")]
    [ApiController]
    public class BooksController : ControllerBase
    {
        private readonly JustReadItDbContext _dbContext;
        private readonly IAmazonS3 _s3Client;
        private readonly StorageOptions _storageOptions;

        public BooksController(
            JustReadItDbContext dbContext,
            IAmazonS3 s3Client,
            IOptions<StorageOptions> storageOptions)
        {
            _dbContext = dbContext;
            _s3Client = s3Client;
            _storageOptions = storageOptions.Value;
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

        [HttpGet("books/{bookId:int}/download-url")]
        public async Task<ActionResult<DownloadUrlModel>> GetDemoBookDownloadUrlAsync(int bookId)
        {
            var book = await _dbContext.Books
                .AsNoTracking()
                .Where(book => book.Id == bookId)
                .Select(book => new { book.Id, book.Title })
                .FirstOrDefaultAsync();

            if (book is null)
            {
                return NotFound();
            }

            if (string.IsNullOrWhiteSpace(_storageOptions.UserContentBucketName))
            {
                return Problem("Storage:UserContentBucketName must be configured before download URLs can be generated.");
            }

            if (string.IsNullOrWhiteSpace(_storageOptions.DemoEbookKey))
            {
                return Problem("Storage:DemoEbookKey must be configured before download URLs can be generated.");
            }

            var expiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(
                Math.Max(1, _storageOptions.PresignedUrlExpirationMinutes));

            var request = new GetPreSignedUrlRequest
            {
                BucketName = _storageOptions.UserContentBucketName,
                Key = _storageOptions.DemoEbookKey,
                Verb = HttpVerb.GET,
                Expires = expiresAtUtc.UtcDateTime,
                Protocol = Protocol.HTTPS,
                ResponseHeaderOverrides = new ResponseHeaderOverrides
                {
                    ContentDisposition = $"attachment; filename=\"{BuildDownloadFileName(book.Title)}\"",
                    ContentType = "text/plain"
                }
            };

            var downloadUrl = await _s3Client.GetPreSignedURLAsync(request);

            return new DownloadUrlModel
            {
                DownloadUrl = downloadUrl,
                ExpiresAtUtc = expiresAtUtc
            };
        }

        private static string BuildDownloadFileName(string title)
        {
            var normalizedTitle = new string(title
                    .ToLowerInvariant()
                    .Select(character => char.IsLetterOrDigit(character) ? character : '-')
                    .ToArray())
                .Split('-', StringSplitOptions.RemoveEmptyEntries);

            var fileName = string.Join('-', normalizedTitle);

            return string.IsNullOrWhiteSpace(fileName)
                ? "ebook.txt"
                : $"{fileName}.txt";
        }
    }
}
