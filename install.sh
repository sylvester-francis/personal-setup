#!/usr/bin/env bash
#
# install.sh — bootstrap Homebrew, then install a Brewfile by group.
#
# It reads the `#:group:` markers in ./Brewfile and lets you install everything
# or pick/skip groups. Homebrew is installed automatically if it's missing
# (Apple Silicon -> /opt/homebrew, Intel -> /usr/local).
#
# Usage:
#   ./install.sh                 Interactive: prompt for each group
#   ./install.sh -y, --yes       Non-interactive: install all default-ON groups
#   ./install.sh -a, --all       Install every group (including optional ones)
#   ./install.sh python shell    Install only the named group(s)
#   ./install.sh -l, --list      List groups and exit
#   ./install.sh -h, --help      Show this help
#
# Override the Brewfile location with:  BREWFILE=/path/to/Brewfile ./install.sh
#
# Note: `set -u` is intentionally NOT used — macOS ships bash 3.2, which errors
# on empty-array expansion under `set -u`.
set -eo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"
BREWFILE="${BREWFILE:-$SCRIPT_DIR/Brewfile}"

# ---------------------------------------------------------------------------
# Pretty output (color only when stdout is a terminal)
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; RESET=""
fi
info() { printf '%s %s\n' "${BLUE}==>${RESET}" "$*"; }
ok()   { printf '%s %s\n' "${GREEN}==>${RESET}" "$*"; }
warn() { printf '%s %s\n' "${YELLOW}==>${RESET}" "$*" >&2; }
err()  { printf '%s %s\n' "${RED}==>${RESET}" "$*" >&2; }

usage() {
  sed -n '3,22p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Workspace for the assembled, per-run Brewfile
# ---------------------------------------------------------------------------
TMP_WORK="$(mktemp -d "${TMPDIR:-/tmp}/brewbundle.XXXXXX")"
cleanup() { rm -rf "$TMP_WORK"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Parse CLI args
# ---------------------------------------------------------------------------
MODE="interactive"   # interactive | yes | all
DO_LIST=0
POSITIONAL=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -y|--yes)  MODE="yes" ;;
    -a|--all)  MODE="all" ;;
    -l|--list) DO_LIST=1 ;;
    -h|--help) usage; exit 0 ;;
    --)        shift; while [ "$#" -gt 0 ]; do POSITIONAL+=("$1"); shift; done; break ;;
    -*)        err "Unknown option: $1"; usage; exit 2 ;;
    *)         POSITIONAL+=("$1") ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Parse the Brewfile into groups
# ---------------------------------------------------------------------------
if [ ! -f "$BREWFILE" ]; then
  err "Brewfile not found at: $BREWFILE"
  exit 1
fi

GROUP_IDS=()
GROUP_TITLES=()
GROUP_DEFS=()
current=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    '#:group:'*)
      rest="${line#\#:group:}"
      id="${rest%%:*}";   rest="${rest#*:}"
      def="${rest%%:*}";  title="${rest#*:}"
      current="$id"
      GROUP_IDS+=("$id")
      GROUP_TITLES+=("$title")
      GROUP_DEFS+=("$def")
      : > "$TMP_WORK/$id.brewfile"
      ;;
    '#:endgroup'*)
      current=""
      ;;
    *)
      if [ -n "$current" ]; then
        printf '%s\n' "$line" >> "$TMP_WORK/$current.brewfile"
      fi
      ;;
  esac
done < "$BREWFILE"

if [ "${#GROUP_IDS[@]}" -eq 0 ]; then
  err "No '#:group:' markers found in $BREWFILE"
  exit 1
fi

# Comma-separated package names for a group (for display).
group_pkgs() {
  sed -n -E 's/^[[:space:]]*(brew|cask|tap)[[:space:]]+"([^"]+)".*/\2/p' \
    "$TMP_WORK/$1.brewfile" | paste -sd, - | sed 's/,/, /g'
}

# Does group id "$1" exist?
group_exists() {
  local i
  for i in "${!GROUP_IDS[@]}"; do
    if [ "${GROUP_IDS[$i]}" = "$1" ]; then return 0; fi
  done
  return 1
}

