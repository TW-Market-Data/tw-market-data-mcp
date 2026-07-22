# TW Market Data — MCP server

> **This is the public documentation & issue tracker for the *hosted* TW Market Data (TWMD) MCP server.** The server is a hosted service — there is nothing to install or run locally; you connect to the remote endpoint below. Open an issue here for questions, bug reports, or tool feedback.

TWMD is an agent access layer for **Taiwan stock-market data**: official sources, value-by-value reconciled, **point-in-time safe** (look-ahead protection for backtesting). All tools are read-only.

## Endpoint

| | |
|---|---|
| **URL** | `https://mcp.twmarketdata.com/mcp` |
| **Transport** | streamable-http (MCP `2025-06-18`) |
| **Auth** | `X-API-Key` header — free trial tier for sample tickers; full key at [twmarketdata.com](https://twmarketdata.com) |

## Quickstart

Claude Code / Claude Desktop:

```bash
claude mcp add --transport http tw-market-data https://mcp.twmarketdata.com/mcp \
  --header "X-API-Key: sk_live_..."
```

(replace `sk_live_...` with your key). Any MCP client that speaks streamable-http works — point it at the endpoint and send the `X-API-Key` header.

## Tools

The live `tools/list` (server v1.28.1):

1. **`list_datasets`** — List available Taiwan-market datasets (discovery entry point). Returns id / 中文名 / category / tier / one-line description. Use first to find the right data. Args: `category` (`chip`籌碼 / `fundamental`基本面 / `price`行情 / `macro`總經 / `relation`關聯 / `derivatives`期權 / `event`事件 / `rag_text`文本), `tier`.
2. **`describe_dataset`** — FULL semantics of one dataset: grain (what a row is), field meanings + units, ★time-correctness rules (`knowledge_time_field` / `point_in_time_safe` — read before backtesting), relations for cross-table reasoning, agent_hints, quant_use. Args: `dataset_id`.
3. **`query_dataset`** — Query rows with built-in look-ahead protection. ★ Pass `as_of` (YYYY-MM-DD) for backtesting/agent-learning; non-point-in-time-safe datasets (fundamentals, monthly_revenue, dividend_policy…) are filtered by *disclosure* date ≤ `as_of`. Args: `dataset_id`, `tickers` (e.g. `['2330','2317']`), `start`/`end`, `as_of`, `limit` (≤5000). Returns `{meta:{table,coverage,row_count,as_of_applied,point_in_time_safe,warnings}, data:[…]}`.
4. **`find_related`** — Related-dataset discovery over a knowledge graph. `dataset_id` → join-able datasets (+why) to plan multi-table analysis; `ticker` → its industry value-chain node + peers (supply-chain reasoning).

Machine-readable server descriptor: [`server.json`](./server.json).

## Links

- Website: <https://twmarketdata.com>
- REST API (OpenAPI): <https://api.twmarketdata.com/openapi.json>
- Python client: [`twmarketdata`](https://pypi.org/project/twmarketdata/) (`pip install twmarketdata`)

## License

[MIT](./LICENSE) — covers this repository's documentation. The hosted TWMD API/service is commercial.
