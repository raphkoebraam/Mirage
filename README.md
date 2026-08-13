# mirage

> Codename `mirage` — a simulated image that behaves like the real thing.

A humane, scriptable CLI for managing Apple simulators. `mirage` wraps
`xcrun simctl` with **fuzzy device resolution**, **sensible defaults**,
**readable tables**, and **interactive prompts** — while staying fully
automatable (`--json`, `--yes`, non-TTY fallbacks).

```console
$ mirage boot "iphone 17 pro"        # names, not UDIDs
$ mirage create "CI Phone" --type "iphone 17 pro"   # newest runtime picked for you
$ mirage screenshot booted           # timestamped filename for free
$ mirage list --json | jq '.[].udid' # scripting-friendly everywhere
```

## Why

`simctl` is powerful but hostile in daily use: it wants UDIDs, its ~40
subcommands are inconsistently named (`get_app_container`, `pbcopy`,
`status_bar`), its output is a wall of text, and creating a device requires
exact identifiers like `com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro`.

`mirage` fixes each of those. Every `<device>` argument accepts:

- an exact **UDID** (case-insensitive) — the only way to address unavailable devices
- a **UDID prefix** (≥ 4 characters)
- an exact or unique-substring **name** (case-insensitive)
- the magic word **`booted`**

When several devices match, a booted one wins, then the newest runtime;
remaining ties are reported as ambiguous with the candidates listed —
`mirage` never guesses.

## Installation

```bash
git clone <repo-url> && cd sim-cli
mise install          # tuist, swiftformat, swiftlint (pinned)
mise run generate     # tuist install + tuist generate
mise run build        # Release build → ./bin/mirage
./bin/mirage --version
# copy bin/mirage onto your PATH
```

Build products stay inside the repo: DerivedData goes to `build/` (via
`-derivedDataPath`) and the release binary is copied to `bin/mirage` —
both git-ignored.

Requirements: macOS 15+, Xcode 26+.

## Command reference

### Devices

| Command | Description |
|---|---|
| `mirage list [devices]` | Table of available devices. `--all` includes unavailable, `--name <s>` filters, `--json` for scripts. |
| `mirage list runtimes` | Installed runtimes (`--json` supported). |
| `mirage list devicetypes` | Device types; `--family iPhone` filters. |
| `mirage list pairs` | Watch–phone pairs. |
| `mirage booted` | Only booted devices. |
| `mirage create <name> [--type <t>] [--runtime <r>]` | Fuzzy type ("iphone 17 pro") and runtime ("26.0"); newest compatible runtime by default; prompts for the type when interactive. Prints the new UDID. |
| `mirage clone <device> <new-name>` | Clone a device; prints the new UDID. |
| `mirage rename <device> <new-name>` | Rename. |
| `mirage boot <device> [--wait] [--open]` | Boot; `--wait` blocks until booted, `--open` launches Simulator.app. |
| `mirage shutdown <device> \| --all` | Shutdown one or all. |
| `mirage erase <device...> \| --all` | Factory reset. Asks for confirmation; `--yes` skips. |
| `mirage delete <device...> \| --unavailable \| --all` | Delete devices. Asks for confirmation; `--yes` skips. |
| `mirage upgrade <device> <runtime>` | Move a device to a newer runtime. |

### Apps

| Command | Description |
|---|---|
| `mirage app install <device> <path>` | Install an .app bundle. |
| `mirage app uninstall <device> <bundle-id>` | Uninstall. |
| `mirage app launch <device> <bundle-id> [--console] [--wait-for-debugger] [--terminate-running] [-- args...]` | Launch; prints the PID. `--console` streams output. |
| `mirage app terminate <device> <bundle-id>` | Terminate. |
| `mirage app list <device>` | Installed apps. |
| `mirage app info <device> <bundle-id>` | App details. |
| `mirage app container <device> <bundle-id> [kind]` | Container path (`app`, `data`, `groups`, or a group id). |
| `mirage app install-data <device> <path>` | Install an .xcappdata package. |

