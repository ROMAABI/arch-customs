# llama-server On-Demand Proxy

Auto-starts llama-server on connection, stops after 30s idle to save memory.

## Architecture

```
Port 8080 (public)
    │
    ▼
llama-proxy.py  ──►  llama-server (port 8081)
(on-demand)           (idle-stop 30s)
```

## Files

| File | Purpose |
|---|---|
| `/home/spix/.local/bin/llama-proxy.py` | Proxy daemon |
| `/usr/lib/systemd/system/llama-server.service` | llama-server on port 8081 |
| `/usr/lib/systemd/system/llama-proxy.service` | Proxy on port 8080 |

## Usage

Open `http://127.0.0.1:8080/chat?session=agent%3Amain%3Amain` in browser.

- First request starts llama-server automatically
- After 30s of no connections, server stops
- Configurable via `IDLE_TIMEOUT` in `llama-proxy.py`
