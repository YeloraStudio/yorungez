namespace Yorungez.Catalog.Domain;

public sealed record TermTranslation(string Name, string Definition, string[] Aliases);
public sealed record GlossaryTerm(string Id, string? Abbreviation, string Category,
    Dictionary<string, TermTranslation> Translations, string[] Sources);
