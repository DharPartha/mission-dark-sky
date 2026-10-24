/*
 * The Dark Sky — companion page logic.
 * Parses the pasted report, shows it as a clean printable page, and prints to PDF with the
 * browser's own print dialog. All text is inserted with textContent (never as HTML).
 * No network requests of any kind: nothing is sent, stored on a server, or tracked.
 */
(function () {
  "use strict";

  var SECTION_TITLES = {
    PROBLEM: "Problem",
    EVIDENCE: "Simulated game evidence",
    "BEFORE AND AFTER": "Before and after (simulated)",
    ALTERNATIVES: "Alternatives considered",
    RECOMMENDATION: "Recommendation",
    "TRADE-OFFS": "Trade-offs",
    "ESSENTIAL LIGHTING KEPT": "Essential lighting kept",
    "NEXT STEPS": "Next steps",
    REFLECTION: "Reflection",
    "OPTIONAL REAL-WORLD OBSERVATIONS": "Real-world observations (optional)",
  };

  var input = document.getElementById("report-input");
  var messages = document.getElementById("messages");
  var previewSection = document.getElementById("preview-section");
  var preview = document.getElementById("preview");
  var lastText = "";

  function element(tag, text, className) {
    var node = document.createElement(tag);
    if (text !== undefined && text !== null) {
      node.textContent = text;
    }
    if (className) {
      node.className = className;
    }
    return node;
  }

  function showMessages(errors, warnings) {
    messages.textContent = "";
    if (errors.length > 0) {
      var errorList = element("ul", null, "errors");
      errors.forEach(function (text) {
        errorList.appendChild(element("li", text));
      });
      messages.appendChild(element("p", "We couldn't read that report:", "error-title"));
      messages.appendChild(errorList);
    }
    if (warnings.length > 0) {
      var warningList = element("ul", null, "warnings");
      warnings.forEach(function (text) {
        warningList.appendChild(element("li", text));
      });
      messages.appendChild(warningList);
    }
  }

  function renderLines(container, lines) {
    var list = null;
    lines.forEach(function (entry) {
      if (entry.type === "bullet") {
        if (!list) {
          list = element("ul");
          container.appendChild(list);
        }
        list.appendChild(element("li", entry.text));
      } else {
        list = null;
        container.appendChild(element("p", entry.text));
      }
    });
  }

  function renderAlternatives(container, alternatives) {
    var table = element("table");
    var head = element("tr");
    ["Option", "What", "Pros", "Cons"].forEach(function (title) {
      head.appendChild(element("th", title));
    });
    table.appendChild(head);
    alternatives.forEach(function (option) {
      var row = element("tr");
      [option.label, option.text, option.pros, option.cons].forEach(function (text) {
        row.appendChild(element("td", text));
      });
      table.appendChild(row);
    });
    container.appendChild(table);
  }

  function realWorldSection() {
    var place = document.getElementById("real-place").value.trim();
    var notes = document.getElementById("real-notes").value.trim();
    var adult = document.getElementById("real-adult").checked;
    if (place === "" && notes === "") {
      return null;
    }
    var section = element("section", null, "real-world");
    section.appendChild(element("h3", "Real-world observations (added outside the game — not game evidence)"));
    section.appendChild(element("p", adult ? "Checked with a trusted adult." : "Not marked as checked by an adult.", "note"));
    if (place !== "") {
      section.appendChild(element("p", "Kind of place: " + place));
    }
    if (notes !== "") {
      section.appendChild(element("p", notes));
    }
    return section;
  }

  function render(report) {
    preview.textContent = "";
    var header = report.header;
    preview.appendChild(element("p", "THE DARK SKY", "kicker"));
    var title = element("h2", header.TITLE);
    title.id = "preview-heading";
    preview.appendChild(title);
    var facts = element("dl", null, "facts");
    [["Place", header.LOCATION], ["Lights", header.FIXTURE], ["Evidence", header.SOURCE], ["Town", header.TOWN]].forEach(function (pair) {
      facts.appendChild(element("dt", pair[0]));
      facts.appendChild(element("dd", pair[1]));
    });
    preview.appendChild(facts);

    report.sections.forEach(function (section) {
      if (section.name === "OPTIONAL REAL-WORLD OBSERVATIONS") {
        return;
      }
      var block = element("section");
      block.appendChild(element("h3", SECTION_TITLES[section.name] || section.name));
      if (section.alternatives) {
        renderAlternatives(block, section.alternatives);
      } else {
        renderLines(block, section.lines);
      }
      preview.appendChild(block);
    });

    // Real-world observations always print under their own heading, never mixed with game evidence.
    var realWorld = realWorldSection();
    if (realWorld) {
      preview.appendChild(realWorld);
    } else {
      var blank = element("section", null, "real-world");
      blank.appendChild(element("h3", "Real-world observations (optional, with a trusted adult)"));
      var note = report.sections.filter(function (section) {
        return section.name === "OPTIONAL REAL-WORLD OBSERVATIONS";
      })[0];
      if (note) {
        renderLines(blank, note.lines);
      }
      blank.appendChild(element("div", "", "write-in"));
      preview.appendChild(blank);
    }
    preview.appendChild(element("p", "Don't eliminate light. Make every light count.", "closing"));
    previewSection.hidden = false;
  }

  function show() {
    lastText = input.value;
    var result = window.DarkSkyReport.parse(lastText);
    showMessages(result.ok ? [] : result.errors, result.warnings || []);
    if (!result.ok) {
      previewSection.hidden = true;
      input.focus();
      return;
    }
    render(result.report);
    document.getElementById("print-report").focus();
  }

  function copyText() {
    var text = lastText;
    var done = function () {
      showMessages([], ["Report text copied."]);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, function () {
        input.focus();
        input.select();
      });
    } else {
      // Fallback: select the text so it can be copied with the keyboard.
      input.focus();
      input.select();
    }
  }

  document.getElementById("show-report").addEventListener("click", show);
  document.getElementById("clear-report").addEventListener("click", function () {
    input.value = "";
    lastText = "";
    messages.textContent = "";
    previewSection.hidden = true;
    input.focus();
  });
  document.getElementById("print-report").addEventListener("click", function () {
    // Re-render so the latest real-world notes are included, then open the print dialog.
    var result = window.DarkSkyReport.parse(lastText);
    if (result.ok) {
      render(result.report);
    }
    window.print();
  });
  document.getElementById("copy-report").addEventListener("click", copyText);
  ["real-place", "real-notes", "real-adult"].forEach(function (id) {
    document.getElementById(id).addEventListener("change", function () {
      if (!previewSection.hidden) {
        show();
      }
    });
  });
})();
