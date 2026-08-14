# Mirage

> Codename **Mirage** — a simulated image that behaves like the real thing.

A humane, scriptable CLI for managing Apple simulators. Mirage wraps
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

Mirage fixes each of those. Every `<device>` argument accepts:

- an exact **UDID** (case-insensitive) — the only way to address unavailable devices
- a **UDID prefix** (≥ 4 characters)
- an exact or unique-substring **name** (case-insensitive)
- the magic word **`booted`**

When several devices match, a booted one wins, then the newest runtime;
remaining ties are reported as ambiguous with the candidates listed —
Mirage never guesses.

## Installation

```bash
git clone <repo-url> && cd Mirage
mise install          # tuist, swiftformat, swiftlint (pinned)
mise run generate     # tuist install + tuist generate
mise run build        # Release build → ./bin/mirage
./bin/mirage --version
```

Then put `mirage` on your `PATH`. A symlink is best when building from
source — every `mise run build` refreshes the installed command:

```bash
sudo ln -sf "$PWD/bin/mirage" /usr/local/bin/mirage
```

Prefer a stable copy instead (`sudo cp bin/mirage /usr/local/bin/`), or, to
avoid sudo, copy it into `~/.local/bin` and add that directory to `PATH` in
your shell profile. Verify with `which mirage && mirage --version`.

Build products stay inside the repo: DerivedData goes to `build/` (via
`-derivedDataPath`) and the release binary is copied to `bin/mirage` —
both git-ignored.

Requirements: macOS 15+, Xcode 26+.

## Command reference

Synopses below are exactly what `--help` prints — every option is shown.
Each command and subcommand answers `-h/--help`; destructive ones take
`-y/--yes` to skip confirmation. `<device>` always accepts a name, unique
substring, UDID, UDID prefix (≥ 4 chars), or `booted`.

### Devices & lifecycle

| Synopsis | Description |
|---|---|
| `mirage list devices [--json] [--all] [--name <text>]` | Device table (the default for bare `mirage list`). `--all` includes unavailable devices. |
| `mirage list runtimes [--json]` | Installed runtimes. |
| `mirage list devicetypes [--json] [--family <family>]` | Device types; families: iPhone, iPad, Apple Watch, Apple TV, Apple Vision. |
| `mirage list pairs` | Watch–phone pairs. |
| `mirage booted [--json]` | Only booted devices. |
| `mirage create <name> [--type <type>] [--runtime <runtime>] [--boot] [--yes]` | Fuzzy type ("iphone 17 pro") and runtime ("26.0"); newest compatible runtime by default; prompts for the type when interactive. A near-miss runtime ("18") offers the closest match — confirmed interactively, auto-accepted with `--yes`. Incompatible type/runtime pairs fail up front listing what works. Prints the new UDID. |
| `mirage clone <device> <new-name>` | Clone; prints the new UDID. |
| `mirage rename <device> <new-name>` | Rename. |
| `mirage boot <device> [--wait] [--open]` | Boot; `--wait` blocks until booted, `--open` launches Simulator.app. |
| `mirage shutdown [<device>] [--all]` | Shutdown one device or all. |
| `mirage erase [<devices> ...] [--all] [--yes]` | Factory reset (confirmed). |
| `mirage delete [<devices> ...] [--unavailable] [--all] [--yes]` | Delete devices, the unavailable ones, or everything (confirmed). |
| `mirage upgrade <device> <runtime> [--yes]` | Move a device to a newer runtime; near-miss versions offer the closest match, incompatible pairs fail with guidance. |

### Cleanup & insight

| Synopsis | Description |
|---|---|
| `mirage cleanup [--stale-runtimes] [--runtime <runtime> ...] [--images-not-used-since <days>] [--dry-run] [--yes]` | Tiered roster slimming: unavailable devices and duplicates always; `--stale-runtimes` adds shutdown devices on non-latest runtimes; `--runtime 18.4` (repeatable) removes everything on that version; `--images-not-used-since N` prunes runtime disk images. Reports the plan with reclaimable sizes before confirming. Booted, mid-operation, and paired devices are never touched. |
| `mirage disk-usage [--top <n>] [--json]` | Disk usage per runtime + biggest devices; read-only. |
| `mirage doctor` | Environment health checks with hygiene hints. |

### Apps

| Synopsis | Description |
|---|---|
| `mirage app install <device> <path>` | Install an .app bundle. |
| `mirage app uninstall <device> <bundle-id>` | Uninstall. |
| `mirage app launch <device> <bundle-id> [--console] [--wait-for-debugger] [--terminate-running] -- [<app-arguments> ...]` | Launch; prints the PID. `--console` streams output until Ctrl-C. |
| `mirage app terminate <device> <bundle-id>` | Terminate. |
| `mirage app list <device> [--json] [--raw]` | Installed apps as a table (user apps first), JSON, or simctl's raw plist. |
| `mirage app info <device> <bundle-id>` | App details. |
| `mirage app container <device> <bundle-id> [<container>]` | Container path: `app`, `data`, `groups`, or an app-group id. |
| `mirage app install-data <device> <path>` | Install an .xcappdata package. |

### Capture & media

