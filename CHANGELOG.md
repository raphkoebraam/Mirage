# Changelog

All notable changes to Mirage are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Mirage follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `mirage doctor` referred to `mirage du`, a command that no longer exists; it now points at `mirage disk-usage`.

## [0.9.0] - 2026-08-16

First public release.

### Added

- **Device resolution by name.** Anywhere a command takes a `<device>`, Mirage accepts a full name, a unique fragment of one, a UDID, a UDID prefix, or `booted`. Ambiguous queries prefer the booted device, then the newest runtime, and otherwise list the candidates instead of guessing. Omitting the device entirely targets the booted simulator.
- **Full simctl surface**: device lifecycle (`create`, `boot`, `shutdown`, `erase`, `delete`, `rename`, `clone`, `upgrade`), `list` and `booted`, apps (`app install`, `app launch`, `app list`, `app container`, and friends), media and IO (`screenshot`, `record`, `media add`, `open`), `push`, `privacy`, `statusbar`, `ui`, `location`, `keychain`, `pasteboard`, watch pairing, `runtime` management, `spawn`, `diagnose`, and `logs`.
- **Forgiving runtime queries.** `--runtime 18` resolves to the closest runtime the device can actually run, with compatibility guidance instead of simctl's bare "Incompatible device" error.
- **`cleanup`**: reclaims disk by removing unavailable, stale, and duplicate devices, showing exactly what it will delete and how much space it frees before touching anything.
- **`disk-usage`**: per-runtime and per-device disk report.
- **`doctor`**: sanity checks for the simulator environment.
- **`completions`**: completion scripts for zsh, bash, and fish.
- **`--json`** on the listing commands, emitting stable, pretty-printed output.
- **`MIRAGE_DEVICE_SET`** / `--set`: routes every simctl call through an isolated CoreSimulator device set, so CI never touches personal simulators.
- **Confirmation guards.** Destructive commands prompt when a terminal is attached and refuse to run without `--yes` when one isn't.
- **Honest exit codes**: `0` on success, simctl's own code on failure, `64` for usage errors.

[Unreleased]: https://github.com/raphkoebraam/Mirage/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/raphkoebraam/Mirage/releases/tag/v0.9.0
