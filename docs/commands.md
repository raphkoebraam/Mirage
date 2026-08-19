# Command reference

Every Mirage command, generated from the binary's own `--help` output so nothing here can drift from reality. Two conventions apply throughout:

- `<device>` accepts a name, a unique part of a name (case-insensitive), a UDID, a UDID prefix of at least four characters, or the word `booted`. When several devices match, a booted one wins, then the newest runtime; a genuine tie is reported with the candidates listed rather than guessed.
- Destructive commands ask for confirmation when a terminal is attached, and take `-y`/`--yes` to skip the prompt (which is also how non-interactive environments opt in).

**Devices & lifecycle:**
[list devices](#list-devices) ·
[list runtimes](#list-runtimes) ·
[list devicetypes](#list-devicetypes) ·
[list pairs](#list-pairs) ·
[booted](#booted) ·
[create](#create) ·
[clone](#clone) ·
[rename](#rename) ·
[boot](#boot) ·
[shutdown](#shutdown) ·
[erase](#erase) ·
[delete](#delete) ·
[upgrade](#upgrade)

**Cleanup & insight:**
[cleanup](#cleanup) ·
[disk-usage](#disk-usage) ·
[doctor](#doctor)

**Apps:**
[app install](#app-install) ·
[app uninstall](#app-uninstall) ·
[app launch](#app-launch) ·
[app terminate](#app-terminate) ·
[app list](#app-list) ·
[app info](#app-info) ·
[app container](#app-container) ·
[app install-data](#app-install-data)

**Capture & media:**
[screenshot](#screenshot) ·
[record](#record) ·
[media add](#media-add)

**System state:**
[open](#open) ·
[push](#push) ·
[privacy grant](#privacy-grant) ·
[privacy revoke](#privacy-revoke) ·
[privacy reset](#privacy-reset) ·
[statusbar override](#statusbar-override) ·
[statusbar demo](#statusbar-demo) ·
[statusbar clear](#statusbar-clear) ·
[statusbar list](#statusbar-list) ·
[ui appearance](#ui-appearance) ·
[ui content-size](#ui-content-size) ·
[ui increase-contrast](#ui-increase-contrast) ·
[location set](#location-set) ·
[location clear](#location-clear) ·
[location run](#location-run) ·
[location list](#location-list) ·
[keychain add-root-cert](#keychain-add-root-cert) ·
[keychain add-cert](#keychain-add-cert) ·
[keychain reset](#keychain-reset) ·
[pasteboard copy](#pasteboard-copy) ·
[pasteboard paste](#pasteboard-paste) ·
[pasteboard sync](#pasteboard-sync) ·
[getenv](#getenv) ·
[icloud-sync](#icloud-sync) ·
[logverbose](#logverbose) ·
[logs](#logs)

**Watch pairs, runtimes, diagnostics:**
[pair](#pair) ·
[unpair](#unpair) ·
[pair-activate](#pair-activate) ·
[runtime list](#runtime-list) ·
[runtime available](#runtime-available) ·
[runtime install](#runtime-install) ·
[runtime uninstall](#runtime-uninstall) ·
[diagnose](#diagnose) ·
[spawn](#spawn) ·
[completions](#completions)

---

# Devices & lifecycle

## list devices

List simulator devices (the default).

```
mirage list devices [--json] [--all] [--name <name>]
```

Argument | Description
--- | ---
`--json` | Emit JSON instead of a table.
`--all` | Include unavailable devices.
`--name <name>` | Only devices whose name contains this text.

```console
$ mirage list --name "iphone 17"
$ mirage list --json | jq '.[].udid'
```

## list runtimes

List installed simulator runtimes.

```
mirage list runtimes [--json]
```

Argument | Description
--- | ---
`--json` | Emit JSON instead of a table.

## list devicetypes

List available device types.

```
mirage list devicetypes [--json] [--family <family>]
```

Argument | Description
--- | ---
`--json` | Emit JSON instead of a table.
`--family <family>` | Only device types in this product family (iPhone, iPad, Apple Watch, Apple TV, Apple Vision).

## list pairs

List watch–phone pairs.

```
mirage list pairs
```

## booted

List currently booted simulators.

```
mirage booted [--json]
```

Argument | Description
--- | ---
`--json` | Emit JSON instead of a table.

```console
$ mirage booted
```

## create

Create a new simulator. Device type and runtime accept fuzzy names ('iphone 17 pro', '26.0'). Without --runtime the newest runtime for the device type is used; without --name the device type's name is used.

```
mirage create [--name <name>] [--type <type>] [--runtime <runtime>] [--boot] [--yes]
```

Argument | Description
--- | ---
`--name <name>` | Name for the new simulator. Defaults to the device type's name.
`--type <type>` | Device type (name, substring, or identifier).
`--runtime <runtime>` | Runtime (version, name, or identifier). Defaults to the newest compatible one.
`--boot` | Boot the device right after creating it.
`-y, --yes` | Assume yes for prompts, e.g. accepting the closest runtime match.

```console
$ mirage create --type "iphone 17 pro" --boot              # named "iPhone 17 Pro"
$ mirage create --name "Old Phone" --type "iphone 16" --runtime 18.5
```

## clone

Clone a simulator.

```
mirage clone [<device>] --name <name>
```

Argument | Description
--- | ---
`<device>` | Source device (name, UDID, or prefix); defaults to the booted simulator.
`--name <name>` | Name for the clone.

```console
$ mirage clone "CI Phone" --name "CI Phone Copy"
```

## rename

Rename a simulator.

```
mirage rename [<device>] --name <name>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--name <name>` | The new name.

```console
$ mirage rename "CI Phone" --name "Test Phone"
```

## boot

Boot a simulator.

```
mirage boot <device> [--wait] [--open]
```

Argument | Description
--- | ---
`<device>` | Device name, UDID, UDID prefix, or 'booted'.
`--wait` | Block until the device finishes booting.
`--open` | Open the Simulator app afterwards.

```console
$ mirage boot "iphone 17 pro" --open
```

## shutdown

Shutdown simulators.

```
mirage shutdown [<device>] [--all]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--all` | Shutdown every booted simulator.

```console
$ mirage shutdown --all
```

## erase

Erase simulators' content and settings (factory reset).

```
mirage erase [<devices> ...] [--all] [--yes]
```

Argument | Description
--- | ---
`<devices>` | Devices to erase (name, UDID, prefix, or 'booted').
`--all` | Erase every simulator.
`-y, --yes` | Skip the confirmation prompt.

```console
$ mirage erase "CI Phone" --yes
```

## delete

Delete simulators.

```
mirage delete [<devices> ...] [--unavailable] [--all] [--yes]
```

Argument | Description
--- | ---
`<devices>` | Devices to delete (name, UDID, prefix, or 'booted').
`--unavailable` | Delete simulators whose runtime is missing.
`--all` | Delete every simulator.
`-y, --yes` | Skip the confirmation prompt.

```console
$ mirage delete --unavailable --yes
```

## upgrade

Upgrade a simulator to a newer runtime.

```
mirage upgrade [<device>] --runtime <runtime> [--yes]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--runtime <runtime>` | Target runtime (version, name, or identifier).
`-y, --yes` | Assume yes for prompts, e.g. accepting the closest runtime match.

```console
$ mirage upgrade "Old Phone" --runtime 26.0
```

# Cleanup & insight

## cleanup

Slim down the simulator roster. Removes unavailable devices (their runtime is gone) and duplicates (same name, type, and runtime; a booted copy is kept, else the most recently used one, else the one with the most data). Booted devices and watch-pair members are never touched. The plan is shown before anything is deleted.

```
mirage cleanup [--stale-runtimes] [--runtime <runtime> ...] [--images-not-used-since <days>] [--dry-run] [--yes]
```

Argument | Description
--- | ---
`--stale-runtimes` | Also remove shutdown devices on non-latest runtimes.
`--runtime <runtime>` | Remove all shutdown devices on this runtime (version, name, or identifier). Repeatable.
`--images-not-used-since` | <days> Also delete runtime disk images unused for this many days.
`--dry-run` | Report what would be removed without deleting anything.
`-y, --yes` | Skip the confirmation prompt.

```console
$ mirage cleanup --dry-run
$ mirage cleanup --stale-runtimes --images-not-used-since 30
```

## disk-usage

Show simulator disk usage per runtime and per device. Read-only companion to `mirage cleanup`: see where the space goes before deleting.

```
mirage disk-usage [--top <top>] [--json]
```

Argument | Description
--- | ---
`--top <top>` | How many devices to list in the biggest-devices table. (default: 10)
`--json` | Emit JSON instead of tables.

```console
$ mirage disk-usage --top 5
```

## doctor

Check that the simulator environment is healthy.

```
mirage doctor
```

```console
$ mirage doctor
```

# Apps

## app install

Install an app bundle.

```
mirage app install [<device>] --path <path>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--path <path>` | Path to the .app bundle.

```console
$ mirage app install --path ./build/My.app
```

## app uninstall

Uninstall an app.

```
mirage app uninstall [<device>] --bundle-id <bundle-id>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--bundle-id <bundle-id>` | The app's bundle identifier.
## app launch

Launch an app. Pass app arguments after '--', e.g. `mirage app launch --bundle-id com.example -- -AppleLocale en_US`.

```
mirage app launch [<device>] --bundle-id <bundle-id> [--console] [--wait-for-debugger] [--terminate-running] -- [<app-arguments> ...]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`<app-arguments>` | Arguments passed to the app.
`--bundle-id <bundle-id>` | The app's bundle identifier.
`--console` | Stream the app's console output (Ctrl-C to stop).
`--wait-for-debugger` | Wait for a debugger to attach before running.
`--terminate-running` | Terminate an already-running instance first.

```console
$ mirage app launch --bundle-id com.example.app --console
```

## app terminate

Terminate a running app.

```
mirage app terminate [<device>] --bundle-id <bundle-id>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--bundle-id <bundle-id>` | The app's bundle identifier.
## app list

List installed apps.

```
mirage app list [<device>] [--json] [--raw]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--json` | Emit JSON instead of a table.
`--raw` | Pass simctl's raw plist output through unchanged.

```console
$ mirage app list booted
```

## app info

Show information about an installed app.

```
mirage app info [<device>] --bundle-id <bundle-id>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--bundle-id <bundle-id>` | The app's bundle identifier.
## app container

Print an app container path. Container kinds: app, data, groups, or an app group identifier.

```
mirage app container [<device>] --bundle-id <bundle-id> [--container <container>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--bundle-id <bundle-id>` | The app's bundle identifier.
`--container <container>` | Container kind (app, data, groups, or a group id).

```console
$ open $(mirage app container booted com.example.app data)
```

## app install-data

Install an .xcappdata package, replacing the app's data container.

```
mirage app install-data [<device>] --path <path>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--path <path>` | Path to the .xcappdata package.
# Capture & media

## screenshot

Save a screenshot of a simulator.

```
mirage screenshot [<device>] [--output <output>] [--type <type>] [--display <display>] [--mask <mask>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`-o, --output <output>` | Output file. Defaults to <device>-<timestamp>.png in the current directory.
`--type <type>` | Image format: png, tiff, bmp, gif, jpeg.
`--display <display>` | Display to capture (see `simctl io enumerate`).
`--mask <mask>` | Mask policy for non-rectangular displays: ignored, alpha, black.

```console
$ mirage screenshot booted
$ mirage screenshot booted -o shot.jpeg --type jpeg
```

## record

Record a video of a simulator (Ctrl-C to stop and finalize).

```
mirage record [<device>] [--output <output>] [--codec <codec>] [--display <display>] [--mask <mask>] [--force]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`-o, --output <output>` | Output file. Defaults to <device>-<timestamp>.mov in the current directory.
`--codec <codec>` | Codec: h264 or hevc (default).
`--display <display>` | Display to record (see `simctl io enumerate`).
`--mask <mask>` | Mask policy for non-rectangular displays: ignored, alpha, black.
`--force` | Overwrite the output file if it exists.

```console
$ mirage record booted -o demo.mov   # Ctrl-C stops and finalizes
```

## media add

Add photos, live photos, videos, or contacts.

```
mirage media add [<device>] [--path <path> ...]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--path <path>` | Files to add (repeatable, or several after one --path).

```console
$ mirage media add --path photo.png video.mov
```

# System state

## open

Open a URL on a simulator (https, deep links, etc.).

```
mirage open [<device>] --url <url>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--url <url>` | The URL to open.

```console
$ mirage open --url "myapp://deep/link"
```

## push

Send a simulated push notification. Without --payload, --message, or --json-payload the JSON payload is read from stdin. The payload may embed 'Simulator Target Bundle' instead of passing --bundle-id.

```
mirage push [<device>] [--bundle-id <bundle-id>] [--payload <payload>] [--message <message>] [--json-payload <json-payload>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--bundle-id <bundle-id>` | Target app's bundle identifier.
`--payload <payload>` | Path to the APNS JSON payload file.
`--message <message>` | Shortcut: send a plain alert with this text (no payload file needed).
`--json-payload <json-payload>` | Inline JSON payload string.

```console
$ mirage push --bundle-id com.example.app --message "Hello!"
$ mirage push --bundle-id com.example.app --payload payload.json
```

## privacy grant

Grant a privacy permission to an app. Services: all, calendar, contacts, contacts-limited, location, location-always, photos, photos-add, media-library, microphone, motion, reminders, siri.

```
mirage privacy grant [<device>] --service <service> --bundle-id <bundle-id>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--service <service>` | The privacy service to grant (see `mirage privacy --help`).
`--bundle-id <bundle-id>` | Target app's bundle identifier.

```console
$ mirage privacy grant --service photos --bundle-id com.example.app
```

## privacy revoke

Revoke a privacy permission from an app.

```
mirage privacy revoke [<device>] --service <service> --bundle-id <bundle-id>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--service <service>` | The privacy service to revoke (see `mirage privacy --help`).
`--bundle-id <bundle-id>` | Target app's bundle identifier.

## privacy reset

Reset a privacy permission, for one app or for all apps.

```
mirage privacy reset [<device>] --service <service> [--bundle-id <bundle-id>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--service <service>` | The privacy service to reset ('all' for every service).
`--bundle-id <bundle-id>` | Target app's bundle identifier; omit to reset every app.

```console
$ mirage privacy reset --service all
```

## statusbar override

Set status bar overrides (at least one flag required).

```
mirage statusbar override [<device>] [--time <time>] [--data-network <data-network>] [--wifi-mode <wifi-mode>] [--wifi-bars <wifi-bars>] [--cellular-mode <cellular-mode>] [--cellular-bars <cellular-bars>] [--operator-name <operator-name>] [--battery-state <battery-state>] [--battery-level <battery-level>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--time <time>` | Fixed time string (ISO dates also set the date).
`--data-network <data-network>` | hide, wifi, 3g, 4g, lte, lte-a, lte+, 5g, 5g+, 5g-uwb, 5g-uc.
`--wifi-mode <wifi-mode>` | searching, failed, or active.
`--wifi-bars <wifi-bars>` | 0-3.
`--cellular-mode <cellular-mode>` | notSupported, searching, failed, or active.
`--cellular-bars <cellular-bars>` | 0-4.
`--operator-name <operator-name>` | Carrier name.
`--battery-state <battery-state>` | charging, charged, or discharging.
`--battery-level <battery-level>` | 0-100.

```console
$ mirage statusbar override booted --time "9:41" --battery-level 100
```

## statusbar demo

Apply the classic App Store screenshot preset (9:41, full battery and signal).

```
mirage statusbar demo [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

```console
$ mirage statusbar demo booted
```

## statusbar clear

Clear all status bar overrides.

```
mirage statusbar clear [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## statusbar list

List current status bar overrides.

```
mirage statusbar list [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## ui appearance

Get or set light/dark appearance.

```
mirage ui appearance [<device>] [--set <set>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--set <set>` | New value: light or dark. Omit to print the current value.

```console
$ mirage ui appearance --set dark
$ mirage ui appearance              # prints the current value
```

## ui content-size

Get or set the preferred content size category.

```
mirage ui content-size [<device>] [--set <set>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--set <set>` | New value: a size category, increment, or decrement. Omit to print the current value.
## ui increase-contrast

Get or set Increase Contrast mode.

```
mirage ui increase-contrast [<device>] [--set <set>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--set <set>` | New value: enabled or disabled. Omit to print the current value.
## location set

Set a fixed location. Decimal degrees, e.g. --latitude 37.3349 --longitude -122.009.

```
mirage location set [<device>] --latitude <latitude> --longitude <longitude>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--latitude <latitude>` | Latitude in decimal degrees.
`--longitude <longitude>` | Longitude in decimal degrees.

```console
$ mirage location set --latitude 37.3349 --longitude -122.009
```

## location clear

Clear any simulated location.

```
mirage location clear [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## location run

Run a location scenario (see `mirage location list`).

```
mirage location run [<device>] --scenario <scenario>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--scenario <scenario>` | Scenario name.
## location list

List available location scenarios.

```
mirage location list [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## keychain add-root-cert

Add a certificate to the trusted root store.

```
mirage keychain add-root-cert [<device>] --path <path>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--path <path>` | Path to the certificate.
## keychain add-cert

Add a certificate to the keychain.

```
mirage keychain add-cert [<device>] --path <path>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--path <path>` | Path to the certificate.
## keychain reset

Reset the device's keychain.

```
mirage keychain reset [<device>] [--yes]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`-y, --yes` | Skip the confirmation prompt.
## pasteboard copy

Copy stdin onto the device pasteboard.

```
mirage pasteboard copy [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## pasteboard paste

Print the device pasteboard.

```
mirage pasteboard paste [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## pasteboard sync

Sync the pasteboard between devices (or 'host').

```
mirage pasteboard sync <source> <destination>
```

Argument | Description
--- | ---
`<source>` | Source: device query or 'host'.
`<destination>` | Destination: device query or 'host'.

```console
$ mirage pasteboard sync host booted   # Mac clipboard → simulator
```

## getenv

Print an environment variable from a device.

```
mirage getenv [<device>] --variable <variable>
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--variable <variable>` | Variable name (e.g. HOME).

```console
$ mirage getenv --variable HOME
```

## icloud-sync

Trigger an iCloud sync on a device.

```
mirage icloud-sync [<device>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.

## logverbose

Enable or disable verbose logging on a device.

```
mirage logverbose [<device>] --on --off
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--on` | Enable verbose logging.
`--off` | Disable verbose logging.

```console
$ mirage logverbose --on
```
## logs

Stream a device's unified log (Ctrl-C to stop). Wraps `log stream` on the device. Use --app for a quick process filter or --predicate for full NSPredicate syntax.

```
mirage logs [<device>] [--predicate <predicate>] [--app <app>] [--level <level>]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`--predicate <predicate>` | NSPredicate filter, e.g. 'subsystem == "com.example"'.
`--app <app>` | Shortcut: only logs from this process name.
`--level <level>` | Log level: default, info, or debug.

```console
$ mirage logs booted --app MyApp --level debug
```

# Watch pairs, runtimes, diagnostics

## pair

Pair a watch simulator with a phone simulator.

```
mirage pair <watch> <phone>
```

Argument | Description
--- | ---
`<watch>` | Watch device (name, UDID, prefix).
`<phone>` | Phone device (name, UDID, prefix).

```console
$ mirage pair "watch" "iphone 17 pro"
```

## unpair

Unpair a watch–phone pair.

```
mirage unpair <pair>
```

Argument | Description
--- | ---
`<pair>` | Pair UUID (see `mirage list pairs`).

## pair-activate

Set a pair as the active one.

```
mirage pair-activate <pair>
```

Argument | Description
--- | ---
`<pair>` | Pair UUID (see `mirage list pairs`).

## runtime list

List runtime disk images.

```
mirage runtime list
```

## runtime available

List simulator runtimes Apple offers for download. Reads the same catalog Xcode's Components pane uses and marks the builds already installed. Install one with `mirage runtime install`.

```
mirage runtime available [--platform <platform>] [--prerelease] [--json]
```

Option | Description
--- | ---
`--platform <platform>` | Only this platform: iOS, watchOS, tvOS, or visionOS.
`--prerelease` | Include betas and release candidates.
`--json` | Emit JSON instead of a table.

```console
$ mirage runtime available --platform iOS
```

## runtime install

Download and install a simulator runtime. Wraps `xcodebuild -downloadPlatform`. Downloads are large (5 to 10 GB) and stream progress. The version is checked against Apple's catalog first: `17` means 17.0, an already installed build is reported instead of re-downloaded, and an unknown version lists what is available.

```
mirage runtime install --platform <platform> [--version <version>]
```

Argument | Description
--- | ---
`--platform <platform>` | Platform: iOS, watchOS, tvOS, or visionOS.
`--version <version>` | Runtime version (e.g. 26.2). Latest when omitted.

```console
$ mirage runtime install --platform iOS --version 26.2
```

## runtime uninstall

Uninstall a runtime disk image ('all' removes every image). `runtime delete` remains an alias.

```
mirage runtime uninstall [<identifier>] [--version <version>] [--yes]
```

Argument | Description
--- | ---
`<identifier>` | Runtime version ('18' means 18.0), build, image identifier, or 'all'.
`--version <version>` | Runtime version to uninstall (same as passing it as the argument).
`-y, --yes` | Skip the confirmation prompt.

```console
$ mirage runtime uninstall 18
```

## diagnose

Collect simulator diagnostics and logs.

```
mirage diagnose [--output <output>] [--all-logs] [--device <device> ...]
```

Argument | Description
--- | ---
`--output <output>` | Output directory for the archive.
`--all-logs` | Include all logs, not just recent ones.
`--device <device>` | Restrict to specific devices (queries).

## spawn

Spawn an executable on a device. Pass executable arguments after '--', e.g. `mirage spawn --executable /bin/ls -- -la`.

```
mirage spawn [<device>] --executable <executable> -- [<executable-arguments> ...]
```

Argument | Description
--- | ---
`<device>` | Device (name, UDID, or prefix); defaults to the booted simulator.
`<executable-arguments>` | Arguments for the executable.
`--executable <executable>` | Path to the executable on the device.

```console
$ mirage spawn --executable /bin/ls -- -la /
```

## completions

Print a shell completion script for zsh, bash, or fish, ready to redirect into your shell's completions directory.

```
mirage completions <shell>
```

Argument | Description
--- | ---
`<shell>` | The shell: zsh, bash, or fish. (values: zsh, bash, fish)

```console
$ mirage completions zsh > ~/.zsh/completions/_mirage
$ mirage completions fish > ~/.config/fish/completions/mirage.fish
```
