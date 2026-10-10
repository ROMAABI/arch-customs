# All User Configs goes here
fastfetch

# llama.cpp shared libraries (installed via cmake to ~/.local/lib)
set -gx LD_LIBRARY_PATH "$HOME/.local/lib" $LD_LIBRARY_PATH

# GEMMA-TUI venv - do NOT add venv/bin to global PATH (breaks system python tools like powerprofilesctl)
# To work on GEMMA-TUI, run manually: source ~/GEMMA-TUI/.venv/bin/activate.fish
