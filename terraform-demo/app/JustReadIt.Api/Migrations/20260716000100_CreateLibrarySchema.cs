#nullable disable

using JustReadIt.Api.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace JustReadIt.Api.Migrations
{
    [DbContext(typeof(JustReadItDbContext))]
    [Migration("20260716000100_CreateLibrarySchema")]
    public partial class CreateLibrarySchema : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "authors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Bio = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_authors", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "books",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Title = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: false),
                    AuthorId = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    CoverUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    PublishedYear = table.Column<int>(type: "integer", nullable: false),
                    Pages = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_books", x => x.Id);
                    table.ForeignKey(
                        name: "FK_books_authors_AuthorId",
                        column: x => x.AuthorId,
                        principalTable: "authors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.Sql("""
                INSERT INTO authors ("Id", "Bio", "Name")
                VALUES
                    (1, 'A fictional in-house author used for infrastructure demos.', 'JustReadIt Demo Library'),
                    (2, 'A tiny fake publisher for database seed data.', 'Ada Lovelace Press');
                """);

            migrationBuilder.Sql("""
                INSERT INTO books ("Id", "AuthorId", "CoverUrl", "Description", "Pages", "PublishedYear", "Title")
                VALUES
                    (1, 1, '/demo-cover.svg', 'A small demo book record loaded from PostgreSQL through Entity Framework Core.', 128, 2026, 'The Terraform Reader'),
                    (2, 1, '/demo-cover.svg', 'Fake seed data that proves one author can have several books.', 214, 2025, 'Practical Cloud Notes'),
                    (3, 2, '/demo-cover.svg', 'A fictional book used to verify the Author-to-Books relationship.', 176, 2024, 'Postgres for Page Turners');
                """);

            migrationBuilder.CreateIndex(
                name: "IX_books_AuthorId",
                table: "books",
                column: "AuthorId");

            migrationBuilder.Sql("SELECT setval(pg_get_serial_sequence('authors', 'Id'), (SELECT MAX(\"Id\") FROM authors));");
            migrationBuilder.Sql("SELECT setval(pg_get_serial_sequence('books', 'Id'), (SELECT MAX(\"Id\") FROM books));");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "books");

            migrationBuilder.DropTable(
                name: "authors");
        }
    }
}
