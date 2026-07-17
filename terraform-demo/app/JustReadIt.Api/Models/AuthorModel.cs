using System.Text.Json.Serialization;

namespace JustReadIt.Api.Models
{
    public class AuthorModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = "N/A";
        public string? Bio { get; set; }

        [JsonIgnore]
        public ICollection<BookModel> Books { get; set; } = new List<BookModel>();
    }
}
