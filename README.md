# personal-setup

A reproducible macOS dev environment: a **grouped, skippable Brewfile** plus a
**one-command installer** that bootstraps Homebrew and installs only the toolsets
you pick. Tuned for **AI/ML development** and **general productivity**.

## What's inside

| File | Purpose |
|------|---------|
| `Brewfile` | All packages, organized into labeled groups via `#:group:` markers. |
| `install.sh` | Installs Homebrew if missing (Apple Silicon → `/opt/homebrew`, Intel → `/usr/local`), then installs the groups you choose. |

## Requirements

- macOS (Apple Silicon or Intel)
- An internet connection
- Xcode Command Line Tools — Homebrew installs these automatically if needed

## Quick start

```sh
git clone git@github.com:sylvester-francis/personal-setup.git
cd personal-setup
./install.sh
```

With no arguments, `install.sh` walks each group and asks `[Y/n]`, so you can
skip anything you don't want.

## Usage

| Command | What it does |
|---------|--------------|
| `./install.sh` | Interactive — prompt for each group |
| `./install.sh -y`, `--yes` | Non-interactive — install all default-**on** groups |
| `./install.sh -a`, `--all` | Install every group, including optional ones |
| `./install.sh python shell` | Install only the named group(s) |
| `./install.sh -l`, `--list` | List groups and exit |
| `./install.sh -h`, `--help` | Show help |

Point the installer at a different file with `BREWFILE=/path/to/Brewfile ./install.sh`.

## Groups

| Group | Default | Packages |
|-------|:------:|----------|
| `core` | on | git, node, gh |
| `shell` | on | fzf, tmux, ripgrep, fd, bat, eza, htop, tree |
| `python` | on | uv, pyenv, pipx |
| `datascience` | on | miniforge, jupyterlab |
| `mldata` | on | git-lfs, wget, ffmpeg, jq |
| `localllm` | **off** | ollama, lm-studio |
| `editors` | on | visual-studio-code, cursor, zed |
| `terminals` | on | iterm2, warp |
| `devtools` | on | postman, dbeaver-community, docker |
| `cloud` | on | awscli, azure-cli, ansible, terraform, mongodb-community |
| `runtimes` | on | openjdk@17, dotnet-sdk |
| `collab` | on | notion, slack, zoom, microsoft-teams |
| `productivity` | on | raycast, rectangle, obsidian, stats, the-unarchiver |

## Customizing

Each group in the `Brewfile` is delimited by marker comments:

```ruby
#:group:<id>:<on|off>:<Title>
brew "some-formula"
cask "some-app"
#:endgroup
```

- Add or remove `brew` / `cask` / `tap` lines inside a group.
- Flip `<on|off>` to change the default answer shown at the prompt.
- Add a new group by wrapping lines in a fresh marker pair.

The markers are ordinary comments, so a plain `brew bundle --file=Brewfile`
ignores the grouping and installs **everything**.

## How the Homebrew bootstrap works

`install.sh` looks for `brew` on your `PATH`, then in `/opt/homebrew` and
`/usr/local`. If it's missing, it runs the official Homebrew installer
non-interactively, loads `brew shellenv` into the current session, and appends
it to `~/.zprofile` (only if not already present).

## License

[MIT](LICENSE)
