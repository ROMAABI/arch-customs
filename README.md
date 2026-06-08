# Gemma 4 12B TUI — Local LLM Chat Client

A terminal UI chat client powered by `llama.cpp` running **Gemma 4 12B** (`unsloth/gemma-4-12b-it-GGUF:Q4_K_M`) locally.

## Setup

### Dependencies

- [llama.cpp](https://github.com/ggml-org/llama.cpp) — built from source (`v9521`, GCC 16.1.1, CPU only)
- Python 3.12+ with `httpx`, `rich`, `pyyaml`, `toml`

### Install

```bash
pip install -e .
```

### Configuration

Config file: `~/.config/gemma-local/config.toml`

```toml
[ui]
name = "Abi"

[server]
host = "127.0.0.1"
port = 8080
model = "unsloth/gemma-4-12b-it-GGUF:Q4_K_M"
```

### Running

#### Start the model server

```bash
llama-server \
  --host 127.0.0.1 --port 8080 \
  -m /path/to/gemma-4-12b-it-Q4_K_M.gguf \
  --alias gemma \
  --no-context-shift \
  --mlock \
  --threads 10 \
  --ctx-size 4096
```

Or use the `gemma` fish function which handles auto-start + TUI launch.

#### Launch the TUI

```bash
python main.py
```

The TUI connects to `localhost:8080` and streams responses with a clean chat interface.

## Architecture

### Files

| Path | Purpose |
|---|---|
| `main.py` | Entry point — launches the TUI app |
| `tui/app.py` | Rich-based terminal UI (chat loop, streaming, display) |
| `core/client.py` | `LlamaClient` — async HTTP/SSE client to `llama-server` |
| `config/settings.py` | Config loader (`~/.config/gemma-local/config.toml` + defaults) |
| `config/defaults.toml` | Built-in default settings |

### How it works

1. `client.py` formats messages into Gemma's prompt template (`<start_of_turn>user|model|system<end_of_turn>`)
2. Sends to `llama-server` `/completion` endpoint (not the chat API — avoids thought-channel parsing issues)
3. Buffers SSE stream, strips the `<|channel>thought\n<channel|>` preamble, yields clean tokens to the TUI

## Model Notes

- **GGUF**: unsloth/gemma-4-12b-it-GGUF:Q4_K_M (~6.3 GB)
- **Hardware**: 13th Gen Intel i5-1334U (CPU-only, SSE3/AVX2), 15 GB RAM
- **Memory**: ~13 GB RSS pinned with `--mlock` — ~2 GB headroom
- **Performance**: ~4-5s first token (warm), ~10-15 tok/s
- **Prompt cache**: `--cache-prompt` enabled for faster follow-ups
- **Template**: Gemma 4 chat format with `<start_of_turn>` / `<end_of_turn>` tags

## Fish Function

A fish shell function (`gemma.fish`) handles server lifecycle:

```fish
function gemma
    # checks health on port 8080
    # if server not running → starts it with --mlock --threads 10
    # launches TUI via `python main.py`
end
```
