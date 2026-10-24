// Tests for the companion page. Run: node --test site/tests/
// The fixture is written by the game's own report builder:
//   python3 scripts/run_self_tests.py --emit-sample site/tests/fixtures/sample-report.txt
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { parse, REQUIRED_SECTIONS } = require("../parser.js");

const fixture = fs.readFileSync(path.join(__dirname, "fixtures", "sample-report.txt"), "utf8");

test("parses the report the game actually writes", () => {
  const result = parse(fixture);
  assert.equal(result.ok, true, JSON.stringify(result.errors));
  assert.deepEqual(result.warnings, []);
  const names = result.report.sections.map((section) => section.name);
  for (const name of REQUIRED_SECTIONS) {
    assert.ok(names.includes(name), `missing ${name}`);
  }
  assert.match(result.report.header.SOURCE, /Simulated game evidence/);
});

test("splits alternatives into option, pros, and cons", () => {
  const result = parse(fixture);
  const alternatives = result.report.sections.find((s) => s.name === "ALTERNATIVES").alternatives;
  assert.ok(alternatives.length >= 2);
  assert.equal(alternatives[0].label, "A");
  assert.ok(alternatives[0].pros.length > 0 && alternatives[0].cons.length > 0);
});

test("handles Windows line endings and a byte-order mark", () => {
  const result = parse("﻿" + fixture.replace(/\n/g, "\r\n"));
  assert.equal(result.ok, true);
});

test("rejects empty input with a friendly message", () => {
  const result = parse("   ");
  assert.equal(result.ok, false);
  assert.match(result.errors[0], /Paste/);
});

test("rejects text without the header line", () => {
  const result = parse(fixture.split("\n").slice(1).join("\n"));
  assert.equal(result.ok, false);
  assert.match(result.errors[0], /first line/);
});

test("explains an unsupported version", () => {
  const result = parse(fixture.replace("DARKSKY-REPORT v1", "DARKSKY-REPORT v9"));
  assert.equal(result.ok, false);
  assert.match(result.errors[0], /not supported/);
});

test("reports a missing section", () => {
  const result = parse(fixture.replace("## RECOMMENDATION", "## SOMETHING ELSE"));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes("RECOMMENDATION")));
});

test("warns when the end of the report was not copied", () => {
  const result = parse(fixture.replace("END OF REPORT", ""));
  assert.equal(result.ok, true);
  assert.ok(result.warnings.some((w) => w.includes("END OF REPORT")));
});

test("keeps markup as plain text (the page never renders HTML from the report)", () => {
  const result = parse(fixture.replace("## REFLECTION\n", "## REFLECTION\n<img src=x onerror=alert(1)>\n"));
  assert.equal(result.ok, true);
  const reflection = result.report.sections.find((s) => s.name === "REFLECTION");
  assert.equal(reflection.lines[0].text, "<img src=x onerror=alert(1)>");
  const app = fs.readFileSync(path.join(__dirname, "..", "app.js"), "utf8");
  assert.ok(!/innerHTML|outerHTML|insertAdjacentHTML|document\.write/.test(app), "app.js must not insert HTML");
});

test("rejects overlong input", () => {
  assert.equal(parse("DARKSKY-REPORT v1\n" + "x".repeat(25000)).ok, false);
});

test("the page makes no network requests and loads nothing external", () => {
  const app = fs.readFileSync(path.join(__dirname, "..", "app.js"), "utf8");
  const parser = fs.readFileSync(path.join(__dirname, "..", "parser.js"), "utf8");
  for (const source of [app, parser]) {
    assert.ok(!/fetch\(|XMLHttpRequest|sendBeacon|WebSocket|EventSource|importScripts/.test(source));
  }
  const html = fs.readFileSync(path.join(__dirname, "..", "index.html"), "utf8");
  assert.ok(!/https?:\/\//.test(html.replace(/<!--[\s\S]*?-->/g, "")), "index.html must not reference external URLs");
  assert.match(html, /connect-src 'none'/);
});
