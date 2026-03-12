# Changelog

This file is updated with every code change committed to the repository.
Dates use the local repository commit date.

## 2026-03-12

- Add common keyboard shortcuts to the Markdown help reference
- Merge Auto, Light, and Dark into a single Theme submenu
- Use a native single-choice Theme picker in the View menu
- Make Show Toolbar a native action item and move auto theme under Theme
- Simplify View appearance controls into top-level auto theme and a Theme submenu
- Flatten View menu controls so Show Toolbar and Appearance sit at the top level
- Add editable writing font controls under Edit and sync them across editor settings
- Reorganize the File menu into Draft, Open, and Save groups with Reveal in Finder
- Add a Help menu markdown syntax reference window
- Group View menu controls into Editor and Appearance sections
- Debounce full-document markdown restyling to reduce typing lag
- Move theme selection into a nested View menu with explicit selection state
- Move toolbar and auto-theme toggles into the View menu
- Add a layered-paper app icon set and wire AppIcon into both targets
- Make the editor start writing from the top-left with minimal blank-page insets
- Convert the outline sidebar into a lightweight overlay drawer
- Turn utility panels into lightweight overlay drawers that no longer consume editor width
- Add File menu recent documents and make the editor surface full-width editable
- Add unsaved-changes confirmation before opening or replacing the current draft
- Switch app launch flow to a scratch-based writing session with app-managed open/save
- Simplify editor chrome with hidden toolbar and auto theme controls
- Add slash synonyms and natural language template matching
- Add slash palette match highlighting
- Add fuzzy slash matching and recent usage sorting
- `dfd44b5` Add numeric shortcuts for slash palette
- `a8b375e` Add slash templates and image import command
- `310024d` Add keyboard navigation for slash commands
- `6b5d33b` Add slash command editor palette
- `50b4eef` Add markdown auto-pair and inline exit flow
- `6515af1` Refine paste and auto-wrap editing flow
- `083b3f8` Add inline markdown formatting commands
- `b04bfc9` Refine backspace block exit flow
- `8d75f11` Refine return key writing flow
- `caf0965` Refine code block and frontmatter typing
- `1dbcc8b` Refine list and quote typing rhythm
- `8fa9111` Refine heading typing rhythm
- `bee0fc9` Refine empty document writing layout
- `a1c8909` Refine sidebar layering and transitions
- `9791fab` Refine header into menu bar
- `4d5a5de` Move utility panels into sidebar drawers
- `9545230` Refine editor scroll immersion
- `1084e46` Refine launch and empty document experience
- `5060533` Refine inline markdown emphasis
- `9b3fae5` Strengthen block boundaries in editor
- `84d79f7` Refine markdown block rhythm
- `b3efdc5` Refine editor page surface
- `8cffe9c` Lighten editor chrome toward typora
- `1a846d3` Add focused paragraph styling in editor
- `4879b7b` Soften markdown syntax markers in editor
- `5e5c258` Refine typora-like writing typography
- `6bcbc16` Add typora-style inline markdown editor
- `9c745fb` Simplify editor chrome and default to writing mode

## 2026-03-11

- `c2d47ff` Implement tables exports code blocks and iCloud sync
- `c6d167d` Fix iPhone document launch creation flow
- `638d7f8` Add macOS target and image asset workflow
- `8b4cdc9` Initial Writem scaffold
