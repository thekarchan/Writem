# Writem Architecture

## Goal

Build a Markdown editor that keeps source files native while giving writers a focused SwiftUI experience on iPhone, iPad, and Mac.

## App shape

Writem currently uses a document-based SwiftUI app with shared source files across:

- `Writem` target for iPhone and iPad
- `WritemMac` target for native macOS
- `DocumentGroup` handles opening and saving local Markdown files.
- `EditorRootView` owns the top-level writing experience.
- `MarkdownFileDocument` stores the raw Markdown source as the source of truth.
- Side features such as outline, frontmatter, and preflight derive from that source instead of maintaining separate persistence.

## Initial module split

### App

- `WritemApp.swift`
  - App entry
  - Creates document scenes

### Models

- `MarkdownFileDocument`
  - Wraps `.md` file loading and saving
- `Frontmatter`
  - Canonical in-memory metadata model
- `OutlineItem`
  - Heading tree row model
- `PreflightIssue`
  - Error / warning result model
- `EditorMode`
  - Write / Read / Source modes
- `LineWidthPreset`
  - Comfortable writing widths

### Services

- `FrontmatterParser`
  - Reads and rewrites YAML frontmatter inside raw Markdown
- `MarkdownAnalyzer`
  - Derives outline and preflight results
- `SnippetLibrary`
  - Shared insertion templates
- `SampleDocument`
  - Default seed content for new files
- `ClipboardService`
  - Cross-platform copy action for code blocks
- `ImageResourceManager`
  - Creates the local `assets/` folder
  - Imports image files beside the current document
  - Generates relative Markdown image paths

### Views

- `EditorRootView`
  - Split layout, mode switching, utility panels
- `EditorCanvasView`
  - Main editor surface and immersive card layout
- `MarkdownPreviewView`
  - Reading mode renderer for headings, quotes, lists, code blocks
- `OutlineSidebarView`
  - Structural navigation panel
- `FrontmatterPanelView`
  - Metadata form editor
- `PreflightPanelView`
  - Publish checks and issue list

## Why this structure

- The raw Markdown text remains the only durable state.
- Frontmatter, outline, and checks can be recomputed cheaply and stay consistent.
- The current split is small enough for V1 while still leaving room for later feature targets such as:
  - image asset management
  - table editor
  - richer Markdown AST rendering
  - export pipelines
  - publishing adapters for Hugo, Jekyll, and Astro

## V1 implementation status

### Implemented in this scaffold

- Document-based local file editing
- Single-column writing shell
- Basic reading/source mode switching
- Frontmatter form and rewrite
- Heading outline extraction
- Preflight core checks
- Code block copy action in reading mode
- Image import to local `assets/` with relative path insertion
- Native macOS app target in the same Xcode project

### Reserved next

- image import and asset relocation
- visual table editor
- richer inline formatting commands with cursor-aware insertion
- PDF / HTML export
- block folding
- publish-ready filesystem validation using the actual current document URL