# Is "$1" in the SELECTED list?
in_selected() {
  local x
  for x in "${SELECTED[@]}"; do
    if [ "$x" = "$1" ]; then return 0; fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# --list
# ---------------------------------------------------------------------------
if [ "$DO_LIST" -eq 1 ]; then
  printf '%sAvailable groups in %s:%s\n\n' "$BOLD" "$BREWFILE" "$RESET"
  for i in "${!GROUP_IDS[@]}"; do
    if [ "${GROUP_DEFS[$i]}" = "on" ]; then tag="${GREEN}[default on]${RESET}"; else tag="${DIM}[optional]${RESET}"; fi
    printf '  %s%-14s%s %s\n' "$BOLD" "${GROUP_IDS[$i]}" "$RESET" "$tag"
    printf '    %s%s%s\n' "$DIM" "${GROUP_TITLES[$i]}" "$RESET"
    printf '    %s%s%s\n\n' "$DIM" "$(group_pkgs "${GROUP_IDS[$i]}")" "$RESET"
  done
  exit 0
fi

# ---------------------------------------------------------------------------
# Decide which groups to install
# ---------------------------------------------------------------------------
SELECTED=()

select_default_on() {
  local i
  for i in "${!GROUP_IDS[@]}"; do
    if [ "${GROUP_DEFS[$i]}" = "on" ]; then SELECTED+=("${GROUP_IDS[$i]}"); fi
  done
}
select_all() {
  local i
  for i in "${!GROUP_IDS[@]}"; do SELECTED+=("${GROUP_IDS[$i]}"); done
}

if [ "${#POSITIONAL[@]}" -gt 0 ]; then
  for want in "${POSITIONAL[@]}"; do
    if group_exists "$want"; then
      SELECTED+=("$want")
    else
      err "Unknown group: '$want'"
      warn "Run '$0 --list' to see available groups."
      exit 2
    fi
  done
  info "Selected groups: ${SELECTED[*]}"
elif [ "$MODE" = "all" ]; then
  select_all
  info "Installing ALL groups: ${SELECTED[*]}"
elif [ "$MODE" = "yes" ]; then
  select_default_on
  info "Installing default-on groups: ${SELECTED[*]}"
elif [ ! -r /dev/tty ]; then
  warn "No interactive terminal; installing default-on groups (pass -y, -a, or group names to control this)."
  select_default_on
else
  printf '%sChoose what to install%s %s(Enter = the value in brackets)%s\n' \
    "$BOLD" "$RESET" "$DIM" "$RESET"
  for i in "${!GROUP_IDS[@]}"; do
    id="${GROUP_IDS[$i]}"; title="${GROUP_TITLES[$i]}"; def="${GROUP_DEFS[$i]}"
    printf '\n  %s%s%s %s(%s)%s\n' "$BOLD" "$title" "$RESET" "$DIM" "$id" "$RESET"
    printf '    %s%s%s\n' "$DIM" "$(group_pkgs "$id")" "$RESET"
    if [ "$def" = "on" ]; then hint="Y/n"; else hint="y/N"; fi
    printf '    install? [%s] ' "$hint"
    if ! read -r ans </dev/tty; then ans=""; fi
    ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    case "$ans" in
      y|yes) SELECTED+=("$id") ;;
      n|no)  : ;;
      *)     if [ "$def" = "on" ]; then SELECTED+=("$id"); fi ;;
    esac
  done
fi

if [ "${#SELECTED[@]}" -eq 0 ]; then
  warn "No groups selected — nothing to install."
  exit 0
fi

# ---------------------------------------------------------------------------
# Ensure Homebrew is installed and on PATH
# ---------------------------------------------------------------------------
persist_shellenv() {
  local brew_bin="$1" profile="$HOME/.zprofile"
  if [ -f "$profile" ] && grep -qF "$brew_bin shellenv" "$profile"; then return 0; fi
  printf '\n# Homebrew\neval "$(%s shellenv)"\n' "$brew_bin" >> "$profile"
  info "Added Homebrew to $profile (open a new shell to pick it up)."
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    ok "Homebrew present: $(brew --version | head -n1)"
    return 0
  fi
  local p
  for p in /opt/homebrew /usr/local; do
    if [ -x "$p/bin/brew" ]; then
      eval "$("$p/bin/brew" shellenv)"
      ok "Found Homebrew at $p"
      return 0
    fi
  done

  info "Homebrew not found — installing (you may be prompted for your password)..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  local brew_bin=""
  if [ -x /opt/homebrew/bin/brew ]; then brew_bin=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then brew_bin=/usr/local/bin/brew
  else err "Homebrew installation appears to have failed."; exit 1
  fi
  eval "$("$brew_bin" shellenv)"
  persist_shellenv "$brew_bin"
  ok "Homebrew installed."
}

ensure_brew

# ---------------------------------------------------------------------------
# Assemble selected groups into one Brewfile and run brew bundle
# ---------------------------------------------------------------------------
FINAL="$TMP_WORK/Brewfile.selected"
: > "$FINAL"
for id in "${SELECTED[@]}"; do
  printf '# --- %s ---\n' "$id" >> "$FINAL"
  cat "$TMP_WORK/$id.brewfile" >> "$FINAL"
  printf '\n' >> "$FINAL"
done

info "Installing ${#SELECTED[@]} group(s) via 'brew bundle'..."
echo
if brew bundle --file="$FINAL" --no-lock; then
  echo
  ok "All done."
else
  status=$?
  echo
  err "brew bundle finished with errors (exit $status). Re-run to retry failed items."
  exit "$status"
fi

# ---------------------------------------------------------------------------
# Post-install tips (only for groups that were installed)
# ---------------------------------------------------------------------------
tips=()
if in_selected python; then
  tips+=("pyenv: add 'eval \"\$(pyenv init -)\"' to ~/.zshrc, then 'pyenv install 3.12'.")
fi
if in_selected datascience; then
  tips+=("miniforge: run 'conda init zsh' (or use 'mamba') and restart your shell.")
fi
if in_selected shell; then
  tips+=("fzf keybindings: run \"\$(brew --prefix)/opt/fzf/install\".")
fi
if in_selected localllm; then
  tips+=("Ollama: 'ollama run llama3.2' to pull & chat with a model.")
fi
if in_selected runtimes; then
  tips+=("openjdk@17 is keg-only; 'brew info openjdk@17' shows how to put it on PATH.")
fi
tips+=("GUI apps were installed to /Applications.")

if [ "${#tips[@]}" -gt 0 ]; then
  echo
  printf '%sNext steps%s\n' "$BOLD" "$RESET"
  for t in "${tips[@]}"; do printf '  • %s\n' "$t"; done
fi
