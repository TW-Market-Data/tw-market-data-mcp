# TW Market Data — MCP server

> **Public documentation & issue tracker for the *hosted* TWMD MCP server.** There is nothing to
> install: you connect to the remote endpoint below. Open an issue here for questions, bug reports
> or tool feedback.

TWMD is an agent access layer for **Taiwan stock-market data** — TWSE and TPEx. Official sources,
value-by-value reconciled, and **point-in-time safe**: a query carrying `as_of` sees only what was
knowable on that date, which is what makes a backtest run here mean something. Every tool is
read-only. This service places no orders and moves no money.

## Endpoint

| | |
|---|---|
| **URL** | `https://mcp.twmarketdata.com/mcp` |
| **Transport** | streamable-http (MCP `2025-06-18`) |
| **Auth** | OAuth sign-in, or an `X-API-Key` header |

## What works before you have anything

You do not need an account to look around, and you do not need one to get real rows back:

- **The whole catalogue and every reference resource read with no key at all** — dataset list,
  glossary, point-in-time methodology, standards mapping, benchmark method, coverage windows.
- **Five sample tickers answer for free, with no plan**: `2330`, `2317`, `2454`, `0050`, `2603`
  on `twse_daily_price`, `tpex_daily_price` and `monthly_revenue` (capped, and the response says
  so).

Querying beyond those over MCP starts at the **Pro** plan. Upgrading uses the same email you
signed in with and the next query picks it up — **you do not need to reconnect**.

## Connect

**Claude Code**

```bash
claude mcp add --transport http tw-market-data https://mcp.twmarketdata.com/mcp
```

**Claude Desktop / claude.ai — Connectors**

Settings → Connectors → *Add custom connector* → paste `https://mcp.twmarketdata.com/mcp`,
then sign in when prompted.

**ChatGPT — Connectors**

Settings → Connectors → *Add* → paste the same URL and complete the OAuth sign-in.

**With an API key instead of OAuth** (CLI, servers, CI):

```bash
claude mcp add --transport http tw-market-data https://mcp.twmarketdata.com/mcp \
  --header "X-API-Key: sk_live_..."
```

**Any other MCP client** that speaks streamable-http: point it at the endpoint. Anonymous
`initialize` / `tools/list` / `resources/list` are allowed, so a registry can health-check the
server without credentials.

## Tools

### Discovery & semantics — start here

- **`list_datasets`** — List available Taiwan-market datasets (discovery entry point). Returns id / 中文名 / category / tier / one-line description for each. Use this first to find the right data.
- **`describe_dataset`** — FULL semantics of one dataset: grain (what a row is), field meanings+units, ★TIME-CORRECTNESS rules (knowledge_time_field / point_in_time_safe — read before backtesting), relations for cross-table reasoning, agent_hints (when to use), quant_use (which factors).
- **`find_related`** — Traverse the knowledge graph for cross-table / supply-chain reasoning. - dataset_id: returns join-able datasets (+why) to plan multi-table analysis. - ticker: returns its industry value-chain node + peers in the same node (supply-chain reasoning).
- **`get_code_example`** — Emit a copy-pasteable HTTP snippet wired to the real endpoint, header and parameter names.
- **`try_sample`** — Hand an unregistered caller a short taste of an open dataset, plus where to unlock the rest.

### Data

- **`query_dataset`** — Query rows with built-in look-ahead protection.
- **`search_filings`** — Semantic search over MOPS filings, financial-statement notes and company news. Answers questions a keyword filter cannot: "what risks did this company disclose this quarter?", "which companies mentioned CoWoS capacity expansion?" — matching on MEANING, so a paragraph that never uses your exact words still ranks.
- **`read_primary_text`** — Read the FULL TEXT of filings and announcements — with proof links and a knowledge cutoff.
- **`calendar`** — Sort corporate dates into what is still ahead and what has already passed.

### Verifiability — the half you can check yourself

- **`get_inclusion_proof`** — Prove a row was in the snapshot TWMD published — and check it yourself. Returns the Merkle sibling path, the signed root, and the checkpoint it belongs to. It returns the PATH rather than a yes/no on purpose: a service that answers "yes, it is included, trust me" is the opposite of verifiable. Recompute the root from the leaf and the path; the verifier is ~30 lines and is written out in docs/VERIFIABLE_DATA.md.
- **`cite_this`** — Produce a bibliographic citation for TWMD data — APA, BibTeX, and a re-verifiable token.
- **`replay_backtest`** — Re-run a stored backtest and report whether it still produces the same numbers. Same spec, same `as_of`, same data questions. If the numbers moved, either the engine version changed or the underlying data was restated — both are reported, neither is smoothed over.

