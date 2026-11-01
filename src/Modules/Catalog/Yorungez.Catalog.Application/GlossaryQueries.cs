using System.Globalization;
using System.Text;
using MediatR;
using Yorungez.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Application;

public interface IGlossaryRepository
{
    Task<IReadOnlyList<GlossaryTerm>> GetAllAsync(CancellationToken cancellationToken);
}

public sealed record TermView(string Id, string? Abbreviation, string Name,
    string Definition, string Category, string CategoryName, string Language, string[] Sources);
public sealed record FindTermsQuery(string? Search, string Language) : IQuery<IReadOnlyList<TermView>>;
public sealed record GetTermQuery(string Id, string Language) : IQuery<TermView>;

public sealed class FindTermsHandler(IGlossaryRepository repository, ITextCatalog texts)
    : IRequestHandler<FindTermsQuery, IReadOnlyList<TermView>>
{
    public async Task<IReadOnlyList<TermView>> Handle(FindTermsQuery request, CancellationToken ct)
    {
        if (request.Search?.Length > 100)
            throw new AppFailure("Common.InvalidInput", FailureKind.Validation);
        var terms = await repository.GetAllAsync(ct);
        var search = Normalize(request.Search ?? "");
        return terms.Where(t => search.Length == 0 || Normalize(t.Id).Contains(search, StringComparison.Ordinal)
            || Normalize(t.Abbreviation ?? "").Contains(search, StringComparison.Ordinal)
            || t.Translations.Values.Any(v => Normalize(v.Name).Contains(search, StringComparison.Ordinal)
                || v.Aliases.Any(a => Normalize(a).Contains(search, StringComparison.Ordinal))))
            .Select(t => View(t, request.Language, texts))
            .OrderBy(t => t.Name, StringComparer.Create(CultureInfo.GetCultureInfo(request.Language), true))
            .ToArray();
    }

    internal static TermView View(GlossaryTerm term, string language, ITextCatalog texts)
    {
        if (!term.Translations.TryGetValue(language, out var translation))
            throw new InvalidOperationException("A required glossary translation is missing.");
        return new(term.Id, term.Abbreviation, translation.Name, translation.Definition,
            term.Category, texts.Get("Category." + term.Category, language), language, term.Sources);
    }

    private static string Normalize(string value) => string.Concat(value.Normalize(NormalizationForm.FormD)
        .Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark))
        .Replace('ı', 'i').ToLowerInvariant();
}

public sealed class GetTermHandler(IGlossaryRepository repository, ITextCatalog texts) : IRequestHandler<GetTermQuery, TermView>
{
    public async Task<TermView> Handle(GetTermQuery request, CancellationToken ct)
    {
        var term = (await repository.GetAllAsync(ct)).SingleOrDefault(t => t.Id == request.Id)
            ?? throw new AppFailure("Catalog.TermNotFound", FailureKind.NotFound);
        return FindTermsHandler.View(term, request.Language, texts);
    }
}
