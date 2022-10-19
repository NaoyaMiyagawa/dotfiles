export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"

# composer
export PATH="$PATH:$HOME/.composer/vendor/bin:$PATH"

# yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if is_osx; then

    # # fluter
    # export PATH="$PATH:$HOME/Documents/flutter/bin:$PATH"

    # # online-judge-tool 用 ｜ `time` を gtimeではなくtimeとして動かす
    # export PATH="/usr/local/opt/gnu-time/libexec/gnubin:$PATH"

    # # php 7.4
    # # - icu4c
    # export PATH="/usr/local/opt/icu4c/bin:$PATH"
    # export PATH="/usr/local/opt/icu4c/sbin:$PATH"
    # export LDFLAGS="-L/usr/local/opt/icu4c/lib"
    # export CPPFLAGS="-I/usr/local/opt/icu4c/include"
    # export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig"
    # # -
    # export PATH="/usr/local/opt/libiconv/bin:$PATH"
    # # - bzip2
    # export PATH="/usr/local/opt/bzip2/bin:$PATH"
    # export LDFLAGS="-L/usr/local/opt/bzip2/lib"
    # export CPPFLAGS="-I/usr/local/opt/bzip2/include"
    # # -
    # export CFLAGS=-DU_DEFINE_FALSE_AND_TRUE=1
    # [[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc
    # # - openssl
    # export OPENSSL_CFLAGS="-I$(brew --prefix openssl)/include"
    # export OPENSSL_LIBS="-L$(brew --prefix openssl)/lib"
    # # - curl
    # export LDFLAGS="-L/usr/local/opt/curl/lib"
    # export CPPFLAGS="-I/usr/local/opt/curl/include"
    # export PKG_CONFIG_PATH="/usr/local/opt/curl/lib/pkgconfig"

    # anyenv
    if [[ -e "$HOME/.anyenv" ]]; then
        export PATH="$HOME/.anyenv/bin:$PATH"

        if command -v anyenv 1>/dev/null 2>&1; then
            eval "$(anyenv init -)"
        fi
    fi

    # direnv
    if type direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
    fi

    # asdf
    if [[ -e /usr/local/opt/asdf/libexec/asdf.sh ]]; then
        . /usr/local/opt/asdf/libexec/asdf.sh
    fi

    # tfenv
    if type tfenv >/dev/null 2>&1; then
        export PATH="$HOME/.anyenv/envs/tfenv/bin:$PATH"
    fi

    export PATH="/usr/local/opt/libxml2/bin:$PATH"

    # Dockerイメージのセキュリティ対策
    #export DOCKER_CONTENT_TRUST=1
    # multipass docker
    export PATH="$PATH:/Users/miyagawa/Library/Application Support/multipass/bin"
    export DOCKER_HOST="ssh://ubuntu@docker.local"

    # export LC_ALL=ja_JP.UTF-8
    export HOMEBREW_PREFIX="/usr/local"

    #eval "$(/opt/homebrew/bin/brew shellenv)"

    # m1 mac homebrew
    # 参考: https://zenn.dev/ress/articles/069baf1c305523dfca3d
    typeset -U path PATH
    path=(
        /opt/homebrew/bin(N-/)
        /usr/local/bin(N-/)
        $path
    )
    if (( $+commands[sw_vers] )) && (( $+commands[arch] )); then
        [[ -x /usr/local/bin/brew ]] && alias brew="arch -arch x86_64 /usr/local/bin/brew"
        alias x64='exec arch -x86_64 /bin/zsh'
        alias a64='exec arch -arm64e /bin/zsh'
        switch-arch() {
            if  [[ "$(uname -m)" == arm64 ]]; then
                arch=x86_64
            elif [[ "$(uname -m)" == x86_64 ]]; then
                arch=arm64e
            fi
            exec arch -arch $arch /bin/zsh
        }
    fi
    setopt magic_equal_subst

    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

export HISTTIMEFORMAT='%Y%m%d %T%z | '
export EDITOR=vim

# パスの重複を削除
typeset -U PATH

# ls
export LS_COLORS="uu=37"
# exa
export EXA_COLORS="uu=37:gu=37"
# bat
export BAT_THEME="TwoDark"
# fzf
# export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
# export FZF_DEFAULT_OPTS='--preview "bat  --color=always --style=header,grid --line-range :100 {}"'
