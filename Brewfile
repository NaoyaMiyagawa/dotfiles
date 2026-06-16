# Brewfile — curated CLI tools for this dotfiles environment.
#
# Apply on a new machine (after installing Homebrew and running `make install`):
#   make brew            # or: brew bundle --file=Brewfile
#
# Hand-maintained on purpose (NOT `brew bundle dump`) — add tools deliberately.
#
# Not on Homebrew, install separately:
#   sonar (SonarQube CLI):
#     curl -fsSL https://raw.githubusercontent.com/SonarSource/sonarqube-cli/refs/heads/master/user-scripts/install.sh | bash

# --- Search / navigation ---
brew "ripgrep"   # rg  — fast grep replacement
brew "fd"        # fast find replacement
brew "fzf"       # fuzzy finder (used by fuzzy-cd, fbr, fbrm, fshow, fssh)
brew "peco"      # fuzzy finder (used by peco-cdr and the `de` alias)
brew "ast-grep"  # sg  — structural (AST) code search & rewrite

# --- Files / text ---
brew "bat"       # cat replacement with syntax highlighting
brew "eza"       # ls replacement
brew "sd"        # sed replacement for simple find/replace
brew "jq"        # JSON processor
brew "yq"        # YAML/JSON/TOML processor

# --- Git / dev workflow ---
brew "gh"        # GitHub CLI
brew "lazygit"   # git TUI
brew "git-delta" # delta — syntax-highlighting diff pager
brew "git-town"  # high-level git branch workflows
brew "hyperfine" # command-line benchmarking
brew "tealdeer"  # tldr — example-first man pages
brew "jira-cli"  # jira — Jira from the terminal

# --- AI agent tooling ---
brew "rtk"       # Rust Token Killer — token-optimizing CLI proxy

# --- Infra ---
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"
