# Command reference

Every Mirage command, with its exact options. The synopses below are what `--help` prints, so nothing is hidden — and every command and subcommand answers `-h`/`--help` on its own if you'd rather explore from the terminal.

Two conventions apply everywhere:

- `<device>` accepts a name, a unique part of a name (case-insensitive), a UDID, a UDID prefix of at least four characters, or the word `booted`. When several devices match, a booted one wins, then the newest runtime; a genuine tie is reported with the candidates listed rather than guessed.
- Destructive commands ask for confirmation when a terminal is attached, and take `-y`/`--yes` to skip the prompt (which is also how non-interactive environments opt in).

## Devices & lifecycle

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

## Cleanup & insight

| Synopsis | Description |
|---|---|
| `mirage cleanup [--stale-runtimes] [--runtime <runtime> ...] [--images-not-used-since <days>] [--dry-run] [--yes]` | Tiered roster slimming: unavailable devices and duplicates always; `--stale-runtimes` adds shutdown devices on non-latest runtimes; `--runtime 18.4` (repeatable) removes everything on that version; `--images-not-used-since N` prunes runtime disk images. Reports the plan with reclaimable sizes before confirming. Booted, mid-operation, and paired devices are never touched. |
| `mirage disk-usage [--top <n>] [--json]` | Disk usage per runtime + biggest devices; read-only. |
| `mirage doctor` | Environment health checks with hygiene hints. |

## Apps

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

## Capture & media

| Synopsis | Description |
|---|---|
| `mirage screenshot <device> [-o <file>] [--type <fmt>] [--display <d>] [--mask <policy>]` | Screenshot; defaults to `<device>-<timestamp>.png`. Formats: png, tiff, bmp, gif, jpeg. |
| `mirage record <device> [-o <file>] [--codec <codec>] [--display <d>] [--mask <policy>] [--force]` | Record video until Ctrl-C; defaults to `.mov`. Codecs: hevc (default), h264. |
| `mirage media add <device> <paths> ...` | Add photos/videos/contacts to the library. |

## System state

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

## Watch pairs, runtimes, diagnostics

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
