# Verification shim ONLY — for MCP-registry (Glama) introspection. NOT the production server.
#
# Production TW Market Data is a HOSTED service at https://mcp.twmarketdata.com/mcp (streamable-http,
# X-API-Key). This image is a thin stdio<->HTTP bridge (mcp-remote) that lets a registry's Docker-based
# validator introspect the tool list against that hosted endpoint. Introspection uses the endpoint's
# keyless-discovery mode (MCP_KEYLESS_DISCOVERY) — so NO API KEY is baked into this image. Real tool
# *calls* still require your own X-API-Key, passed at runtime (never build-time), e.g.:
#   docker run -e TWMD_API_KEY=sk_live_... <image>   # then the entrypoint would add --header
#
# Do NOT put a real key in this Dockerfile or image.
FROM node:22-alpine

# Pin mcp-remote for reproducible verification builds.
RUN npm install -g mcp-remote@0.1.29

# Bridge stdio (what a Docker-based MCP validator speaks) to the hosted streamable-http endpoint.
# http-only: our endpoint is streamable-http, not SSE. No key here — introspection is keyless.
ENTRYPOINT ["npx", "-y", "mcp-remote", "https://mcp.twmarketdata.com/mcp", "--transport", "http-only"]
