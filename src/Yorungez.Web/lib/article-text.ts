// Display formatting for external article/credit text, not an HTML rendering API.
// Consumers must keep using React text nodes; this must not authorize raw HTML.
export function plainArticleText(text: string): string {
  let inTag = false;
  let result = "";
  // Consume every angle bracket directly; nested/malformed markup cannot
  // reconstruct a delimiter after a multi-character replacement.
  for (const character of text) {
    if (character === "<") { inTag = true; continue; }
    if (character === ">") { inTag = false; continue; }
    if (!inTag) result += character;
    if (result.length >= 1500) break;
  }
  return result.slice(0, 1500);
}
