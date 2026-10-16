package ibkr_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"

	"github.com/psyb0t/go-ibkr"
)

// The gateway is stubbed so the example runs offline. Against a real Client
// Portal Gateway the base URL is https://localhost:5000.
func Example() {
	gateway := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"accounts":["U1111111"]}`))
		},
	))
	defer gateway.Close()

	client, err := ibkr.NewClientWithResponses(gateway.URL)
	if err != nil {
		panic(err)
	}

	res, err := client.GetBrokerageAccountsWithResponse(context.Background())
	if err != nil {
		panic(err)
	}

	fmt.Println((*res.JSON200.Accounts)[0])
	// Output: U1111111
}