| Synopsis | Description |
|---|---|
| `mirage screenshot <device> [-o <file>] [--type <fmt>] [--display <d>] [--mask <policy>]` | Screenshot; defaults to `<device>-<timestamp>.png`. Formats: png, tiff, bmp, gif, jpeg. |
| `mirage record <device> [-o <file>] [--codec <codec>] [--display <d>] [--mask <policy>] [--force]` | Record video until Ctrl-C; defaults to `.mov`. Codecs: hevc (default), h264. |
| `mirage media add <device> <paths> ...` | Add photos/videos/contacts to the library. |

### System state

| Synopsis | Description |
|---|---|
| `mirage open <device> <url>` | Open URLs and deep links. |
| `mirage push <device> [<bundle-id>] [<payload>] [--message <text>] [--json-payload <json>]` | Simulated push: a payload file, stdin (default), a plain `--message` alert, or inline `--json-payload`. |
| `mirage privacy <grant\|revoke\|reset> <device> <service> [<bundle-id>]` | Permission control. Services: all, calendar, contacts, contacts-limited, location, location-always, photos, photos-add, media-library, microphone, motion, reminders, siri. |
| `mirage statusbar override <device> [--time <t>] [--data-network <n>] [--wifi-mode <m>] [--wifi-bars <0-3>] [--cellular-mode <m>] [--cellular-bars <0-4>] [--operator-name <s>] [--battery-state <s>] [--battery-level <0-100>]` | Status bar overrides (at least one flag). |
| `mirage statusbar demo <device>` | The 9:41 App Store screenshot preset. |
| `mirage statusbar clear <device>` / `statusbar list <device>` | Clear or list overrides. |
| `mirage ui appearance <device> [light\|dark]` | Get/set appearance; also `ui content-size <device> [<size\|increment\|decrement>]` and `ui increase-contrast <device> [enabled\|disabled]`. |
| `mirage location set <device> <lat,lon>` | Fixed location; also `location clear\|run <scenario>\|list`. |
| `mirage keychain add-root-cert\|add-cert <device> <path>` | Trust certificates; `keychain reset <device> [--yes]` wipes the keychain. |
| `mirage pasteboard copy\|paste <device>` (alias `pb`) | Clipboard in/out; `pasteboard sync <source> <destination>` where either side is a device or `host`. |
| `mirage getenv <device> <variable>` | Device environment variables. |
| `mirage icloud-sync <device>` | Trigger iCloud sync. |
| `mirage logverbose <device> <on\|off>` | Verbose logging (takes effect after reboot). |
| `mirage logs <device> [--predicate <p>] [--app <name>] [--level <default\|info\|debug>]` | Stream the unified log until Ctrl-C. |

### Watch pairs, runtimes, diagnostics

| Synopsis | Description |
|---|---|
| `mirage pair <watch> <phone>` | Pair simulators (fuzzy names work); prints the pair id. |
| `mirage unpair <pair>` / `mirage pair-activate <pair>` | Manage pairs by UUID (see `mirage list pairs`). |
| `mirage runtime list` | Runtime disk images. |
| `mirage runtime install <platform> [<version>]` | Download a runtime (iOS, watchOS, tvOS, visionOS) via `xcodebuild -downloadPlatform`; latest when version omitted. |
| `mirage runtime delete <identifier\|all> [--yes]` | Delete runtime images (confirmed). |
| `mirage diagnose [--output <dir>] [--all-logs] [--device <d> ...]` | Collect diagnostics. |
| `mirage spawn <device> <executable> -- [<arguments> ...]` | Run an executable on a device; exit code passes through. |
| `mirage completions <zsh\|bash\|fish>` | Shell completion scripts (install instructions in `--help`). |

## Automation notes

- **`MIRAGE_DEVICE_SET=/path`** routes every simctl call through `--set`, isolating mirage in a custom CoreSimulator device set (ideal for CI farms).

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

## Contributing

Questions, bug reports, feature ideas, and pull requests are all very
welcome — and if you'd rather talk something through before writing code,
opening an issue is never the wrong first move. Not sure whether something
counts as a bug? Report it anyway.

A few notes that will help a change land smoothly:

- **The test suite is the project's favorite feature — help keep it that
  way.** Everything runs against a mock process runner that asserts the
  exact `simctl` arguments produced, so `mise run test` finishes in about a
  second and never touches your simulators. A test alongside your change is
  the best way to show what it does (and the codebase is full of examples to
  crib from).
- **Adding a simctl capability is easier than it looks** — there's a short
  three-step recipe in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#extending).
- **Formatting is automated**, so no style debates: `mise run format` before
  committing, and `mise run lint` to double-check (tool versions are pinned,
  nothing to configure). Option names are kebab-case; a small test will
  remind you if one slips.
- **Smaller commits are easier to review**, and prefixes like `feat:`,
  `fix:`, or `docs:` are appreciated — but a good change won't be turned
  away over commit cosmetics.
- If your change touches the plan, a one-line update to
  [docs/ROADMAP.md](docs/ROADMAP.md) keeps it honest.

Getting set up is four commands (see Development above): `mise install`,
`mise run generate`, `mise run build`, `mise run test`.

## License

MIT — see [LICENSE](LICENSE).

## Documentation

- [Architecture & testing strategy](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Releasing](docs/RELEASING.md)
- [Scope & analysis](docs/SCOPE.md)
- [ADR 0001 — Adopt Noora](docs/adr/0001-adopt-noora.md)
