# Testing

Refines `~/.claude/rule-details/go/writing-tests.md`.

- **TST1** Tests are black-box, in package `ibkr_test`, and use only the exported API.
- **TST2** Tests never call Interactive Brokers or a gateway. They run the client against an `httptest` server.
- **TST3** The README usage example lives in `example_test.go` too. A README example change goes into `example_test.go` in the same commit.
- **TST4** Every `patch-spec.sh` or config change that alters a generated path or method gets a test that the client sends the expected method and URL.
- **TST5** Table tests use `testCases` and `tc`, call `t.Parallel()` in the test and in every subtest, and assert errors with `require.ErrorIs` against a sentinel.
- **TST6** `make test` runs `go test -race` and must pass.
