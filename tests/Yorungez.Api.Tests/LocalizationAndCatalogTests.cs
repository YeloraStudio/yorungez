using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Yorungez.Application;
using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;
using Yorungez.Identity.Application;
using Yorungez.Identity.Domain;

namespace Yorungez.Api.Tests;

[Trait("Category", "Integration")]
public sealed class LocalizationAndCatalogTests(AppFactory app) : IClassFixture<AppFactory>
{
    [Theory]
    [InlineData("tr", "yorungez API çalışıyor.")]
    [InlineData("en", "The yorungez API is running.")]
    [InlineData("fr", "The yorungez API is running.")]
    [InlineData("en-GB,en;q=0.8,tr;q=0.5", "The yorungez API is running.")]
    public async Task Status_negotiates_supported_language_and_declares_it(string language, string expected)
    {
        using var client = app.Client(language);
        var response = await client.GetAsync("/api/v1/status");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(expected, body.GetProperty("message").GetString());
        Assert.Equal(body.GetProperty("language").GetString(), response.Content.Headers.ContentLanguage.Single());
    }

    [Fact]
    public async Task Missing_language_header_defaults_to_English()
    {
        using var client = app.Client(); client.DefaultRequestHeaders.AcceptLanguage.Clear();
        var response = await client.GetAsync("/api/v1/status");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("en", body.GetProperty("language").GetString());
        Assert.Equal("en", response.Content.Headers.ContentLanguage.Single());
    }

    [Fact]
    public async Task Every_shipped_term_has_both_languages_and_source_links_without_login()
    {
        using var tr = app.Client("tr"); using var en = app.Client("en");
        var turkish = (await tr.GetFromJsonAsync<TermView[]>("/api/v1/terms/"))!;
        var english = (await en.GetFromJsonAsync<TermView[]>("/api/v1/terms/"))!;
        Assert.Equal(52, turkish.Length);
        Assert.Equal(turkish.Select(t => t.Id).Order(), english.Select(t => t.Id).Order());
        foreach (var term in turkish.Concat(english))
        {
            Assert.False(string.IsNullOrWhiteSpace(term.Definition));
            Assert.False(string.IsNullOrWhiteSpace(term.CategoryName));
            Assert.NotEmpty(term.Sources);
            Assert.All(term.Sources, source => Assert.True(Uri.TryCreate(source, UriKind.Absolute, out _)));
        }
        Assert.Equal("ADQL", english.Single(t => t.Id == "adql").Abbreviation);
        Assert.Contains("Astronomical", english.Single(t => t.Id == "adql").Name);
        Assert.Contains("Astronomik", turkish.Single(t => t.Id == "adql").Name);
    }

    [Theory]
    [InlineData("tr", "yükseklik", "altitude")]
    [InlineData("tr", "yukseklik", "altitude")]
    [InlineData("en", "azimut", "azimuth")]
    [InlineData("tr", "ADQL", "adql")]
    public async Task Search_supports_names_aliases_abbreviations_and_Turkish_characters(string language, string query, string id)
    {
        using var client = app.Client(language);
        var terms = (await client.GetFromJsonAsync<TermView[]>("/api/v1/terms/?q=" + Uri.EscapeDataString(query)))!;
        Assert.Contains(terms, t => t.Id == id);
    }

    [Theory]
    [InlineData("tr", "Bu terim bulunamadı.")]
    [InlineData("en", "This term was not found.")]
    public async Task Errors_keep_stable_codes_and_localize_human_text(string language, string expected)
    {
        using var client = app.Client(language);
        var response = await client.GetAsync("/api/v1/terms/not-a-real-term");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Catalog.TermNotFound", body.GetProperty("code").GetString());
        Assert.Equal(expected, body.GetProperty("detail").GetString());
    }

    [Fact]
    public async Task Oversized_search_is_rejected_and_readiness_checks_real_infrastructure()
    {
        using var client = app.Client();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/v1/terms/?q=" + new string('a', 101))).StatusCode);
        var ready = await client.GetAsync("/health/ready");
        Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
        Assert.Equal("Healthy", await ready.Content.ReadAsStringAsync());
    }

    [Fact]
    public void Domain_and_application_layers_do_not_depend_on_infrastructure()
    {
        foreach (var assembly in new[] { typeof(GlossaryTerm).Assembly, typeof(RefreshSession).Assembly,
            typeof(FindTermsQuery).Assembly, typeof(RegisterCommand).Assembly, typeof(ICommand<>).Assembly,
            typeof(SolarSystemBody).Assembly, typeof(CalculateSkyQuery).Assembly,
            typeof(Yorungez.Notebook.Domain.NotebookEntry).Assembly, typeof(Yorungez.Notebook.Application.SaveNotebookCommand).Assembly })
            Assert.DoesNotContain(assembly.GetReferencedAssemblies(), a => a.Name!.Contains("Infrastructure")
                || a.Name.StartsWith("Microsoft.EntityFrameworkCore") || a.Name.StartsWith("Microsoft.AspNetCore"));
        Assert.DoesNotContain(typeof(FindTermsQuery).Assembly.GetReferencedAssemblies(), a => a.Name!.StartsWith("Yorungez.Identity"));
        Assert.DoesNotContain(typeof(RegisterCommand).Assembly.GetReferencedAssemblies(), a => a.Name!.StartsWith("Yorungez.Catalog"));
        Assert.DoesNotContain(typeof(CalculateSkyQuery).Assembly.GetReferencedAssemblies(), a =>
            a.Name!.StartsWith("Yorungez.Identity") || a.Name.StartsWith("Yorungez.Catalog") || a.Name.StartsWith("CosineKitty"));
        Assert.Equal(12, typeof(MediatR.ISender).Assembly.GetName().Version!.Major);
        Assert.DoesNotContain(typeof(Yorungez.Notebook.Application.SaveNotebookCommand).Assembly.GetReferencedAssemblies(), a =>
            a.Name!.StartsWith("Yorungez.Identity") || a.Name.StartsWith("Yorungez.Catalog") || a.Name.StartsWith("Yorungez.Astronomy"));
    }
}
