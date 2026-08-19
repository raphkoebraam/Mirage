# Contributing to Mirage

Thanks for your interest in making Mirage better! Questions, bug reports, feature ideas, and pull requests are all very welcome. If you'd rather talk something through before writing code, opening an issue is never the wrong first move, and if you're not sure whether something counts as a bug, report it anyway.

## Getting set up

You'll need macOS 15+ and Xcode 26+. From there it's four commands:

```bash
mise install          # installs tuist, swiftformat, and swiftlint at pinned versions
mise run generate     # resolves dependencies and generates the Xcode workspace
mise run build        # Release build → ./bin/mirage
mise run test         # runs both test suites
```

`mise run generate` is only needed again when `Project.swift`, `Tuist/Package.swift`, or the dependency graph changes. Day to day, `mise run test` is the loop.

## The lay of the land

Mirage is three layers, and the boundaries between them are the reason it's pleasant to work on:

- **`MirageKit`** holds all the logic: the typed `Simctl` client, the models parsed from `simctl list -j`, the device resolver, the cleanup planner. It has zero third-party dependencies. The only thing in the entire codebase that touches the operating system is one small protocol, `CommandRunning`.
- **`MirageCLI`** is the command layer: ArgumentParser command structs plus the terminal presentation (Noora lives here, behind a `UserInterface` protocol so nothing else needs to know about it).
- **`mirage`** is a tiny executable entry point.

Because the OS is behind one seam, the test suite runs in about a second and never touches a real simulator: tests inject a mock runner and assert the exact `simctl` arguments a command produces. That property is the project's favorite feature; please help keep it that way.

## Making changes

A few notes that will help your change land smoothly:

- **Bring a test with you.** A test alongside your change is the best way to show what it does, and the codebase is full of examples to crib from; every command has both an argv-contract test and an end-to-end harness test.
- **Adding a simctl capability is easier than it looks.** It's three steps: a method on `Simctl` with a test asserting the argv it builds, a command struct in `MirageCLI` with a harness test, and a row in [docs/commands.md](docs/commands.md). Any existing command works as a template.
- **Formatting is automated, so there are no style debates.** Run `mise run format` before committing and `mise run lint` to double-check; tool versions are pinned, so there's nothing to configure. Option names are kebab-case, and a small test will remind you if one slips through.
- **Smaller commits are easier to review.** Prefixes like `feat:`, `fix:`, or `docs:` are appreciated, but a good change won't be turned away over commit cosmetics.
- **If you add or change a command, update [docs/commands.md](docs/commands.md).** The synopses there mirror `--help` output exactly, so the two should never drift apart.

## Opening a pull request

Make sure `mise run test` and `mise run lint` pass, describe what the change does and why, and that's it. If CI disagrees with your machine, the workflow logs usually point at the difference. Reviews aim to be quick and kind. The goal is to get good changes in, not to gatekeep.
