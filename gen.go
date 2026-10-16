// Package ibkr is a Go client for the Interactive Brokers Web API, generated
// with oapi-codegen from the OpenAPI document Interactive Brokers publishes.
package ibkr

//go:generate bash scripts/fetch-spec.sh openapi.json
//go:generate bash scripts/patch-spec.sh
//go:generate go tool oapi-codegen --config=config.yaml api/openapi.patched.json
