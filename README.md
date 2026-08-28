# urls

**Get every tab you have open, out of every browser, in one command.**

Forty tabs across Safari, a Chrome window, and a Firefox you forgot about. You want that list
somewhere useful — a note, a message, a doc. Right now your options are clicking through every
window or installing four different extensions.

`urls` just gives you the list.

```
$ urls
Safari — 2026-08-28 14:32
---
https://news.ycombinator.com/item?id=41200000
https://developer.mozilla.org/en-US/docs/Web/CSS/grid

Chrome — 2026-08-28 14:32
---
http://localhost:3000/dashboard
https://github.com/charmbracelet/vhs
```

One URL per line, like `ls -1`. No JSON, no bullets to strip out, nothing to clean up. And
because the browser name sits above a line of dashes, the exact same text renders as proper
headings when you paste it into anything that understands Markdown.

**Works with:** Safari · Brave · Chrome · Edge · Vivaldi · Firefox · Waterfox · Zen

## Contents

- [Install](#install) — five steps, with what you should see after each one
- [If it didn't work](#if-it-didnt-work) — the three things that actually go wrong
- [Using it](#using-it) — the commands you'll type every day
- [Keyboard shortcuts](#keyboard-shortcuts) — grab your tabs without typing anything
- [Every option](#every-option) — the full flag list
- [How it works](#how-it-works) — the interesting part, if you like this sort of thing
- [Troubleshooting](#troubleshooting) · [Uninstall](#uninstall) · [License](#license)

---

## Install

### Step 1 — Download it

```sh
git clone https://github.com/tasmall17/urls.git
```

Put it wherever you keep projects. It doesn't care where it lives, and you can move or delete
the folder later without breaking anything — the installer copies the command out of it.

```sh
cd urls
```

### Step 2 — Run the installer

```sh
./install.sh
```

**That `./` at the front matters.** Without it, your shell searches your `PATH` for something
called `install.sh`, doesn't find it, and tells you `command not found`. The `./` says "the
one right here in this folder."

You should see something like this:

```
urls — installing
  ✓ python3 found (Python 3.9.6)
  ✓ installed /Users/you/.local/bin/urls
  ✓ updated /Users/you/.zshrc (zsh)
  ✓ bound ctrl-x u (clipboard) and ctrl-x m (markdown file)
```

### Step 3 — Click OK on the permission boxes

macOS will pop up a dialog that says something like **"Terminal wants to control Safari."**
You'll get one per browser. **Click OK on every single one.**

This looks alarming and isn't. macOS requires your permission before any terminal program can
talk to a browser, and reading your open tabs is exactly the kind of thing it wants you to
approve on purpose. The installer deliberately triggers all of these prompts now, while you're
sitting there paying attention, so they don't ambush you later.

Nothing can click these for you — Apple stores the answers in a database that's protected at
the OS level, and no script is allowed to write to it. That's the point of it.

When they're all approved you'll see:

```
Browser access
  ✓ Safari authorized
  ✓ Brave authorized
  ✓ Chrome authorized
  ✓ can write exports to /Users/you/Downloads
```

### Step 4 — Restart your shell

```sh
exec zsh
```

Using bash? Run `exec bash` instead.

**This is the step people skip, and it's why "it didn't work" for most of them.** The installer
added a line to your shell's config file, but the terminal you're sitting in right now started
*before* that line existed. It has no idea the new command is there. `exec zsh` restarts your
shell so it reads the config again. Opening a brand new terminal tab does the same thing.

### Step 5 — Try it

```sh
urls
```

You should see your open tabs, grouped by browser. That's it — you're done. The command now
works from any folder, in any terminal window, forever.

---

## If it didn't work

Three things go wrong. It's almost always the first one.

**`zsh: command not found: urls`**
You skipped Step 4, or you ran the installer in one window and are typing in another older one.
Run `exec zsh` (or `exec bash`), or just open a new terminal tab, and try again.

**`permission denied: ./install.sh`**
The executable bit got stripped, usually by downloading the ZIP from GitHub instead of using
`git clone`. Fix it and re-run:

```sh
chmod +x install.sh uninstall.sh bin/urls
./install.sh
```

**`urls: no open tabs found`**
This one is usually correct rather than broken. It means no browser is running, or every tab
you have open is a blank new-tab page — `urls` filters those out on purpose so you don't get a
list of `favorites://` five times. Open a real page in a browser and run it again.

If Safari and Chrome come back empty but Firefox works, you clicked "Don't Allow" on a
permission box. Jump to [Troubleshooting](#troubleshooting).

---

## Using it

The four commands worth remembering:

```sh
urls          # every open tab, printed to the terminal
urls -c       # every open tab, copied to your clipboard
urls -md      # every open tab, saved to ~/Downloads/open-urls-<date>.md
urls -s       # just Safari
```

Add a browser letter to narrow it down, and the letters combine with the output ones:

```sh
urls -cb      # Brave's tabs -> clipboard
urls -smd     # Safari's tabs -> Markdown file
urls -cmd     # everything -> clipboard AND a file
```

Flags stack in any order and `md` always reads as one piece, so `-smd` means "Safari, as
Markdown" rather than three separate letters. If you'd rather be explicit, the long names work
too: `urls --safari --clip`.

**Browser letters:** `-s` Safari · `-b` Brave · `-g` Chrome (Google) · `-e` Edge ·
`-v` Vivaldi · `-f` Firefox · `-w` Waterfox · `-z` Zen

Name no browser and you get every one that's currently running. Browsers you don't have
installed are skipped silently, so the same command works on any Mac.

---

## Keyboard shortcuts

The installer sets up two chords that work anywhere in your terminal:

| Press | And you get |
|---|---|
| <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>u</kbd> | every open tab on your clipboard |
| <kbd>ctrl</kbd>+<kbd>x</kbd> then <kbd>m</kbd> | every open tab in a Markdown file |

Hold <kbd>ctrl</kbd> and tap <kbd>x</kbd>, let go, then tap the letter. Whatever you were
halfway through typing stays exactly where it was.

Don't want them? `./install.sh --no-keys`.

**Want a shortcut that works when the terminal isn't even open?** Make one in Shortcuts.app:
New Shortcut → add a **Run Shell Script** action → put `~/.local/bin/urls -c` in it → assign a
key combination in the shortcut's info panel. Now any app, any time, one keypress.

### zsh, bash, or both

Both shells are fully supported, key bindings included. The installer figures out which one you
use and sets that one up. To override it:

```sh
./install.sh --shell bash     # or: zsh, both
```

`urls` itself is an ordinary bash script with no zsh dependency, and it runs on the bash 3.2
that Apple still ships, so there's nothing extra to install.

For the curious, here's where the config goes. bash needs two files because a login shell (what
Terminal opens) reads one set of files and a `bash` you start by hand reads a different one —
put the config in only one and it mysteriously works half the time.

| Shell | Files it touches |
|---|---|
| zsh | `~/.zshrc` |
| bash | `~/.bashrc` **and** the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile` that already exists |

It will never create a `~/.bash_profile` if you already have a `~/.profile`, because doing that
would quietly stop bash from ever reading your `.profile` again.

---

## Every option

**The command**

| Flag | What it does |
|---|---|
| *(none)* | print every running browser's tabs |
| `-c` | copy to clipboard |
| `-md` | write to `~/Downloads/open-urls-<date>-<time>.md` |
| `-s -b -g -e -v -f -w -z` | Safari, Brave, Chrome, Edge, Vivaldi, Firefox, Waterfox, Zen |
| `-l` | format as a bullet list (`- https://…`) |
| `--browsers` | show which browsers it knows about |
| `--version` | print the version |
| `-h` | help |

**The installer**

| Flag | What it does |
|---|---|
| `--prefix DIR` | install the command somewhere other than `~/.local/bin` |
| `--shell zsh\|bash\|both` | set up a shell other than the one you log in with |
| `--no-keys` | skip the keyboard shortcuts |
| `--no-grant` | skip the permission prompts |
| `--yes` | don't ask before opening a closed browser to authorize it |

**Settings**

| Variable | What it changes |
|---|---|
| `URLS_OUTDIR` | where `-md` saves files (default `~/Downloads`) |
| `URLS_FOOTER=0` | leave the cheat sheet off the bottom of Markdown files |
| `URLS_BIN_DIR` | where the installer puts the command |

---

## How it works

Browsers don't agree on anything, so there are two completely different mechanisms under the
hood.

**Safari, Brave, Chrome, Edge and Vivaldi** are read live through AppleScript, which is macOS's
built-in way for programs to ask each other questions. `urls` checks whether each browser is
already running before it asks, so it will never launch a browser you had deliberately closed.

**Firefox, Waterfox and Zen** don't offer that. There is simply no way to ask them what tabs
are open. What they do have is a session file on disk — the one that restores your tabs after a
crash — so `urls` reads that instead and pulls out the current page of every live tab.

That file isn't plain text. It's compressed in a Mozilla-specific format called mozLz4, and the
Python library that reads it isn't included with macOS. Requiring a `pip install` to run a
clone-and-go tool seemed like a bad trade, so `urls` carries its own small LZ4 decoder written
in plain Python. It handles a 1.5 MB session file in well under a second.

**One honest caveat:** Firefox-family browsers only save that file every 15 seconds or so, so a
tab you opened moments ago might not show up yet. Give it a moment and run it again. The
AppleScript browsers are always current.

New-tab and start pages (`favorites://`, `about:newtab`, `chrome://newtab` and friends) get
filtered out, so a window full of empty tabs reports nothing instead of a screen of noise.

### What it needs

- macOS. It uses AppleScript and `pbcopy`, so it's not portable to Linux.
- zsh or bash, including Apple's stock bash 3.2. No upgrade needed.
- `python3`, but only for Firefox, Waterfox and Zen. If you don't have it, everything else
  still works and the installer says so. `xcode-select --install` adds it.

---

## Troubleshooting

**Safari, Chrome or Brave return nothing, but Firefox works.**
You denied the Automation permission for that browser. Open System Settings → Privacy &
Security → Automation and switch your terminal back on for it. If the browser isn't listed at
all, reset the prompts with `tccutil reset AppleEvents` and run `./install.sh` again to be
asked fresh.

**`-md` doesn't write anything.**
`~/Downloads` is permission-protected too. Allow your terminal under System Settings → Privacy
& Security → Files and Folders, or send the file somewhere else with
`URLS_OUTDIR=~/Desktop urls -md`.

**A Firefox tab I just opened is missing.**
Wait about 15 seconds and try again. See the caveat in [How it works](#how-it-works).

**The prompts came back in a different terminal app.**
Expected. macOS grants Automation access per application, so approving it for Terminal doesn't
approve it for iTerm or VS Code. Approve it once more there and it sticks.

**The keyboard shortcuts don't do anything.**
Restart your shell with `exec zsh` (or `exec bash`). If they work in one bash window but not
another, you installed an older version — re-run `./install.sh` and it will fix both files.

---

## Updating

From inside the folder you cloned:

```sh
git pull
./install.sh
```

Re-running the installer is always safe. It replaces its own config block instead of piling up
duplicates, no matter how many times you run it.

## Uninstall

```sh
./uninstall.sh
```

Removes the command and cleans its block out of your shell config. Markdown files you already
exported are left alone. If you installed with `--prefix`, use
`URLS_BIN_DIR=DIR ./uninstall.sh`.

## License

MIT. Do whatever you like with it.
