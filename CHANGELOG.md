# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.4, 2026-10-27

- The development image is based on Debian (`golang:1.26.10-trixie`) instead of Alpine. Alpine keeps only the latest build of each package, so the exact pins broke the image build whenever a package was updated. System packages now come from the snapshot.debian.org date the base image was built from, which keeps them fixed for a given base image digest. jq 1.8.2, shellcheck 0.11.0 and shfmt 3.13.1 keep their versions, and Semgrep runs in its own virtual environment.
- Raised the minimum Go version in `go.mod` from 1.26.9 to 1.26.10, which fixes the `crypto/x509` vulnerability GO-2026-6809 found by govulncheck.
- The issue-pull workflow runs at hours derived from the repository name instead of the same four hours as every other repository.

## v0.1.3, 2026-10-17

- Documentation only. The agent skill explains how to look up every endpoint, parameter and model with `go doc` or on pkg.go.dev, and declares its license.
- The README points to the full API reference, and the examples in the README and the skill were checked against the current code.
- The skill's frontmatter is valid YAML again; an unquoted colon in the description stopped it from parsing. The README example matches `example_test.go`.

## v0.1.2, 2026-10-17

- Documentation only. The README and `AGENTS.md` describe the daily regeneration workflow: what it checks, how it fixes failing checks, how it picks the next version and which paths a fix may not touch.

## v0.1.1, 2026-10-16

- Added the `go-ibkr` agent skill. The README's new Agent integrations section has the install commands for Claude Code, Codex and ClawHub.

## v0.1.0, 2026-10-16

- Added `ibkr`, a REST client for the Interactive Brokers Web API generated with oapi-codegen from the published OpenAPI document (spec version 2.41.0, 179 paths).
- `make generate` downloads the current spec and patches its broken path parameters and duplicate operation IDs before generating. The spec is not committed.
