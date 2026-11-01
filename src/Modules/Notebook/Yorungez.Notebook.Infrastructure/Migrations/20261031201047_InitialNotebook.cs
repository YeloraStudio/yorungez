using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yorungez.Notebook.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialNotebook : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "notebook");

            migrationBuilder.CreateTable(
                name: "Entries",
                schema: "notebook",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Id = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    Kind = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Revision = table.Column<long>(type: "bigint", nullable: false),
                    CreatedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    DeletedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Body = table.Column<string>(type: "character varying(8000)", maxLength: 8000, nullable: true),
                    TargetId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    TargetName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    InstantUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Latitude = table.Column<double>(type: "double precision", nullable: true),
                    Longitude = table.Column<double>(type: "double precision", nullable: true),
                    ElevationMeters = table.Column<double>(type: "double precision", nullable: true),
                    PlaceName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Entries", x => new { x.UserId, x.Id });
                });

            migrationBuilder.CreateIndex(
                name: "IX_Entries_UserId_UpdatedAtUtc",
                schema: "notebook",
                table: "Entries",
                columns: new[] { "UserId", "UpdatedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Entries",
                schema: "notebook");
        }
    }
}
