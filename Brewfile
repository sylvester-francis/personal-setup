# =============================================================================
# Brewfile — AI/ML developer + general productivity setup (macOS, Apple Silicon)
# =============================================================================
#
# Easiest way (interactive — lets you skip any group):
#
#     ./install.sh
#
# Install everything directly with Homebrew (ignores the group markers):
#
#     brew bundle --file=Brewfile
#
# -----------------------------------------------------------------------------
# GROUP MARKERS
# -----------------------------------------------------------------------------
# A block between `#:group:<id>:<on|off>:<Title>` and `#:endgroup` is a
# skippable group that install.sh reads. They are ordinary comments, so a plain
# `brew bundle` ignores them and installs every entry below.
#   <on|off> = the default answer install.sh shows at its interactive prompt.
# =============================================================================


#:group:core:on:Core developer tools
brew "git"
brew "node"
brew "gh"               # GitHub CLI
#:endgroup

#:group:shell:on:Terminal & shell power-tools
brew "fzf"              # fuzzy finder
brew "tmux"             # terminal multiplexer
brew "ripgrep"          # fast grep (rg)
brew "fd"               # fast, friendly find
brew "bat"              # cat with syntax highlighting
brew "eza"              # modern ls
brew "htop"             # interactive process viewer
brew "tree"            # directory tree view
#:endgroup

#:group:python:on:Python environment management
brew "uv"               # ultra-fast installer / venv / project manager
brew "pyenv"            # manage multiple Python versions
brew "pipx"             # install Python CLIs in isolated envs
#:endgroup

#:group:datascience:on:Data science & notebooks
cask "miniforge"        # conda (arm64-native) for scientific stacks
brew "jupyterlab"       # notebooks
#:endgroup

#:group:mldata:on:Model & data utilities
brew "git-lfs"          # large model/dataset files in git
brew "wget"             # downloads
brew "ffmpeg"           # audio/video preprocessing
brew "jq"               # JSON wrangling
#:endgroup

#:group:localllm:off:Local LLM runtimes (Ollama, LM Studio) — optional
cask "ollama"           # local model runtime / server
cask "lm-studio"        # local model GUI
#:endgroup

#:group:editors:on:Code editors
cask "visual-studio-code"
cask "cursor"
cask "zed"
#:endgroup

#:group:terminals:on:Terminal emulators
cask "iterm2"
cask "warp"
#:endgroup

#:group:devtools:on:Dev tools (DB / API / containers)
cask "postman"
cask "dbeaver-community"
cask "docker"
#:endgroup

#:group:cloud:on:Cloud & infrastructure
tap "hashicorp/tap"
tap "mongodb/brew"
brew "awscli"
brew "azure-cli"
brew "ansible"
brew "hashicorp/tap/terraform"
brew "mongodb-community"
#:endgroup

#:group:runtimes:on:Language runtimes
brew "openjdk@17"
cask "dotnet-sdk"
#:endgroup

#:group:collab:on:Collaboration apps
cask "notion"
cask "slack"
cask "zoom"
cask "microsoft-teams"
#:endgroup

#:group:productivity:on:Productivity apps
cask "raycast"          # launcher / clipboard / snippets
cask "rectangle"        # window tiling
cask "obsidian"         # markdown notes
cask "stats"            # menu-bar system monitor
cask "the-unarchiver"   # archive extraction
#:endgroup