### Analysis & presentation

- **`ask`** — Answer a plain-language question in Taiwanese-market vocabulary, sentence by sourced sentence.
- **`chart`** — Turn rows you already fetched into a Vega-Lite drawing your chat window can render.
- **`screen`** — Turn a spoken shortlist description into explicit numeric cut-offs, and show the cut-offs.
- **`compare`** — Lay two to five named companies side by side on the same measures, gaps marked as gaps.
- **`run_recipe`** — Replay a saved multi-step routine over rows you fetched, with every step listed.
- **`risk_assess`** — Measure a portfolio you state against limits you state, on official point-in-time prices. Reports concentration and peak-to-trough drawdown, and NAMES every position it could not price rather than quietly assessing the rest — an assessment covering 60% of a portfolio without saying so is worse than none. Any breach produces a PROPOSAL (e.g. "reduce 2330") that requires a human decision. Approving a proposal records that decision; it executes nothing. TWMD has no order path.

### Backtesting (point-in-time)

- **`run_backtest`** — Run a point-in-time backtest and return its run_id, metrics, sources and honesty checks. The run may only see data stamped on or before `as_of` — that is enforced structurally, not by convention. Results arrive with the data `query_ids` behind them and an anti-overfitting verdict (out-of-sample, deflated Sharpe, multiple-comparison, crash stress); a run that fails the gate is returned REJECTED with reasons rather than hidden.
- **`get_backtest`** — Retrieve a previous backtest by run_id — the full record, including why it was rejected. Only runs in YOUR namespace are visible; a run_id belonging to someone else is simply not found.
- **`list_backtests`** — Browse an INDEX of your past backtest runs — ids and headline metrics only, no re-execution. Use when you want to find a run whose id you have forgotten. It never re-computes anything: `run_backtest` executes a new one, `get_backtest` opens a single record in full, and `replay_backtest` re-derives one to check reproducibility. This is the catalogue, not any of those three.

### Memory — your own namespace

- **`memory_save`** — Remember something, with its sources and its knowledge time. Nothing is ever overwritten: saving a `factor_def` or `watchlist` under an existing key SUPERSEDES the previous version (both rows survive, so "what did I believe in June?" stays answerable), and saving identical content twice is a no-op rather than a duplicate.
- **`memory_search`** — Recall your own memories — hybrid (semantic + exact-term), with provenance attached. Every result carries where it came from (`source_query_ids`, replayable), when it was believed (`valid_from`/`valid_to`) and what knowledge time it is about (`as_of`), plus a `recall` block stating which model and which filters produced the answer.
- **`memory_get_watchlist`** — Read the tickers on one named watchlist, as it stands right now. A curated roster you maintain — distinct from `memory_search`, which digs through everything you ever recorded, and from `list_alerts`, which is about price triggers rather than symbols you are following.
- **`memory_replay_query`** — Re-run a remembered query by its `twmd_q_…` id, through the read API's own replay store. This is what makes a recalled finding checkable: the memory says where it came from, and this fetches that same data again. It never re-executes the query by another route — two implementations of "replay" would be two answers to a question whose whole value is having one. `status` is one of: found the bytes are here, with `result_hash` to check them against too_large it WAS served, but exceeded the size ceiling: `result` is absent and `result_hash` is authoritative — you can still verify a copy you hold not_found never recorded (or pruned) — the citation cannot be resolved Args: query_id — the `twmd_q_…` reference carried on a remembered finding's citation.

### Research & agents

- **`run_research`** — Run a multi-agent research pass and return a structured, sourced report. Six roles run in order — data analyst, factor researcher, backtest engineer, risk officer, portfolio manager, compliance officer. Each step's output carries the `query_ids` behind it; risks are reported alongside results, not beneath them; and anything the run could not do is listed as a limitation rather than filled in. The factor researcher checks memory first and SKIPS a hypothesis a previous run already rejected. The portfolio manager proposes nothing when the evidence failed the anti-overfitting gate, and any allocation it does propose is a PROPOSAL awaiting a human — this system places no orders and moves no money.
- **`get_research`** — Retrieve one of YOUR previous research reports. Others' runs are simply not found.
- **`list_factor_findings`** — Verdicts from the overnight factor search on YOUR namespace — including the rejections. The rejections are returned deliberately. A research log that keeps only the winners is the highlight reel overfitting lives in, and the acceptance RATE is the number that tells you whether the anti-overfitting gate is doing its job: a search that accepts most of what it tries has a broken gate, not a talent for finding alpha. Every verdict carries the trial count it was judged against, so it can be re-checked. `coverage.missing` names hypotheses that were proposed but never judged because a cost ceiling was reached — those are UNTESTED, not rejected. An accepted factor is a FINDING with a run_id, not an allocation. Nothing here trades.
- **`agent_activity`** — What YOUR agents have actually done, from the durable audit trail. Every resident agent records what it did and ON WHAT BASIS — the rule and the two closes behind an alert, the coverage and limits behind a risk finding, the run_id and declared trial count behind a factor verdict. This is that trail, and it survives deploys. Reports which agents have recorded NOTHING (`coverage.missing`), because "the monitor has been quiet" and "the monitor is not running" look identical from the records alone and only one of them means your alerts work.

