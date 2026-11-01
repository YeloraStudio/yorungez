export async function readJson(request: Request, maxBytes = 2048): Promise<unknown> {
  const reader = request.body?.getReader(); if (!reader) throw new Error("body");
  let size = 0; const chunks: Uint8Array[] = [];
  for (;;) { const part = await reader.read(); if (part.done) break;
    size += part.value.length; if (size > maxBytes) { await reader.cancel(); throw new Error("size"); } chunks.push(part.value); }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return JSON.parse(new TextDecoder().decode(bytes));
}
