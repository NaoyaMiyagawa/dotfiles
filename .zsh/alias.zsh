##############################################################################
# Aliases
##############################################################################

# ----------------------------------------------------------------------------
# General (Global -gオプション付きで定義するとコマンドの途中でも展開される)
# ----------------------------------------------------------------------------
alias -g C='| pbcopy' # copy

# ----------------------------------------------------------------------------
# General
# ----------------------------------------------------------------------------
# 上書きの際にinteractiveになる
alias cp='cp -i'
alias mv='mv -i'
# alias rm='rm -i'

alias ls='ls -G'
alias ll='ls -lG'
alias lla='ls -alG'
alias cd-='fd'
alias v-='vim `fzf`'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cdb='cd-bookmark'
alias cdg='cd-gitroot'
alias pwdc='pwd | tr -d "\n" | pbcopy'

# ----------------------------------------------------------------------------
# Git
# ----------------------------------------------------------------------------
alias gs='git switch'
alias gsm='git switch master'
alias grs='git restore'
alias gop='git open'
# commitizen
alias gcz='git cz'

# ----------------------------------------------------------------------------
# exa ( https://github.com/ogham/exa )
# ----------------------------------------------------------------------------
alias exa-common='exa --group-directories-first --git'
alias e='exa-common'
alias el='exa-common -l'
alias ela='exa-common --time-style=long-iso -alg'
alias et='exa-common -T -L 1'
alias eta='exa-common -aT -L 1'

# ----------------------------------------------------------------------------
# docker
# ----------------------------------------------------------------------------
alias dc='docker'
alias de='docker exec -it $(docker ps | peco | cut -d " " -f 1) /bin/bash' # dockerコンテナに入る
alias fig='docker-compose'

# ----------------------------------------------------------------------------
# Others
# ----------------------------------------------------------------------------

# bat
alias bat='bat --theme="TwoDark" --style="numbers,changes,header"'

# terraform
alias tf='terraform'

# fzf
alias fzf='fzf --reverse'

# tmux
alias tm='tmux'

# vscode
alias c.='code .'

# xxenv で brew doctor の warning対策
alias brew="PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin brew"

# atcoder-cli で pypy として提出するためのsubmitコマンド
alias accs='acc s --skip-filename -- --guess-python-interpreter pypy'
