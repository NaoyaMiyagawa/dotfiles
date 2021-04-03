# .zshrc

##############################################################################
# environment variables
##############################################################################

export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"

# composer
export PATH="$PATH:$HOME/.composer/vendor/bin:$PATH"

# fluter
export PATH="$PATH:$HOME/Documents/flutter/bin:$PATH"

# yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# online-judge-tool 用 ｜ `time` を gtimeではなくtimeとして動かす
export PATH="/usr/local/opt/gnu-time/libexec/gnubin:$PATH"

# php 7.4
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export LDFLAGS="-L/usr/local/opt/icu4c/lib"
export CPPFLAGS="-I/usr/local/opt/icu4c/include"
export PATH="/usr/local/opt/libiconv/bin:$PATH"
export PATH="/usr/local/opt/bzip2/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/bzip2/lib"
export CPPFLAGS="-I/usr/local/opt/bzip2/include"
export CFLAGS=-DU_DEFINE_FALSE_AND_TRUE=1
[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

# anyenv
if [ -e "$HOME/.anyenv" ]
then
    export ANYENV_ROOT="$HOME/.anyenv"
    export PATH="$ANYENV_ROOT/bin:$PATH"
    if command -v anyenv 1>/dev/null 2>&1
    then
        eval "$(anyenv init -)"
    fi
fi

# direnv
if type direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# pyenv
# export PATH="$(pyenv root)/libexec:$PATH"

# tfenv
export PATH="$HOME/.anyenv/envs/tfenv/bin:$PATH"

export PATH="/usr/local/opt/bison/bin:$PATH"
export PATH="/usr/local/opt/libxml2/bin:$PATH"


# rbenv (ruby)
# export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
# [[ -d ~/.rbenv  ]] && \
#   export PATH=${HOME}/.rbenv/bin:${PATH} && \
#   eval "$(rbenv init -)"

# nvm (node.js)
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export LC_ALL=ja_JP.UTF-8
export HOMEBREW_PREFIX="/usr/local"
export HISTTIMEFORMAT='%Y%m%d %T%z | '

export EDITOR=vim

# exa
#export LS_COLORS="uu=37"
export EXA_COLORS="uu=37:gu=37"

##############################################################################
# zinit 本体読み込み
##############################################################################

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

##############################################################################
# zsh / zinit 設定ファイル読み込み
##############################################################################

DOTFILES_PATH=$HOME/dotfiles

source $DOTFILES_PATH/.zsh/alias.zsh
source $DOTFILES_PATH/.zsh/function.zsh
source $DOTFILES_PATH/.zsh/plugin.zsh

##############################################################################
# PROMPT テーマ
##############################################################################

if [[ ! -f /usr/local/bin/starship ]]; then
    command curl -fsSL https://starship.rs/install.sh | bash -s -- -y
fi

eval "$(starship init zsh)"

##############################################################################
# New
##############################################################################
