##############################################################################
# .zshrc
##############################################################################

# Fig pre block. Keep at the top of this file.
. "$HOME/.fig/shell/zshrc.pre.zsh"

# # Fig pre block. Keep at the top of this file.
# export PATH="${PATH}:${HOME}/.local/bin"
# if [[ -f ~/.fig/shell/pre.sh ]]; then
#     eval "$(fig init zsh pre)"
# fi

# ----------------------------------------------------------------------------
# environment variables
# ----------------------------------------------------------------------------

export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"

# composer
export PATH="$PATH:$HOME/.composer/vendor/bin:$PATH"

# yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

DOTFILES_PATH=$HOME/dotfiles

# ----------------------------------------------------------------------------
# zsh / zinit 設定ファイル読み込み
# ----------------------------------------------------------------------------

source ~/.zprofile
source $DOTFILES_PATH/.zsh/function.zsh

# ----------------------------------------------------------------------------
# mac用
# ----------------------------------------------------------------------------

if is_osx; then


    # fluter
    export PATH="$PATH:$HOME/Documents/flutter/bin:$PATH"

    # online-judge-tool 用 ｜ `time` を gtimeではなくtimeとして動かす
    export PATH="/usr/local/opt/gnu-time/libexec/gnubin:$PATH"

    # php 7.4
    # - icu4c
    export PATH="/usr/local/opt/icu4c/bin:$PATH"
    export PATH="/usr/local/opt/icu4c/sbin:$PATH"
    export LDFLAGS="-L/usr/local/opt/icu4c/lib"
    export CPPFLAGS="-I/usr/local/opt/icu4c/include"
    export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig"
    # -
    export PATH="/usr/local/opt/libiconv/bin:$PATH"
    # - bzip2
    export PATH="/usr/local/opt/bzip2/bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/bzip2/lib"
    export CPPFLAGS="-I/usr/local/opt/bzip2/include"
    # -
    export CFLAGS=-DU_DEFINE_FALSE_AND_TRUE=1
    [[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc
    # - openssl
    export OPENSSL_CFLAGS="-I$(brew --prefix openssl)/include"
    export OPENSSL_LIBS="-L$(brew --prefix openssl)/lib"
    # - curl
    export LDFLAGS="-L/usr/local/opt/curl/lib"
    export CPPFLAGS="-I/usr/local/opt/curl/include"
    export PKG_CONFIG_PATH="/usr/local/opt/curl/lib/pkgconfig"

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
    . /usr/local/opt/asdf/libexec/asdf.sh

    # tfenv
    export PATH="$HOME/.anyenv/envs/tfenv/bin:$PATH"

    export PATH="/usr/local/opt/libxml2/bin:$PATH"

    # Dockerイメージのセキュリティ対策
    #export DOCKER_CONTENT_TRUST=1

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

# git settings
git config --global core.ignorecase false

# ----------------------------------------------------------------------------
# zinit 本体読み込み
#
# https://github.com/zdharma-continuum/zinit
# ----------------------------------------------------------------------------

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# ----------------------------------------------------------------------------
# zsh / zinit 設定ファイル読み込み
# ----------------------------------------------------------------------------

source $DOTFILES_PATH/.zsh/alias.zsh
source $DOTFILES_PATH/.zsh/plugin.zsh

# for "There are insecure files:" Error when executing "compaudit"
# https://stackoverflow.com/questions/13762280/zsh-compinit-insecure-directories
# [[ -e! compaudit ]] && compaudit | xargs chmod g-w
# compaudit && compaudit | xargs chmod g-w
if [ ! -e compaudit ]; then
    # https://github.com/zsh-users/zsh-completions/issues/433
    for f in $(compaudit); do
        chown $(whoami):admin $f;
        chmod go-w $f;
    done;
    compaudit | xargs chown root
    compaudit | xargs chmod go-w
fi

# ----------------------------------------------------------------------------
# PROMPT テーマ
# ----------------------------------------------------------------------------

if [[ ! -f /usr/local/bin/starship ]]; then
    command curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

eval "$(starship init zsh)"

# ----------------------------------------------------------------------------
# New
# ----------------------------------------------------------------------------

if is_osx; then
    ### FIG ENV VARIABLES ####
    # Please make sure this block is at the end of this file.
        ### END FIG ENV VARIABLES ####
fi

# Fig post block. Keep at the bottom of this file.
if [[ -f ~/.fig/shell/pre.sh ]]; then
fi

# Fig post block. Keep at the bottom of this file.
. "$HOME/.fig/shell/zshrc.post.zsh"
