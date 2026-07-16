<p align="center">
  <img src="logoalpha.png" alt="SwiftNotebook logo" width="160">
</p>

<h1 align="center">SwiftNotebook</h1>

<p align="center">
  <a href="https://swiftnotebook.vercel.app">
    <img src="https://img.shields.io/badge/website-swiftnotebook.vercel.app-B23A2E?style=for-the-badge" alt="SwiftNotebook website">
  </a>
</p>

A spiritual Swift successor to RedNotebook - a native macOS journal built from the ground up to feel like a first-party Mac app.

## Overview

SwiftNotebook is a local-first journaling app for macOS. There's no account to create and no server involved: you choose a folder on your Mac, and that folder becomes your journal. Everything is stored there in a local database, so it moves, backs up, and syncs exactly like any other file on your system. Drop it in iCloud Drive or Dropbox and it just works.

The writing experience is built on genuine rich text (the same `NSTextView` technology behind TextEdit and Notes), not a markdown dialect. Formatting is applied directly, so bold and italic look bold and italic while you're writing.

## Features

**Writing**
- Native rich text editing: bold, italic, and links apply live, with no markdown syntax visible in your entries
- Spellcheck built in
- Multiple entries per day, for days that need more than one page
- Type a date anywhere in an entry (e.g. `2026-07-01`) and it automatically becomes a link that jumps to that day

**Organization**
- Tags for freeform labeling, applied per entry
- Categories that behave like folders - file entries under a category and browse by it in the right sidebar
- Templates: assign one per weekday to auto-load into new entries, or create named templates to insert whenever you need them
- A mini calendar and library views ("All Entries," "This Month") for quickly jumping to any day

**Finding things**
- Full search across titles, body text, and tags
- A frequent-words cloud in the inspector, click any word to search for it instantly
- Right-click any entry for quick actions: rename, duplicate, file under a category, export, or delete

**Insight**
- A statistics view covering entry counts, word totals and averages, current and longest writing streaks, and your longest entry

**Export**
- Export the whole journal, a date range, or a single entry to plain text, HTML, or PDF

**Look and feel**
- Full dark mode support, including the text you've written, not just the surrounding chrome
- A warm, editorial visual style with serif type for journal content and system type for the UI

## Data and privacy

Your journal is a Core Data store sitting inside a folder you explicitly chose on first launch. SwiftNotebook keeps a security-scoped bookmark to that folder so it can reopen it automatically on future launches, but the data itself never leaves your Mac and never touches a server. Move the folder, back it up, or sync it with any cloud storage provider you already use.

## Requirements

macOS 15 or later.

## Building from source

1. Clone the repository.
2. Open `SwiftNotebook.xcodeproj` in Xcode.
3. Build and run.

The project has no third-party dependencies - it's built entirely on SwiftUI, AppKit, and Core Data.

## Tech stack

- **SwiftUI** for the app's UI and layout
- **AppKit** (`NSTextView`) for the rich text editor itself, wrapped for use in SwiftUI
- **Core Data** for local, on-disk storage of entries, templates, and categories