### Actions & alerts — human approval required

- **`list_pending_actions`** — Financial actions proposed by your research runs that are waiting for a human decision. Nothing here has been executed or ever will be by this system. These are proposals.
- **`approve_action`** — Record a HUMAN's approval of a proposed action. This writes an audit record naming who approved what, and when. It does NOT execute the action: TWMD has no order or funds path, by design. Execution, if any, happens elsewhere and is performed by a person.
- **`list_alerts`** — Show the price-trigger rules you have armed, and whether each is still armed. A read-only inventory of thresholds you asked to be watched — it arms nothing and cancels nothing (`set_price_alert` arms, `delete_alert` cancels). Another customer's triggers are simply not visible here.
- **`set_price_alert`** — Leave a standing instruction: tell me when this symbol crosses this price. The alert OUTLIVES this conversation. It is evaluated against official daily closes by a resident agent and delivered to your realtime stream and to any webhook endpoints you have registered — signed, retried, and de-duplicated so one crossing is one notification. This is a NOTIFICATION, not an order. Nothing in TWMD can place a trade.
- **`delete_alert`** — Cancel one armed price trigger permanently, by its rule id. Disarms a single watch so it will not fire again — the opposite of `set_price_alert`, and unlike `list_alerts` it changes state rather than reporting it. Cancellation is irreversible: re-arming means creating a fresh trigger. Naming somebody else's rule id cancels nothing at all.

### Reference resources (`resources/read`) — **no API key needed**

- **`twmd://catalog/datasets`** (application/json) — Every dataset this server can serve, with its temporal semantics.
- **`twmd://reference/glossary`** (application/json) — Plain-language definitions of Taiwan market terms, with citation ids.
- **`twmd://reference/methodology`** (text/markdown) — How as_of is applied per dataset, and what the named look-ahead property proves and does not prove.
- **`twmd://reference/standards`** (application/json) — Controls mapped to FINOS AIGF / NIST AI RMF / ISO 42001 / SOC 2 / SR 26-2, each with an evidence pointer. Self-assessed, not a certification.
- **`twmd://reference/benchmark`** (application/json) — What the frozen question bank measures (leakage and correctness), what it does not measure (profitability), and how the bank hash is derived.
- **`twmd://catalog/coverage`** (application/json) — Per-dataset coverage window and last update, so an agent can tell absence of data from absence of coverage.

### Prompts — workflow templates

- **`verified_backtest`** — The full sequence for a backtest somebody else has to be able to trust.
- **`sourced_lookup`** — For a single number somebody may quote elsewhere.
- **`leakage_healthcheck`** — Runs the frozen bank and reads the report honestly.

## Proof, not assurances

Two of these are worth calling out because they are unusual:

- **`get_inclusion_proof`** returns the Merkle *path*, not a yes/no. A service that answers
  "yes, it is included, trust me" is the opposite of verifiable — recompute the root yourself.
- **`cite_this`** produces a citation that a third party can re-verify later, which is the point
  of citing anything.

## Python SDK and CLI

```bash
pip install twmarketdata
twmd datasets --free-only
twmd get monthly_revenue --ticker 2330 --as-of 2024-06-30 --format csv
```

Source: [TW-Market-Data/twmarketdata](https://github.com/TW-Market-Data/twmarketdata).

## Links

- Website: <https://twmarketdata.com>
- Pricing: <https://twmarketdata.com/en/pricing>
- REST API (OpenAPI): <https://api.twmarketdata.com/openapi.json>
- Machine-readable server descriptor: [`server.json`](./server.json)

## How this list is kept honest

The tool list above is generated from the **live** `tools/list` response, not written by hand and
not scanned out of the source. Tools are mounted at runtime, so "how many `@mcp.tool` exist in the
code" and "how many the server actually serves" are different numbers — and the one that matters to
you is the second. The website's MCP page is generated from the same file, so the two cannot drift.

## License

[MIT](./LICENSE) — covers this repository's documentation. The hosted TWMD API/service is
commercial.
