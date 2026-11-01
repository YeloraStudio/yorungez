using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yorungez.Notebook.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ObservationsAndSavedPlaces : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ObservationConfirmed",
                schema: "notebook",
                table: "Entries",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ObservedAtUtc",
                schema: "notebook",
                table: "Entries",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ObservationConfirmed",
                schema: "notebook",
                table: "Entries");

            migrationBuilder.DropColumn(
                name: "ObservedAtUtc",
                schema: "notebook",
                table: "Entries");
        }
    }
}
