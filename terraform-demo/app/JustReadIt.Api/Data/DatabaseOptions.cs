namespace JustReadIt.Api.Data
{
    public class DatabaseOptions
    {
        public const string SectionName = "Database";

        // Non-secret database coordinates. Terraform injects these into the ECS task.
        public string? Host { get; set; }
        public int Port { get; set; } = 5432;
        public string? Name { get; set; }

        // ARN of the RDS-managed Secrets Manager secret containing username/password.
        public string? SecretArn { get; set; }
        public string? Region { get; set; }

        // Convenient for this demo app so first deploy creates and seeds the schema.
        // Disable this in larger production systems where migrations are run separately.
        public bool ApplyMigrationsOnStartup { get; set; } = true;
    }
}
