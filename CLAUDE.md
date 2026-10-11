# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

*Programming the MEGA65* is a book, published as a static HTML site on GitHub Pages at `m65.ctalkobt.net` (see `CNAME`). It is modeled on Raeto Colin West's *Programming the Commodore 64*: the machine and BASIC 65 first, then 45GS02 machine language, then graphics, sound, storage and peripherals. The license is LGPL 2.1.

There is no build system, test suite or linter. The HTML files at the root are the published site. To preview it, open `index.html` in a browser or run `python3 -m http.server`.

## Structure

- `index.html` is the table of contents. It is hand-written, minified onto a few lines, and links every chapter.
- `chNN-<slug>.html` (chapters 1–17) and `appendices.html` hold the book's content. Each is a standalone pandoc-generated HTML5 page (`<meta name="generator" content="pandoc">`) with pandoc's default inline `<style>` block, plus a link to the shared `style.css`.
- `style.css` holds the shared look: a narrow serif body, dark mode through `prefers-color-scheme`, tables that scroll sideways, and `nav.chapnav`.

The pandoc source (Markdown) is **not** in this repo, so edit the HTML directly.

## Conventions to preserve when editing

- **Chapter navigation:** each chapter has an identical `<nav class="chapnav">` bar right after `<body>` and again right before `</body>`. It has three parts: a "← Previous" link (an empty `<span></span>` in chapter 1), a link to "Contents", and a "Next →" link. If you add, remove or rename a chapter, update the nav bars in the chapters on either side and the list in `index.html`.
- **Page header:** each chapter has one `<h1>` in the form "Programming the MEGA65 — Chapter N: Title", followed by a date/byline paragraph (`<p>Oct 4, 2026 · @Craig Taylor</p>`). Heading `id`s are pandoc-style slugs.
- **Citations:** facts taken from the official MEGA65 manual are cited inline as `(MEGA65 Book, p. X-NN)`. This refers to the August 2025 edition of the MEGA65 Book. When a newer source supersedes it, the text cites that source instead.
- **Code:** BASIC and assembly listings go in `<pre><code>`. Register addresses, keywords and opcodes go in inline `<code>`. Reference material (registers, opcodes, keywords, ROM entry points) mostly lives in tables (`<table>` with `<thead>`/`<tbody>`).
- **Version-dependent features:** the text says which ROM, core or Hypervisor version introduced a feature. Chapter 11 explains how a program can detect the version it is running on.

