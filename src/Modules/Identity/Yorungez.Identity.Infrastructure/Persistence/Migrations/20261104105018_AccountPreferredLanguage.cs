using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yorungez.Identity.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AccountPreferredLanguage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PreferredLanguage",
                schema: "identity",
                table: "AspNetUsers",
                type: "character varying(2)",
                maxLength: 2,
                nullable: false,
                defaultValue: "en");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PreferredLanguage",
                schema: "identity",
                table: "AspNetUsers");
        }
    }
}
