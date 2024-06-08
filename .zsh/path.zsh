export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"

# composer
export PATH="$PATH:$HOME/.composer/vendor/bin:$PATH"

# yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if is_osx; then
    # # online-judge-tool 用 ｜ `time` を gtimeではなくtimeとして動かす
    # export PATH="/usr/local/opt/gnu-time/libexec/gnubin:$PATH"

    # php 8.1
    export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH"
    export PATH="/opt/homebrew/opt/php@8.3/sbin:$PATH"
    export LDFLAGS="-L/opt/homebrew/opt/php@8.3/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/php@8.3/include"

    export PATH="/opt/homebrew/opt/icu4c/bin:$PATH"
    export PATH="/opt/homebrew/opt/icu4c/sbin:$PATH"
    export LDFLAGS="-L/opt/homebrew/opt/icu4c/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/icu4c/include"

    # direnv
    if type direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
    fi

    # asdf
    if [[ -e /opt/homebrew/opt/asdf/etc/bash_completion.d/asdf.bash ]]; then
        echo -e "\n. $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash"
        . /opt/homebrew/opt/asdf/etc/bash_completion.d/asdf.bash
    fi

    # tfenv
    if type tfenv >/dev/null 2>&1; then
        export PATH="$HOME/.anyenv/envs/tfenv/bin:$PATH"
    fi

    export PATH="/usr/local/opt/libxml2/bin:$PATH"

    # export LC_ALL=ja_JP.UTF-8
    export HOMEBREW_PREFIX="/usr/local"

    export PATH="$HOME/.console-ninja/.bin:$PATH"

    # lazy git config directory
    export XDG_CONFIG_HOME="$HOME/.config"

    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

export HISTTIMEFORMAT='%Y%m%d %T%z | '
export EDITOR=vim

# remove duplicate paths
typeset -U PATH

# ls
export LS_COLORS="uu=37"
# bat
export BAT_THEME="TwoDark"
