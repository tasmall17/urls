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

## Install

```sh
git clone https://github.com/tasmall17/urls.git
cd urls
./install.sh
exec zsh
```

That installs the command to `~/.local/bin`, puts it on your `PATH`, and adds two terminal
key bindings. Re-running the installer is always safe — it replaces its own block rather
than stacking up duplicates.

The **first time** you point it at Safari or a Chromium browser, macOS asks
*"Terminal wants to control Safari"*. Click OK. It asks once per browser, then never again.

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

**Safari/Chrome/Brave return nothing while Firefox works** — Automation permission was denied.
Re-enable it in System Settings → Privacy & Security → Automation, or reset the prompt with
`tccutil reset AppleEvents` and run `urls` again.

**A Firefox-family browser is missing a tab you just opened** — wait ~15 seconds for the
session store to flush. This is a limitation of reading the session file, not a bug.

**`urls: command not found` after installing** — run `exec zsh`, or open a new terminal tab.

## Uninstall

```sh
./uninstall.sh
```

Removes the command and its shell block. Files you already exported are left alone.

## License

MIT
