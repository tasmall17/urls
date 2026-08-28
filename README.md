# urls

**Dump every open browser tab on your Mac to the clipboard or a Markdown file — from one terminal command.**

Safari, Brave, Chrome, Edge, Vivaldi, Firefox, Waterfox and Zen, all in a single sweep.
No extensions, no browser sign-in, no dependencies beyond what macOS already ships.

```
$ urls
Brave — 2026-08-28 13:29
---
https://www.clearancejobs.com/jobs?clearance=2&keywords=cybersecurity
http://localhost:8080/budgets

Waterfox — 2026-08-28 13:29
---
https://neovim.io/
https://www.reddit.com/r/zsh/comments/zvrqmi/how_do_i_move_filesdirectories_exclusively/
```

Plain one-per-line output, like `ls -1`. The browser name plus `---` is also a Markdown
setext heading, so the same text renders with real headings when you paste it into a doc.

## Contents

- [**Quick start**](#quick-start) — five commands, copy and paste
- [**Install**](#install) — clone, run `./install.sh`, done
  - [About the permission prompts](#about-the-permission-prompts) — what macOS asks, why, and what the installer does about it
  - [Installer options](#installer-options) — `--prefix`, `--no-keys`, `--no-grant`, `--yes`
- [**Usage**](#usage) — every flag, with examples
  - [Key bindings](#key-bindings) — <kbd>ctrl</kbd>+<kbd>x</kbd> <kbd>u</kbd> / <kbd>m</kbd>, and a system-wide hotkey
  - [Environment](#environment) — `URLS_OUTDIR`, `URLS_FOOTER`, `URLS_BIN_DIR`
- [**How it works**](#how-it-works) — AppleScript, session stores, and the mozLz4 decoder
- [Requirements](#requirements) · [Troubleshooting](#troubleshooting) · [Uninstall](#uninstall) · [License](#license)

## Quick start

Five commands. Copy and paste each one in order — every block has a copy button on its right.

**1. Clone the repo** (anywhere you like; `~/Dev` is a fine home)

```sh
git clone https://github.com/tasmall17/urls.git
```

**2. Go into it**

```sh
cd urls
```

**3. Run the installer**

```sh
./install.sh
```

macOS will pop up dialogs saying *"Terminal wants to control Safari"* — one per browser.
**Click OK on every one.** That is the entire setup; see
[About the permission prompts](#about-the-permission-prompts) for why.

**4. Reload your shell** so the new command is on your `PATH`

```sh
exec zsh
```

**5. Try it**

```sh
urls
```

You should see your open tabs, grouped by browser. If you do, you're done — and these now work
anywhere in your terminal:

```sh
urls -c      # every open tab -> clipboard
urls -md     # every open tab -> ~/Downloads/open-urls-<date>.md
urls -s      # just Safari
```

Plus two keyboard chords, no typing required: <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>u</kbd>
copies every tab, <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>m</kbd> writes the Markdown file.

**Updating later**, from inside the repo folder:

```sh
git pull && ./install.sh
```

## Install

The [quick start](#quick-start) above *is* the whole procedure. This section covers what those
commands actually do, and how to change it.

`./install.sh` installs the command to `~/.local/bin`, puts it on your `PATH`, adds two terminal key
bindings, and walks you through the macOS permission prompts. Re-running the installer is
always safe — it replaces its own block rather than stacking up duplicates.

> **First time on a new Mac?** Read [About the permission prompts](#about-the-permission-prompts)
> — it explains the dialogs the installer raises and why clicking OK is the whole setup.
> Prefer to change what gets installed? See [Installer options](#installer-options).

### About the permission prompts

macOS gates Apple Events behind TCC, so a terminal cannot read a browser's tabs until you
approve it. **No script can grant that for you** — the permission store is SIP-protected and
`tccutil` can only reset entries, never create them. What the installer does instead is
*trigger* every prompt up front, so you click OK a few times during install and never get
ambushed later:

```
Browser access
  ✓ Safari authorized
  ✓ Brave authorized
  ✓ Chrome authorized
  ✓ can write exports to /Users/you/Downloads
```

It only touches browsers you actually have installed. For one that isn't running it asks
before opening it, since authorizing requires the app to be up; answer `n` and that browser
simply prompts on first use instead. `--yes` approves those launches without asking,
`--no-grant` skips the whole step.

One honest caveat: the approval belongs to the **terminal app** you ran the installer from.
Launching `urls` from a different terminal — iTerm when you installed from Terminal, say —
produces one more round of prompts. That's macOS's model, not something `urls` can avoid.

### Installer options

| Flag | Effect |
|---|---|
| `--prefix DIR` | install the command somewhere other than `~/.local/bin` |
| `--no-keys` | skip the <kbd>ctrl</kbd>+<kbd>x</kbd> bindings |
| `--no-grant` | skip the permission step entirely |
| `--yes` | don't ask before opening a browser to authorize it |

## Usage

| Command | What it does |
|---|---|
| `urls` | every running browser → stdout |
| `urls -c` | → clipboard |
| `urls -md` | → `~/Downloads/open-urls-<date>-<time>.md` |
| `urls -s` | Safari only |
| `urls -smd` | Safari only → Markdown file |
| `urls -cb` | Brave only → clipboard |
| `urls -cmd` | everything → clipboard **and** a file |
| `urls -l` | bullet-list Markdown (`- <url>`) |
| `urls --browsers` | list the browsers it knows about |
| `urls -h` | help |

Flags bundle in any order, and `md` is parsed as a single token — so `-smd` reads as
"Safari + Markdown", not "s, m, d". Long forms work too: `urls --safari --clip`.

**Browsers:** `-s` Safari · `-b` Brave · `-g` Chrome · `-e` Edge · `-v` Vivaldi ·
`-f` Firefox · `-w` Waterfox · `-z` Zen. Name none and you get every one that is running.

**Output:** `-c` clipboard · `-md` file. Name neither and it prints to stdout. `-c` and `-md`
are destinations, not filters, so they compose freely with the browser letters.

### Key bindings

The installer binds two chords in your interactive shell:

| Chord | Action |
|---|---|
| <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>u</kbd> | all open tabs → clipboard |
| <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>m</kbd> | all open tabs → Markdown file |

They run without disturbing whatever you were typing. Skip them with `./install.sh --no-keys`.

For a hotkey that works when the terminal *isn't* focused, make a Shortcuts.app shortcut with
a **Run Shell Script** action calling `~/.local/bin/urls -c`, then assign it a key in the
shortcut's info panel.

### Environment

| Variable | Effect |
|---|---|
| `URLS_OUTDIR` | where `-md` writes (default `~/Downloads`) |
| `URLS_FOOTER=0` | omit the cheat sheet appended to Markdown files |
| `URLS_BIN_DIR` | install location, read by `install.sh`/`uninstall.sh` |

## How it works

Two very different mechanisms, because browsers don't agree on anything:

**Safari, Brave, Chrome, Edge, Vivaldi** are read **live** over AppleScript
(`URL of every tab of every window`). The script checks `application "X" is running` first,
so it never launches a browser you had closed.

**Firefox, Waterfox and Zen** expose no AppleScript tab API at all. Instead the script reads
the browser's own session store — the newest of `recovery.jsonlz4`, `previous.jsonlz4` or
`sessionstore.jsonlz4` under your profile — and pulls `entries[index-1].url` for each live
tab, ignoring closed tabs and closed windows.

Those files are **mozLz4**: an 8-byte `mozLz40\0` magic, a little-endian `uint32` of the
decompressed size, then a raw LZ4 block. The `lz4` Python module isn't part of macOS's stock
Python, and requiring a `pip install` for a "just clone and run" tool is a bad trade — so
`urls` carries a small pure-Python LZ4 block decoder instead. It bulk-copies non-overlapping
matches and only falls back to a byte loop for overlapping runs, which keeps a 1.5 MB session
file well under a second.

**One caveat:** Firefox-family browsers flush that session file every ~15 seconds, so their
results can trail the live window by a few seconds. The AppleScript browsers are always current.

Start pages (`favorites://`, `topsites://`, `about:newtab`, `chrome://newtab` and friends)
are filtered out, so a window full of empty new tabs reports nothing rather than noise.

## Requirements

- macOS (uses AppleScript and `pbcopy`)
- `python3` — only for the Firefox family. Stock macOS Python is fine; if it's missing,
  `xcode-select --install` provides it. Everything else still works without it.

## Troubleshooting

**"no open tabs found"** — the browser isn't running, or every tab is a blank new-tab page.

**Safari/Chrome/Brave return nothing while Firefox works** — Automation permission was denied
for that browser (see [About the permission prompts](#about-the-permission-prompts)). Re-enable it in System Settings → Privacy & Security → Automation, or reset
the prompts with `tccutil reset AppleEvents` and re-run `./install.sh` to be asked again.

**`-md` writes nothing** — `~/Downloads` is TCC-protected too, same story as
[the browser prompts](#about-the-permission-prompts). Allow your terminal under
System Settings → Privacy & Security → Files and Folders, or point `URLS_OUTDIR` elsewhere.

**A Firefox-family browser is missing a tab you just opened** — wait ~15 seconds for the
session store to flush. This is a limitation of reading the session file, not a bug.

**`urls: command not found` after installing** — run `exec zsh`, or open a new terminal tab.

**Prompts appear again in a different terminal app** — expected; approvals are per terminal.
[Why](#about-the-permission-prompts).

## Uninstall

```sh
./uninstall.sh
```

Removes the command and its shell block. Files you already exported are left alone.
It reads `URLS_BIN_DIR` the same way [the installer](#installer-options) does, so a
`--prefix` install uninstalls cleanly with `URLS_BIN_DIR=DIR ./uninstall.sh`.

## License

MIT
