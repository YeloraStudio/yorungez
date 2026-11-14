using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Yorungez.Notebook.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class WeatherDependentReminders : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "ForecastElevationMeters",
                schema: "notebook",
                table: "Reminders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "ForecastLatitude",
                schema: "notebook",
                table: "Reminders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "ForecastLongitude",
                schema: "notebook",
                table: "Reminders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "WeatherDependent",
                schema: "notebook",
                table: "Reminders",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ForecastElevationMeters",
                schema: "notebook",
                table: "Reminders");

            migrationBuilder.DropColumn(
                name: "ForecastLatitude",
                schema: "notebook",
                table: "Reminders");

            migrationBuilder.DropColumn(
                name: "ForecastLongitude",
                schema: "notebook",
                table: "Reminders");

            migrationBuilder.DropColumn(
                name: "WeatherDependent",
                schema: "notebook",
                table: "Reminders");
        }
    }
}
