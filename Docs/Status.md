# Writem Status

This file tracks the current implementation baseline and the next most useful gaps to close.

## Implemented

- Scratch-first editor session with local save, autosave, and undo/redo
- Native macOS target plus shared iPhone/iPad target
- Single-column Markdown writing editor with inline styling
- Floating find and replace panel with next / previous / replace / replace all actions
- Slash command palette with templates, aliases, fuzzy matching, and keyboard navigation
- Frontmatter editing with source sync
- Outline drawer
- Table editing panel
- Code block highlighting and copy support
- Export to Markdown, HTML, and PDF
- Recent documents menu
- Basic preflight checks
- Local image import into an `assets/` folder with relative Markdown paths
- Settings sync toggle for iCloud-backed preferences

## Common Gaps

### P0

- Paste screenshot or clipboard image directly into the document
- Open a folder/workspace instead of only single-file editing
- Restore formal reading/source mode entry points
- Fold heading sections while editing

### P1

- Image compression and configurable asset destination rules
- Open imported asset location from the editor
- Better publish checks for site-specific metadata and links
- Document history / snapshot restore
- Better code block rendering for Mermaid and LaTeX previews

### P2

- App-managed cloud document library instead of file-provider-only sync
- Multi-tab document workflow
- Git integration
- AI assistance
- Plugin system

## In Progress

- Paste screenshot or clipboard image directly into the document
