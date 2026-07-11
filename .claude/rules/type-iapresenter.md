---
paths:
  - "**/*.iapresenter/**"
---

# iA Presenter Bundles (`.iapresenter/`)

An `.iapresenter` presentation is a **directory** (not a zip), openable directly by [iA Presenter](https://ia.net/presenter):

```
presentation-name.iapresenter/
├── text.md       — the full presentation content (edit this directly)
├── info.json     — theme, appearance, footer, and template settings
└── assets/       — local images and media referenced in text.md
```

Official docs: https://ia.net/presenter/support/basics/markdown (syntax), https://ia.net/presenter/support/visuals/themes (custom themes).

**No YAML frontmatter.** `text.md` begins directly with content. A leading `---` frontmatter block is parsed as a slide separator, not metadata, so deck settings belong in `info.json`, never in frontmatter.

## The Core Rule: Slides vs. Speaker Notes

- **Normal paragraphs** (no indent) → speaker notes only, not visible to audience
- **Tab-indented content** → appears on the slide
- **Headings** (`#`, `##`, etc.) → always appear on slides, no tab needed

```markdown
# Slide Title

This paragraph is a speaker note.

	This tab-indented paragraph appears on the slide.

	- Tabbed list items appear on the slide

- This list has no tab, so it's speaker notes only
```

Applies to lists, blockquotes, and tables too — they need a tab prefix to render on-slide.

## info.json

```json
{
  "creatorIdentifier" : "net.ia.presenter",
  "net.ia.presenter" : {
    "appearance" : "dark",
    "footerleading" : "Footer left text",
    "logo" : "/assets/logo.svg",
    "preset" : "Default",
    "template" : "template-name"
  },
  "transient" : false,
  "type" : "net.daringfireball.markdown",
  "version" : 2
}
```

Do not include properties with empty string values — iA Presenter renders them as blank artifacts (e.g. an empty footer element) and won't remove them on its own. Omit unused properties instead of setting `""`.

## Slide Separators

A horizontal rule (`---`) starts a new slide. Multiple headings sharing one slide (no `---` between them) is intentional — useful for agenda or day-by-day layouts.

## Media Slides

An image path or URL at the top of a slide (before any heading or content) fills the slide with that media:

```markdown
/assets/image.png
size: contain
```

Directives: `size: contain|cover`, `x: left|right`, `y: top|bottom`, `title: "Caption text"`. Local assets use `/assets/filename.ext` (relative to the bundle root, no `presentations/`-style prefix). Multiple image paths on one slide without `---` between them auto-layout as a grid/split.

## Other Syntax

- Tab-indented content **before** an H1 renders as a label/tagline above the title
- Lines starting with `//` are presenter-only comments, never shown on-slide or exported
- Text extensions beyond standard markdown: `==highlight==`, `x^2^` superscript, `H~2~O` subscript

## Layout Alignment Trick

To force alignment between content groups in a multi-column auto-layout (e.g. aligning labels across columns), insert an invisible spacer block: a line containing a tab character followed by a non-breaking space (`U+00A0`). It has no visible glyph but iA Presenter treats it as a content block for layout balancing.
