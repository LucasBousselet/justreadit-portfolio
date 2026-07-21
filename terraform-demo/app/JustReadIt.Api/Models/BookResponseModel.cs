namespace JustReadIt.Api.Models
{
    public class BookResponseModel
    {
        public int Id { get; set; }
        public string Title { get; set; } = "N/A";
        public AuthorResponseModel Author { get; set; } = null!;
        public string? Description { get; set; }
        public string? CoverUrl { get; set; }
        public int PublishedYear { get; set; }
        public int Pages { get; set; }
    }
}
