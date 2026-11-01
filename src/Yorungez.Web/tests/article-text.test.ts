import assert from "node:assert/strict";
import test from "node:test";
import { plainArticleText } from "../lib/article-text.ts";

test("external article/credit display strips markup without reconstructing tags", () => {
  assert.equal(plainArticleText('Photo by <a href="https://example.invalid">Public Author</a>'), "Photo by Public Author");
  assert.equal(plainArticleText("Güneş · Yörünge & sky"), "Güneş · Yörünge & sky");
  for (const value of ["<scrip<script>t>alert(1)</script>", "<<img>script>", "<unclosed", "unopened>", "<!<--comment-->>", "<".repeat(2000) + ">".repeat(2000)]) {
    assert.doesNotMatch(plainArticleText(value), /[<>]/);
  }
  assert.equal(plainArticleText("x".repeat(2000)).length, 1500);
  // Truncation must also preserve the no-angle-bracket invariant.
  assert.doesNotMatch(plainArticleText("x".repeat(1499) + "<<script>t>"), /[<>]/);
});
