# Writem

Writem is a SwiftUI-first Markdown editor prototype for iPhone, iPad, and Mac. The repository starts with a document-based editing shell that keeps local `.md` files native, adds an immersive single-column editor, and reserves clear extension points for frontmatter, outline, media, table, and preflight workflows.

## Current baseline

- SwiftUI codebase with a shared iPhone/iPad target plus a separate native macOS target
- Document-based local file open/save using `DocumentGroup`
- Single-column writing mode, reading mode, and source mode
- Frontmatter form panel with two-way sync back into Markdown
- Outline extraction from `#` heading structure
- Preflight checks for metadata, heading jumps, empty links, unclosed code fences, absolute paths, and long paragraphs
- Image import into a local `assets/` directory with relative Markdown path generation
- Markdown snippet insertion menu for common blocks
- Reading view with styled headings, quotes, lists, code blocks, and local image preview

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
2. Select the `Writem` scheme for iPhone/iPad, or `WritemMac` for native macOS.
3. Run on an iPhone simulator, iPad simulator, or a native macOS destination.

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
