namespace JustReadIt.Api.Models
{
    public class DownloadUrlModel
    {
        public string DownloadUrl { get; set; } = string.Empty;
        public DateTimeOffset ExpiresAtUtc { get; set; }
    }
}
