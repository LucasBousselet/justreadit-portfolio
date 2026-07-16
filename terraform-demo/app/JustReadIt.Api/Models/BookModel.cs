namespace JustReadIt.Api.Models
{
    public class BookModel
    {
        public int Id { get; set; }
        public string Title { get; set; } = "N/A";
        public string Author { get; set; } = "N/A";
        public string? Description { get; set; }
        public string? CoverUrl { get; set; }
        public int PublishedYear { get; set; }
        public int Pages { get; set; }
    }
}
