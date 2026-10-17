# go-ibkr

[![Go Reference](https://pkg.go.dev/badge/github.com/psyb0t/go-ibkr.svg)](https://pkg.go.dev/github.com/psyb0t/go-ibkr)
[![CI](https://github.com/psyb0t/go-ibkr/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/psyb0t/go-ibkr/actions/workflows/pipeline.yml)
[![version](https://raw.githubusercontent.com/psyb0t/go-ibkr/badges/version.svg)](https://github.com/psyb0t/go-ibkr/tags)
[![license](https://raw.githubusercontent.com/psyb0t/go-ibkr/badges/license.svg)](LICENSE)
[![imported by](https://raw.githubusercontent.com/psyb0t/go-ibkr/badges/importers.svg)](https://github.com/psyb0t/go-ibkr/blob/badges/importers.md)

Unofficial Go client for the [Interactive Brokers Web API](https://www.interactivebrokers.com/campus/ibkr-api-page/web-api/) (Client Portal API v1), generated with [oapi-codegen](https://github.com/oapi-codegen/oapi-codegen) from the OpenAPI document Interactive Brokers publishes at `https://api.ibkr.com/gw/api/v3/api-docs`.

The package is `ibkr`, in the repository root. Everything in `client.gen.go` is generated. Don't edit it by hand, regenerate it.

## Install

```sh
go get github.com/psyb0t/go-ibkr
```

## Usage

Every endpoint in the spec has a typed method on `ClientWithResponses`. The spec paths carry their full prefix (`/v1/api/...`, `/gw/api/v1/...`), so the base URL is only the scheme and host.

```go
package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net/http"

	"github.com/psyb0t/go-ibkr"
)

func main() {
	// The Client Portal Gateway serves a self-signed certificate.
	httpClient := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		},
	}

	client, err := ibkr.NewClientWithResponses(
		"https://localhost:5000",
		ibkr.WithHTTPClient(httpClient),
	)
	if err != nil {
		panic(err)
	}

	res, err := client.GetBrokerageAccountsWithResponse(context.Background())
	if err != nil {
		panic(err)
	}

	fmt.Println((*res.JSON200.Accounts)[0])
}
```

Only skip certificate checks for a gateway on your own machine. Point the client at any other host with normal TLS.

The same call is in `example_test.go`, where it runs against a stub gateway, so `make test` checks it.

The full API, with the spec's descriptions as doc comments, is in the [Go reference](https://pkg.go.dev/github.com/psyb0t/go-ibkr) and in `go doc github.com/psyb0t/go-ibkr`.

## Auth

I don't implement any login flow here. The client sends whatever the session you hand it carries. There are two ways to get one.

**Client Portal Gateway.** Download and run the gateway from Interactive Brokers, open `https://localhost:5000` in a browser and log in. The gateway keeps the brokerage session and adds the auth to every request it forwards, so the client needs no credentials, only the base URL `https://localhost:5000` (or wherever you run the gateway). `GetBrokerageStatusWithResponse` (`POST /v1/api/iserver/auth/status`) reports whether the session is logged in. Call `GetSessionTokenWithResponse` (`POST /v1/api/tickle`) about once a minute to keep the session alive.

**OAuth.** If you have OAuth access to `https://api.ibkr.com`, get the access token with your own OAuth code and attach it with a request editor:

```go
auth := ibkr.WithRequestEditorFn(func(_ context.Context, req *http.Request) error {
	req.Header.Set("Authorization", "Bearer "+accessToken)

	return nil
})

client, err := ibkr.NewClientWithResponses("https://api.ibkr.com", auth)
```

## Regenerating

The spec is not committed. `make generate` downloads the current OpenAPI document into the gitignored `api/` directory and regenerates the client:

```sh
make generate
```

`gen.go` declares the steps, so `make generate` is just `go generate ./...`:

- `scripts/fetch-spec.sh` downloads `api/openapi.json`.
- `scripts/patch-spec.sh` writes `api/openapi.patched.json` with the spec defects that stop oapi-codegen fixed. Path parameters missing from their path template are renamed to the undeclared placeholder when there is exactly one, and dropped otherwise. Placeholders with no parameter get a required string parameter. Duplicate operation IDs get a numeric suffix (`getTradingSchedule2`).
- oapi-codegen runs with `config.yaml` against the patched spec.

`.github/workflows/regen.yml` does the same every day in CI. When the new spec changes the client, it runs `make lint`, `make test` and `make sec`. If a check fails, Claude edits the code and the checks run again, up to three times, and a review step reads the result. A passing change is committed with a CHANGELOG entry and tagged as the next release: a patch version for fixes and additions, a minor version for breaking changes.

## Agent integrations

The [skill](.agents/skills/go-ibkr) teaches a coding agent how to use go-ibkr when it writes Go. It works in any agent that reads `.agents/skills/`, and installs natively in the clients below.

### Claude Code

```bash
claude plugin marketplace add psyb0t/agents
claude plugin install go-ibkr@psyb0t
```

### Codex

```bash
codex plugin marketplace add psyb0t/agents
codex plugin add go-ibkr@psyb0t
```

Codex also picks the skill up with no install in any checkout of this repo.

### OpenClaw

The skill is published to ClawHub on every release:

```bash
openclaw skills install @psyb0t/go-ibkr
```

## Development

Every command runs in the `Dockerfile.dev` image. The host needs only Docker and Make.

```sh
make help      # list targets
make dep       # go mod tidy + vendor
make lint      # shellcheck, shfmt, go fix, golangci-lint
make test      # go test -race
make sec       # gitleaks, govulncheck, semgrep
make generate  # download the spec and regenerate
```

## License

[MIT](LICENSE). The generated code comes from the API specification Interactive Brokers publishes. The specification itself is not redistributed here. This project is not affiliated with Interactive Brokers.
