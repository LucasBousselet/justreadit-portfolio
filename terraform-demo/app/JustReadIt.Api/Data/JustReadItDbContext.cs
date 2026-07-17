using JustReadIt.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace JustReadIt.Api.Data
{
    public class JustReadItDbContext : DbContext
    {
        public JustReadItDbContext(DbContextOptions<JustReadItDbContext> options)
            : base(options)
        {
        }

        public DbSet<AuthorModel> Authors => Set<AuthorModel>();
        public DbSet<BookModel> Books => Set<BookModel>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AuthorModel>(entity =>
            {
                entity.ToTable("authors");

                entity.HasKey(author => author.Id);

                entity.Property(author => author.Name)
                    .HasMaxLength(200)
                    .IsRequired();

                entity.Property(author => author.Bio)
                    .HasMaxLength(1000);

                entity.HasData(
                    new AuthorModel
                    {
                        Id = 1,
                        Name = "JustReadIt Demo Library",
                        Bio = "A fictional in-house author used for infrastructure demos."
                    },
                    new AuthorModel
                    {
                        Id = 2,
                        Name = "Ada Lovelace Press",
                        Bio = "A tiny fake publisher for database seed data."
                    });
            });

            modelBuilder.Entity<BookModel>(entity =>
            {
                entity.ToTable("books");

                entity.HasKey(book => book.Id);

                entity.Property(book => book.Title)
                    .HasMaxLength(240)
                    .IsRequired();

                entity.Property(book => book.Description)
                    .HasMaxLength(1000);

                entity.Property(book => book.CoverUrl)
                    .HasMaxLength(500);

                entity.HasOne(book => book.Author)
                    .WithMany(author => author.Books)
                    .HasForeignKey(book => book.AuthorId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasData(
                    new BookModel
                    {
                        Id = 1,
                        Title = "The Terraform Reader",
                        AuthorId = 1,
                        Description = "A small demo book record loaded from PostgreSQL through Entity Framework Core.",
                        CoverUrl = "/demo-cover.svg",
                        PublishedYear = 2026,
                        Pages = 128
                    },
                    new BookModel
                    {
                        Id = 2,
                        Title = "Practical Cloud Notes",
                        AuthorId = 1,
                        Description = "Fake seed data that proves one author can have several books.",
                        CoverUrl = "/demo-cover.svg",
                        PublishedYear = 2025,
                        Pages = 214
                    },
                    new BookModel
                    {
                        Id = 3,
                        Title = "Postgres for Page Turners",
                        AuthorId = 2,
                        Description = "A fictional book used to verify the Author-to-Books relationship.",
                        CoverUrl = "/demo-cover.svg",
                        PublishedYear = 2024,
                        Pages = 176
                    });
            });
        }
    }
}
