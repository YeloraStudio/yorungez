// Display formatting for external article/credit text, not an HTML rendering API.
// Consumers must keep using React text nodes; this must not authorize raw HTML.
export function plainArticleText(text: string): string {
  // Every angle bracket is consumed, including malformed/nested tag fragments.
  return text.replace(/<[^<>]*>|[<>]/g, "").slice(0, 1500);
}
