# mirage

> Codename `mirage` — a simulated image that behaves like the real thing.

A humane, scriptable CLI for managing Apple simulators. `mirage` wraps
`xcrun simctl` with fuzzy device resolution, sensible defaults, readable
output, and interactive prompts.

Status: under active development. See [docs/SCOPE.md](docs/SCOPE.md) for the
full analysis and roadmap.

## Development

Requirements: Xcode 26+, [mise](https://mise.jdx.dev) (pins Tuist).

```bash
mise install            # installs the pinned Tuist version
tuist install           # resolves dependencies
tuist generate --no-open
xcodebuild build -workspace Mirage.xcworkspace -scheme mirage
xcodebuild test  -workspace Mirage.xcworkspace -scheme MirageKitTests
```

## Documentation

- [Scope & analysis](docs/SCOPE.md)
- [ADR 0001 — Adopt Noora](docs/adr/0001-adopt-noora.md)
