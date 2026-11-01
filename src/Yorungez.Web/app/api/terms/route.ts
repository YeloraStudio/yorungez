import glossary from "../../../generated/glossary.json";
export async function GET(request: Request) {
  const language = new URL(request.url).searchParams.get("lang") === "tr" ? "tr" : "en";
  const data = glossary.map(term => ({ id: term.id, abbreviation: term.abbreviation,
    ...term.translations[language], sources: term.sources }));
  return Response.json(data, { headers: { "Content-Language": language, "Cache-Control": "public, max-age=3600" } });
}
