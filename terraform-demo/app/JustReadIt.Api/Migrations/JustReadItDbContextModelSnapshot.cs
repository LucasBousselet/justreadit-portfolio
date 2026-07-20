#nullable disable

using JustReadIt.Api.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace JustReadIt.Api.Migrations
{
    [DbContext(typeof(JustReadItDbContext))]
    partial class JustReadItDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
            modelBuilder
                .HasAnnotation("ProductVersion", "10.0.7")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            modelBuilder.Entity("JustReadIt.Api.Models.AuthorModel", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer")
                        .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

                    b.Property<string>("Bio")
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("character varying(200)");

                    b.HasKey("Id");

                    b.ToTable("authors");

                    b.HasData(
                        new
                        {
                            Id = 1,
                            Bio = "A fictional in-house author used for infrastructure demos.",
                            Name = "JustReadIt Demo Library"
                        },
                        new
                        {
                            Id = 2,
                            Bio = "A tiny fake publisher for database seed data.",
                            Name = "Ada Lovelace Press"
                        });
                });

            modelBuilder.Entity("JustReadIt.Api.Models.BookModel", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer")
                        .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

                    b.Property<int>("AuthorId")
                        .HasColumnType("integer");

                    b.Property<string>("CoverUrl")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<string>("Description")
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<int>("Pages")
                        .HasColumnType("integer");

                    b.Property<int>("PublishedYear")
                        .HasColumnType("integer");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(240)
                        .HasColumnType("character varying(240)");

                    b.HasKey("Id");

                    b.HasIndex("AuthorId");

                    b.ToTable("books");

                    b.HasData(
                        new
                        {
                            Id = 1,
                            AuthorId = 1,
                            CoverUrl = "/demo-cover.svg",
                            Description = "A small demo book record loaded from PostgreSQL through Entity Framework Core.",
                            Pages = 128,
                            PublishedYear = 2026,
                            Title = "The Terraform Reader"
                        },
                        new
                        {
                            Id = 2,
                            AuthorId = 1,
                            CoverUrl = "/demo-cover.svg",
                            Description = "Fake seed data that proves one author can have several books.",
                            Pages = 214,
                            PublishedYear = 2025,
                            Title = "Practical Cloud Notes"
                        },
                        new
                        {
                            Id = 3,
                            AuthorId = 2,
                            CoverUrl = "/demo-cover.svg",
                            Description = "A fictional book used to verify the Author-to-Books relationship.",
                            Pages = 176,
                            PublishedYear = 2024,
                            Title = "Postgres for Page Turners"
                        });
                });

            modelBuilder.Entity("JustReadIt.Api.Models.BookModel", b =>
                {
                    b.HasOne("JustReadIt.Api.Models.AuthorModel", "Author")
                        .WithMany("Books")
                        .HasForeignKey("AuthorId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Author");
                });

            modelBuilder.Entity("JustReadIt.Api.Models.AuthorModel", b =>
                {
                    b.Navigation("Books");
                });
        }
    }
}
