##############################################################################
# Path
##############################################################################

### paths ###
typeset -gU PATH path
typeset -gU FPATH fpath

# asdf (0.16+) uses a binary; keep data dir explicit for shim path.
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

path=(
    '/usr/local/bin'(N-/)
    '/usr/local/sbin'(N-/)
    '/usr/bin'(N-/)
    '/usr/sbin'(N-/)
    '/bin'(N-/)
    '/sbin'(N-/)
)

path=(
    # asdf
    "$ASDF_DATA_DIR/shims"(N-/)
    # composer
    "$HOME/.composer/vendor/bin"(N-/)
    # yarn
    "$HOME/.yarn/bin"(N-/)
    "$HOME/.config/yarn/global/node_modules/.bin"(N-/)
    # php 8.3
    "/opt/homebrew/opt/php@8.3/bin"(N-/)
    "/opt/homebrew/opt/php@8.3/sbin"(N-/)
    "/opt/homebrew/opt/icu4c/bin"(N-/)
    "/opt/homebrew/opt/icu4c/sbin"(N-/)
    # cargo
    "$HOME/.cargo/bin"(N-/)
    # online-judge-tool 用 ｜ `time` を gtimeではなくtimeとして動かす
    "/usr/local/opt/gnu-time/libexec/gnubin"(N-/)
    # tfenv
    "$HOME/.anyenv/envs/tfenv/bin"(N-/)
    # console-ninja
    "$HOME/.console-ninja/.bin"(N-/)
    # opencode
    "$HOME/.opencode/bin"(N-/)
    # cursor agent
    "$HOME/.local/bin"(N-/)
    # ?
    "/usr/local/opt/libxml2/bin"(N-/)
    "$path[@]"
)

if is_osx; then
    # homebrew
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # direnv
    if type direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
    fi

fi

