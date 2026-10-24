/*
 * The Dark Sky — community report parser.
 *
 * Reads the plain-text report the game creates (format "DARKSKY-REPORT v1") and returns a
 * structured object, or a list of readable errors. Pure: no DOM, no network. Used by the
 * page (app.js) and by the tests (site/tests). Content is always treated as plain text.
 *
 * Format (written by src/shared/Shared/ReportBuilder.luau in the game):
 *   DARKSKY-REPORT v1
 *   KEY: value            (TITLE, LOCATION, FIXTURE, SOURCE, TOWN)
 *   ## SECTION NAME
 *   text line  |  - bullet line
 *   END OF REPORT
 */
(function (root, factory) {
  if (typeof module === "object" && module.exports) {
    module.exports = factory();
  } else {
    root.DarkSkyReport = factory();
  }
})(typeof self !== "undefined" ? self : this, function () {
  "use strict";

  var HEADER = "DARKSKY-REPORT v1";
  var HEADER_KEYS = ["TITLE", "LOCATION", "FIXTURE", "SOURCE", "TOWN"];
  var REQUIRED_SECTIONS = [
    "PROBLEM",
    "EVIDENCE",
    "BEFORE AND AFTER",
    "ALTERNATIVES",
    "RECOMMENDATION",
    "TRADE-OFFS",
    "ESSENTIAL LIGHTING KEPT",
    "NEXT STEPS",
    "REFLECTION",
  ];
  var OPTIONAL_SECTIONS = ["OPTIONAL REAL-WORLD OBSERVATIONS"];
  var MAX_TOTAL_LENGTH = 20000;
  var MAX_LINE_LENGTH = 1000;

  function parseAlternative(text) {
    // "Option A: text | Pros: ... | Cons: ..."
    var match = /^Option ([A-Z]): (.*?) \| Pros: (.*?) \| Cons: (.*)$/.exec(text);
    if (!match) {
      return null;
    }
    return { label: match[1], text: match[2], pros: match[3], cons: match[4] };
  }

  function parse(input) {
    var errors = [];
    var warnings = [];
    if (typeof input !== "string" || input.trim() === "") {
      return { ok: false, errors: ["Paste the report text from the game first."], warnings: warnings };
    }
    if (input.length > MAX_TOTAL_LENGTH) {
      return { ok: false, errors: ["This text is too long to be a Dark Sky report."], warnings: warnings };
    }

    var lines = input.replace(/^﻿/, "").replace(/\r\n?/g, "\n").split("\n");
    var index = 0;
    while (index < lines.length && lines[index].trim() === "") {
      index += 1;
    }
    var first = (lines[index] || "").trim();
    if (first !== HEADER) {
      if (/^DARKSKY-REPORT v\d+$/.test(first)) {
        errors.push("This report version (" + first + ") is not supported by this page. Try the latest website.");
      } else {
        errors.push('The first line should be "' + HEADER + '". Copy the whole report from the game, including the first line.');
      }
      return { ok: false, errors: errors, warnings: warnings };
    }
    index += 1;

    var header = {};
    var sections = [];
    var current = null;
    var ended = false;
    for (; index < lines.length; index += 1) {
      var raw = lines[index];
      var line = raw.trim();
      if (line.length > MAX_LINE_LENGTH) {
        errors.push("Line " + (index + 1) + " is too long.");
        continue;
      }
      if (line === "") {
        continue;
      }
      if (line === "END OF REPORT") {
        ended = true;
        break;
      }
      if (line.indexOf("## ") === 0) {
        current = { name: line.slice(3).trim(), lines: [] };
        sections.push(current);
        continue;
      }
      if (current === null) {
        var keyMatch = /^([A-Z]+): (.*)$/.exec(line);
        if (keyMatch && HEADER_KEYS.indexOf(keyMatch[1]) !== -1) {
          header[keyMatch[1]] = keyMatch[2];
        } else {
          warnings.push("Ignored an unexpected line near the top: " + line.slice(0, 60));
        }
        continue;
      }
      if (line.indexOf("- ") === 0) {
        current.lines.push({ type: "bullet", text: line.slice(2) });
      } else {
        current.lines.push({ type: "text", text: line });
      }
    }

    if (!ended) {
      warnings.push('The report did not end with "END OF REPORT". Part of it may be missing; copy it again if anything looks cut off.');
    }
    HEADER_KEYS.forEach(function (key) {
      if (!header[key]) {
        errors.push("The report is missing its " + key.toLowerCase() + " line.");
      }
    });
    var names = sections.map(function (section) {
      return section.name;
    });
    REQUIRED_SECTIONS.forEach(function (name) {
      if (names.indexOf(name) === -1) {
        errors.push('The report is missing the "' + name + '" section.');
      }
    });
    sections.forEach(function (section) {
      if (REQUIRED_SECTIONS.indexOf(section.name) === -1 && OPTIONAL_SECTIONS.indexOf(section.name) === -1) {
        warnings.push('Unknown section "' + section.name + '" will be shown as plain text.');
      }
      if (section.name === "ALTERNATIVES") {
        section.alternatives = section.lines
          .filter(function (entry) {
            return entry.type === "bullet";
          })
          .map(function (entry) {
            return parseAlternative(entry.text) || { label: "", text: entry.text, pros: "", cons: "" };
          });
      }
    });

    if (errors.length > 0) {
      return { ok: false, errors: errors, warnings: warnings };
    }
    return { ok: true, report: { header: header, sections: sections }, warnings: warnings };
  }

  return {
    HEADER: HEADER,
    REQUIRED_SECTIONS: REQUIRED_SECTIONS,
    parse: parse,
  };
});
