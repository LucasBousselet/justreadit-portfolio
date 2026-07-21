using System.Text.Json.Serialization;

namespace JustReadIt.Api.Models
{
    public class AuthorResponseModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = "N/A";
        public string? Bio { get; set; }
    }
}
