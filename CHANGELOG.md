# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.0, 2026-10-16

- Added `ibkr`, a REST client for the Interactive Brokers Web API generated with oapi-codegen from the published OpenAPI document (spec version 2.41.0, 179 paths).
- `make generate` downloads the current spec and patches its broken path parameters and duplicate operation IDs before generating. The spec is not committed.