### Capture & media

| Command | Description |
|---|---|
| `mirage screenshot <device> [-o file] [--type t] [--display d] [--mask m]` | Screenshot; defaults to `<device>-<timestamp>.png`. |
| `mirage record <device> [-o file] [--codec c] [--force]` | Record video; Ctrl-C stops and finalizes. Defaults to `.mov`. |
| `mirage media add <device> <file...>` | Add photos/videos/contacts to the library. |

### System state

| Command | Description |
|---|---|
| `mirage open <device> <url>` | Open URLs and deep links. |
| `mirage push <device> [bundle-id] [payload.json]` | Simulated push; payload from stdin when omitted. |
| `mirage privacy grant\|revoke\|reset <device> <service> [bundle-id]` | Permission control (photos, location, …, or `all`). |
| `mirage statusbar override <device> --time 9:41 --battery-level 100 ...` | Status bar overrides; `clear` and `list` too. |
| `mirage ui appearance <device> [light\|dark]` | Get/set appearance; also `content-size`, `increase-contrast`. |
| `mirage location set <device> <lat,lon>` | Fixed location; `clear`, `run <scenario>`, `list`. |
| `mirage keychain add-root-cert\|add-cert\|reset <device> [path]` | Keychain manipulation. |
| `mirage pasteboard copy\|paste\|sync` (alias `pb`) | Clipboard; `sync host booted` copies Mac → simulator. |
| `mirage getenv <device> <var>` | Device environment variables. |
| `mirage icloud-sync <device>` | Trigger iCloud sync. |
| `mirage logverbose <device> on\|off` | Verbose logging. |

### Watch pairing, runtimes, diagnostics

| Command | Description |
|---|---|
| `mirage pair <watch> <phone>` | Pair simulators (fuzzy names work); prints the pair id. |
| `mirage unpair <pair-id>` / `mirage pair-activate <pair-id>` | Manage pairs. |
| `mirage runtime list` / `mirage runtime delete <id\|all>` | Runtime disk images. |
| `mirage diagnose [--output dir] [--all-logs] [--device d...]` | Collect diagnostics. |
| `mirage spawn <device> <executable> [-- args...]` | Run an executable on a device. |

## Automation notes

- **Exit codes**: `0` success; simctl failures propagate their exit code; usage errors exit `64`.
- **Destructive commands** (`erase`, `delete`, `keychain reset`, `runtime delete`) prompt when a TTY is present and **refuse to run without `--yes` otherwise** — CI jobs must opt in explicitly.
- **`--json`** on listing commands emits stable, pretty-printed JSON.
- Data outputs (UDIDs, paths, pasteboard contents) go to plain stdout; decorated alerts go through Noora and stay out of your pipes' way.

## Development

```bash
mise install          # tuist, swiftformat, swiftlint (pinned)
mise run generate     # tuist install + tuist generate --no-open
mise run test         # both suites, DerivedData in ./build
mise run lint         # swiftformat --lint + swiftlint
mise run format       # apply swiftformat
```

Regenerate (`mise run generate`) only when `Project.swift`,
`Tuist/Package.swift`, or the dependency graph changes; iterate with
`mise run test` or plain `xcodebuild` otherwise. To scope a run to one suite:

```bash
xcodebuild test -workspace Mirage.xcworkspace -scheme MirageCLITests \
  -destination platform=macOS -derivedDataPath build \
  -only-testing 'MirageCLITests/AppCommandTests'
```

The whole suite (162 tests) runs in well under a second and **never touches a
real simulator**: tests inject a mock command runner and assert the exact
`simctl` argv produced. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Documentation

- [Architecture & testing strategy](docs/ARCHITECTURE.md)
- [Scope & analysis](docs/SCOPE.md)
- [ADR 0001 — Adopt Noora](docs/adr/0001-adopt-noora.md)
