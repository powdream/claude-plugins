# Document-quality criteria (reader's perspective)

The default review lens for `cross-doc-review`. These check whether a document
is good to *read* — structure, terminology, rhythm — not whether the underlying
subject is technically correct. Pass the whole list to both reviewers verbatim,
or adapt it for a different artifact type.

1. **Glossary present.** For a jargon-heavy document, is there a terms section
   defining the non-obvious vocabulary? Near-identical names that are easy to
   confuse (e.g. a role vs. a group differing by one letter) are called out.
2. **Term consistency.** The same concept is always called by the same name.
   Names used in requirements match the names used in the design (no
   requirement-to-design drift).
3. **No awkward coinages.** No invented or unnatural mixed-language terms used
   without definition.
4. **Diagrams for complex relationships.** Relationships too tangled for prose
   are shown in a diagram (e.g. mermaid), with a legend where the notation is
   not self-evident.
5. **No frequent duplication.** The same point is not restated across many
   sections; each point has one canonical home, others reference it.
6. **Logical section flow.** Sections and the outline develop in a sensible
   order; a decision or rationale is not buried inside an unrelated section.
7. **Lists, not walls of prose.** Long enumerable content is broken into
   ordered/unordered lists instead of dense paragraphs.
8. **Real headings, not bold-only.** Multi-part nested blocks use actual
   headings (`#`/`##`/…), not bold text standing in for a subsection.
9. **Written for the reader.** Assumptions and references are followable: ticket
   IDs, person names, prior artifacts, and internal jargon get a link or a
   one-line explanation rather than appearing cold. No unresolved placeholders.
10. **Light reading rhythm.** Not overloaded with parentheticals, slash-lists,
    or abbreviations that make sentences heavy.
11. **Body at the right altitude.** The body stays at the design/decision level;
    verbatim scripts, DDL, HCL, code, and long config are moved to an appendix
    or a linked detail document.
12. **No needed section missing.** Nothing the document's own template or purpose
    requires is absent.
13. **No unneeded section lingering.** Empty, boilerplate, or noise sections that
    do not earn their place are removed or absorbed.
