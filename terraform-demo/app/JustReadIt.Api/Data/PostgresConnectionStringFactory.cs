using System.Text.Json;
using Amazon;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Npgsql;

namespace JustReadIt.Api.Data
{
    public static class PostgresConnectionStringFactory
    {
        public static async Task<string> CreateAsync(IConfiguration configuration)
        {
            // Local development escape hatch: if a full connection string is provided,
            // use it directly and skip AWS Secrets Manager entirely.
            var localConnectionString = configuration.GetConnectionString("Postgres");

            if (!string.IsNullOrWhiteSpace(localConnectionString))
            {
                return localConnectionString;
            }

            // In ECS these values are provided by Terraform. The secret ARN points to
            // the RDS-managed master user secret; host/name/port are non-secret metadata.
            var options = configuration.GetSection(DatabaseOptions.SectionName).Get<DatabaseOptions>()
                ?? new DatabaseOptions();

            if (string.IsNullOrWhiteSpace(options.SecretArn))
            {
                throw new InvalidOperationException("Database:SecretArn must be configured, or ConnectionStrings:Postgres must be supplied for local development.");
            }

            var secret = await GetSecretAsync(options, configuration);

            // RDS-managed secrets use JSON with username/password and may also include
            // host, port, and dbname. Terraform still passes host/name/port so the app is
            // resilient if those optional secret fields are absent.
            if (string.IsNullOrWhiteSpace(secret.Username) || string.IsNullOrWhiteSpace(secret.Password))
            {
                throw new InvalidOperationException($"The RDS secret '{options.SecretArn}' must contain username and password values.");
            }

            var host = FirstNonEmpty(secret.Host, options.Host)
                ?? throw new InvalidOperationException("Database host was not found in the RDS secret or Database:Host configuration.");
            var databaseName = FirstNonEmpty(secret.DatabaseName, options.Name)
                ?? throw new InvalidOperationException("Database name was not found in the RDS secret or Database:Name configuration.");

            var connectionString = new NpgsqlConnectionStringBuilder
            {
                Host = host,
                Port = secret.Port ?? options.Port,
                Database = databaseName,
                Username = secret.Username,
                Password = secret.Password,
                // Prefer TLS when the server offers it. This works for RDS without
                // requiring local developers to install the AWS RDS CA bundle.
                SslMode = SslMode.Prefer
            };

            return connectionString.ConnectionString;
        }

        private static async Task<RdsSecret> GetSecretAsync(DatabaseOptions options, IConfiguration configuration)
        {
            // ECS sets AWS_REGION. AWS_DEFAULT_REGION keeps the same code usable in
            // common local/CI shells. If neither exists, the AWS SDK falls back to its
            // normal region resolution chain.
            var regionName = FirstNonEmpty(
                options.Region,
                configuration["AWS_REGION"],
                configuration["AWS_DEFAULT_REGION"]);

            // Credentials are not passed to the app directly. The AWS SDK resolves them
            // from the ECS task role in AWS, or from the local AWS credential chain when
            // running outside ECS.
            using var client = string.IsNullOrWhiteSpace(regionName)
                ? new AmazonSecretsManagerClient()
                : new AmazonSecretsManagerClient(RegionEndpoint.GetBySystemName(regionName));

            var response = await client.GetSecretValueAsync(new GetSecretValueRequest
            {
                SecretId = options.SecretArn
            });

            if (string.IsNullOrWhiteSpace(response.SecretString))
            {
                throw new InvalidOperationException($"The RDS secret '{options.SecretArn}' did not contain a JSON secret string.");
            }

            return JsonSerializer.Deserialize<RdsSecret>(response.SecretString)
                ?? throw new InvalidOperationException($"The RDS secret '{options.SecretArn}' could not be parsed.");
        }

        private static string? FirstNonEmpty(params string?[] values)
        {
            return values.FirstOrDefault(value => !string.IsNullOrWhiteSpace(value));
        }
    }
}
