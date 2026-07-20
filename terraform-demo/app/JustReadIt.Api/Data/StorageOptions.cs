namespace JustReadIt.Api.Data
{
    public class StorageOptions
    {
        public const string SectionName = "Storage";

        // Name of the private S3 bucket that stores user-owned content.
        public string? UserContentBucketName { get; set; }

        // Demo object uploaded by Terraform. ECS sets Storage__DemoEbookKey,
        // which ASP.NET maps to Storage:DemoEbookKey during configuration binding.
        // Real app data would store a different S3 object key per book.
        public string DemoEbookKey { get; set; } = "ebooks/demo-book.txt";

        // Keep presigned URLs short-lived; callers can request a fresh URL when needed.
        public int PresignedUrlExpirationMinutes { get; set; } = 5;
    }
}
