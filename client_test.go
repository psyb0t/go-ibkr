package ibkr_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/psyb0t/go-ibkr"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const testToken = "test-token"

type seenRequest struct {
	method string
	path   string
	auth   string
}

func newTestClient(
	t *testing.T,
	body string,
) (*ibkr.ClientWithResponses, *seenRequest) {
	t.Helper()

	seen := &seenRequest{}

	srv := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			seen.method = r.Method
			seen.path = r.URL.Path
			seen.auth = r.Header.Get("Authorization")

			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(body))
		},
	))
	t.Cleanup(srv.Close)

	auth := ibkr.WithRequestEditorFn(
		func(_ context.Context, req *http.Request) error {
			req.Header.Set("Authorization", "Bearer "+testToken)

			return nil
		},
	)

	client, err := ibkr.NewClientWithResponses(srv.URL, auth)
	require.NoError(t, err)

	return client, seen
}

func TestGetBrokerageStatus(t *testing.T) {
	client, seen := newTestClient(
		t,
		`{"authenticated":true,"competing":false,"connected":true}`,
	)

	res, err := client.GetBrokerageStatusWithResponse(t.Context())
	require.NoError(t, err)

	assert.Equal(t, http.MethodPost, seen.method)
	assert.Equal(t, "/v1/api/iserver/auth/status", seen.path)
	assert.Equal(t, "Bearer "+testToken, seen.auth)

	require.NotNil(t, res.JSON200)
	require.NotNil(t, res.JSON200.Authenticated)
	assert.True(t, *res.JSON200.Authenticated)
	require.NotNil(t, res.JSON200.Competing)
	assert.False(t, *res.JSON200.Competing)
}

func TestGetBrokerageAccounts(t *testing.T) {
	client, seen := newTestClient(
		t,
		`{"accounts":["U1111111","U2222222"],"selectedAccount":"U1111111"}`,
	)

	res, err := client.GetBrokerageAccountsWithResponse(t.Context())
	require.NoError(t, err)

	assert.Equal(t, http.MethodGet, seen.method)
	assert.Equal(t, "/v1/api/iserver/accounts", seen.path)
	assert.Equal(t, "Bearer "+testToken, seen.auth)

	require.NotNil(t, res.JSON200)
	require.NotNil(t, res.JSON200.Accounts)
	assert.Equal(t, []string{"U1111111", "U2222222"}, *res.JSON200.Accounts)
	require.NotNil(t, res.JSON200.SelectedAccount)
	assert.Equal(t, "U1111111", *res.JSON200.SelectedAccount)
}
