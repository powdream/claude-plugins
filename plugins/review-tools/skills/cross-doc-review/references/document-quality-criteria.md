# Document-quality criteria (reader's perspective)

The default review lens for `cross-doc-review`. These check whether a document
is good to *read* — structure, terminology, rhythm — not whether the underlying
subject is technically correct. Pass the whole list to both reviewers verbatim,
or adapt it for a different artifact type.

1. **Glossary present, and up front.** For a jargon-heavy document, is there a
   *dedicated* terms section near the top — before the requirements and design
   sections — rather than definitions scattered inline where the reader meets
   them too late? Group it by area when the vocabulary spans several domains.
   Near-identical names that are easy to confuse (e.g. a role vs. a group
   differing by one letter) are called out.
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
14. **One testable case per use case.** Where the document lists use cases or
    test cases, each is one actor + one precondition + one action, and every
    expected-result bullet is observable from that action alone. An "and"-bullet
    that introduces a **new action** or a **different precondition** is a second
    case merged into the first — split it. Conversely, cases that differ only in
    restating the same action are merged. Each case traces to a requirement.
15. **User story structured by actor, with real scenarios.** Where the document
    has user stories, they are sub-sectioned **per actor**; each actor opens with
    a short "as an X, I want Y, because Z" statement and then walks concrete,
    named scenarios of actual use — what that actor really does, step by step,
    and what changes for them. Two failures to catch: a single undifferentiated
    prose blob, and a bare list of one-line stories with no scenario behind them.
    Both leave the reader unable to picture how the system is actually used.
16. **Wireframes legible once rendered.** Where screens are sketched: an ASCII
    wireframe must not mix full-width (CJK) and half-width characters inside its
    box borders — the columns will not line up when rendered, since full-width
    glyphs occupy two columns. When a screen cannot be drawn cleanly in ASCII,
    it is an SVG asset committed beside the document and referenced as an image,
    with its states and labels also present as text (alt text or an adjacent
    table) so the content stays searchable.
