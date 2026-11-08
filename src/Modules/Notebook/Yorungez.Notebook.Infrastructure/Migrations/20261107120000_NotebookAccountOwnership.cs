using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Yorungez.Notebook.Infrastructure.Migrations;

[DbContext(typeof(NotebookDatabase))]
[Migration("20261107120000_NotebookAccountOwnership")]
public sealed class NotebookAccountOwnership : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Identity migrates first. Keep the ownership rule in PostgreSQL so a write
        // already in flight cannot recreate private rows for a deleted account.
        migrationBuilder.AddForeignKey("FK_Entries_AccountOwner", "Entries", "UserId", "AspNetUsers",
            schema: "notebook", principalSchema: "identity", principalColumn: "Id", onDelete: ReferentialAction.Cascade);
        migrationBuilder.AddForeignKey("FK_Reminders_AccountOwner", "Reminders", "UserId", "AspNetUsers",
            schema: "notebook", principalSchema: "identity", principalColumn: "Id", onDelete: ReferentialAction.Cascade);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey("FK_Reminders_AccountOwner", "Reminders", "notebook");
        migrationBuilder.DropForeignKey("FK_Entries_AccountOwner", "Entries", "notebook");
    }
}
