using System.Text.Json.Serialization;

namespace JustReadIt.Api.Data
{
    public class RdsSecret
    {
        [JsonPropertyName("username")]
        public string? Username { get; set; }

        [JsonPropertyName("password")]
        public string? Password { get; set; }

        [JsonPropertyName("host")]
        public string? Host { get; set; }

        [JsonPropertyName("port")]
        public int? Port { get; set; }

        [JsonPropertyName("dbname")]
        public string? DatabaseName { get; set; }
    }
}
