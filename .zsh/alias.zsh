##############################################################################
# Aliases
##############################################################################

# ----------------------------------------------------------------------------
# General (Global -gオプション付きで定義するとコマンドの途中でも展開される)
# ----------------------------------------------------------------------------
alias -g C='| pbcopy' # copy
alias -g G='| grep'   # grep

# ----------------------------------------------------------------------------
# General
# ----------------------------------------------------------------------------
# 上書きの際にinteractiveになる
alias cp='cp -i'
alias mv='mv -i'
# alias rm='rm -i'

alias ls='ls'
alias l='ls'
alias ll='ls -l'
alias lla='ls -la'
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
if builtin command -v exa >/dev/null; then
    alias exa='exa --group-directories-first --git'
    alias e='exa'
    alias el='exa -l'
    alias ee='exa --time-style=long-iso -alg'
    alias ela='exa --time-style=long-iso -alg'
    alias et='exa -T -L 1'
    alias eta='exa -aT -L 1'

    alias ls="exa"
fi

# ----------------------------------------------------------------------------
# bat ( https://github.com/sharkdp/bat )
# ----------------------------------------------------------------------------
if builtin command -v bat >/dev/null; then
    alias bat='bat --style="numbers,changes,header"'
    alias b='bat --style="numbers,changes,header"'

    alias cat="bat"
fi

# ----------------------------------------------------------------------------
# ripgrep ( https://github.com/BurntSushi/ripgrep )
# ----------------------------------------------------------------------------
if builtin command -v rg >/dev/null; then
    alias grep="rg"
fi

# ----------------------------------------------------------------------------
# docker
# ----------------------------------------------------------------------------
alias dc='docker'
alias de='docker exec -it $(docker ps | peco | cut -d " " -f 1) /bin/bash' # dockerコンテナに入る
alias fig='docker compose'

# ----------------------------------------------------------------------------
# Others
# ----------------------------------------------------------------------------

# terraform
alias tf='terraform'
alias tfp='terraform plan'

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
