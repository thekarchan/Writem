# Writem

Writem is a SwiftUI-first Markdown editor prototype for iPhone, iPad, and Mac. The repository starts with a document-based editing shell that keeps local `.md` files native, adds an immersive single-column editor, and reserves clear extension points for frontmatter, outline, media, table, and preflight workflows.

## Current baseline

- SwiftUI codebase with one shared UI target for iPhone and iPad, plus Mac support through Mac Catalyst
- Document-based local file open/save using `DocumentGroup`
- Single-column writing mode, reading mode, and source mode
- Frontmatter form panel with two-way sync back into Markdown
- Outline extraction from `#` heading structure
- Preflight checks for metadata, heading jumps, empty links, unclosed code fences, absolute paths, and long paragraphs
- Markdown snippet insertion menu for common blocks
- Reading view with styled headings, quotes, lists, and code blocks

## Repository layout

```text
Writem/
├── Docs/
│   ├── Architecture.md
│   └── PRD.md
├── Writem.xcodeproj/
└── Writem/
    ├── Assets.xcassets/
    ├── Models/
    ├── Services/
    ├── Views/
    └── WritemApp.swift
```

## Open in Xcode

1. Open [Writem.xcodeproj](/Users/karchan/Documents/New project/Writem/Writem.xcodeproj).
2. Select the `Writem` scheme.
3. Run on an iPhone simulator, iPad simulator, or `My Mac (Designed for iPad)` / Mac Catalyst destination.

## Local validation

Because this machine has full Xcode installed outside the active `xcode-select` path, local validation can use:

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project Writem.xcodeproj \
  -scheme Writem \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Product docs

- PRD: [Docs/PRD.md](/Users/karchan/Documents/New project/Writem/Docs/PRD.md)
- Architecture: [Docs/Architecture.md](/Users/karchan/Documents/New project/Writem/Docs/Architecture.md)

