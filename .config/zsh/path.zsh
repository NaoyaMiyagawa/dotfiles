##############################################################################
# Path
##############################################################################

### paths ###
typeset -gU PATH path
typeset -gU FPATH fpath

# asdf (0.16+) uses a binary; keep data dir explicit for shim path.
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

# pnpm global installs land directly in $PNPM_HOME (its bin/ stays empty).
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"

# Completions installed by tools (e.g. sentry-cli); must be on fpath before
# compinit runs in .zshrc.
fpath=("$HOME/.local/share/zsh/site-functions"(N-/) $fpath)

# brew shellenv MUST run before the custom path arrays below: recent Homebrew
# versions invoke /usr/libexec/path_helper, which rebuilds PATH and silently
# drops any custom entries added before it.
if [[ "$OSTYPE" == darwin* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Custom entries first, whatever brew shellenv/the environment provided next,
# system dirs last as a fallback (typeset -U dedupes, keeping first occurrence).
path=(
    # asdf
    "$ASDF_DATA_DIR/shims"(N-/)
    # composer
    "$HOME/.composer/vendor/bin"(N-/)
    # yarn
    "$HOME/.yarn/bin"(N-/)
    "$HOME/.config/yarn/global/node_modules/.bin"(N-/)
    "/opt/homebrew/opt/icu4c/bin"(N-/)
    "/opt/homebrew/opt/icu4c/sbin"(N-/)
    # cargo
    "$HOME/.cargo/bin"(N-/)
    # console-ninja
    "$HOME/.console-ninja/.bin"(N-/)
    # pnpm
    "$PNPM_HOME"(N-/)
    # sonarqube-cli
    "$HOME/.local/share/sonarqube-cli/bin"(N-/)
    "$HOME/.local/bin"(N-/)
    # dotfiles helper scripts (cmux-pr-titles, ...)
    "${DOTFILES_PATH:-$HOME/dotfiles}/bin"(N-/)
    "$path[@]"
    '/usr/local/bin'(N-/)
    '/usr/local/sbin'(N-/)
    '/usr/bin'(N-/)
    '/usr/sbin'(N-/)
    '/bin'(N-/)
    '/sbin'(N-/)
)

# direnv
if [[ -o interactive ]] && type direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi
