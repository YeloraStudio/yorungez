using System.Text.Json;
using Yorungez.Application;

namespace Yorungez.Api.Localization;

public sealed class TextCatalog : ITextCatalog
{
    private readonly Dictionary<string, Dictionary<string, string>> _languages = new(StringComparer.Ordinal);
    public TextCatalog()
    {
        foreach (var language in new[] { "tr", "en" })
        {
            using var stream = typeof(TextCatalog).Assembly.GetManifestResourceStream($"Yorungez.Api.Localization.{language}.json")
                ?? throw new InvalidOperationException("Localization resource missing.");
            _languages[language] = JsonSerializer.Deserialize<Dictionary<string, string>>(stream)!;
        }
        if (!_languages["tr"].Keys.ToHashSet(StringComparer.Ordinal).SetEquals(_languages["en"].Keys)
            || _languages.Values.Any(messages => messages.Values.Any(string.IsNullOrWhiteSpace)))
            throw new InvalidOperationException("All public message keys require non-empty tr/en translations.");
    }
    public string Get(string code, string culture) => _languages.TryGetValue(culture, out var messages)
        && messages.TryGetValue(code, out var text) ? text
        : throw new InvalidOperationException($"Missing required translation: {culture}/{code}");
}
