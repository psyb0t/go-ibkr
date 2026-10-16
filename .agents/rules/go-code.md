# Go code

Refines `~/.claude/rule-details/go/wrapping-errors.md` and `~/.claude/rule-details/coding-style.md`.

- **GO1** `client.gen.go` is generated. Never edit it by hand. Change `config.yaml` or the spec patch in `scripts/`, then run `make generate` and commit the result.
- **GO2** Spec fixes live in `scripts/patch-spec.sh`, which writes `api/openapi.patched.json` before oapi-codegen runs. Each fix is a general rule over the spec (orphan path parameters, undeclared placeholders, duplicate operation IDs), not a list of hardcoded paths, and its header comment says which defect it fixes.
- **GO3** The downloaded spec in `api/` is gitignored and never committed.
- **GO4** Hand-written Go (`gen.go` and the tests) wraps errors with `ctxerrors.Wrap` against `ctxerrors/commerr` sentinels. No `fmt.Errorf`, no `errors.New` outside a sentinel declaration.
- **GO5** The exported API is whatever oapi-codegen emits. A patch or config change that renames or removes an exported name, including a new numeric suffix on an operation, is a breaking release (see `releases.md`).
- **GO6** `make lint` passes with zero issues. Hand-written lines are at most 80 columns, the `.golangci.yml` limit.
