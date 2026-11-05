using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yorungez.Identity.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AccountExplorationPreferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ExplorationPreferences",
                schema: "identity",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    MusicEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    SkyLayersJson = table.Column<string>(type: "jsonb", nullable: false),
                    Revision = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorationPreferences", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_ExplorationPreferences_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalSchema: "identity",
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExplorationPreferences",
                schema: "identity");
        }
    }
}
