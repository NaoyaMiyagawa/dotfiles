##############################################################################
# Functions
##############################################################################

# ----------------------------------------------------------------------------
# zsh hooks
# ----------------------------------------------------------------------------

# update terminal (and cmux sidebar) with current working directory via OSC 7
# also persist last CWD per cmux workspace for session restore
_update_cwd() {
    printf "\e]7;file://%s%s\a" "$HOST" "$PWD"
    if [[ -n "$CMUX_WORKSPACE_ID" ]]; then
        local dir="${XDG_CACHE_HOME:-$HOME/.cache}/cmux-dirs"
        mkdir -p "$dir"
        echo "$PWD" > "$dir/$CMUX_WORKSPACE_ID"
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _update_cwd
_update_cwd  # emit once on shell start

# restore last saved directory for this cmux workspace (call from shell startup or manually)
cmux-restore-dir() {
    if [[ -n "$CMUX_WORKSPACE_ID" ]]; then
        local saved="${XDG_CACHE_HOME:-$HOME/.cache}/cmux-dirs/$CMUX_WORKSPACE_ID"
        if [[ -f "$saved" ]]; then
            local dir
            dir=$(cat "$saved")
            [[ -d "$dir" ]] && cd "$dir"
        fi
    fi
}

# control commands to record in history
zshaddhistory() {
    local line="${1%%$'\n'}"
    local lsCmds="ls|ll|lla"
    local gitCmds="ga|gd|gds|gf|gst"
    local lazygitCmds="lazygit|lg"

    [[ ! "$line" =~ "^(cd|$lsCmds|$gitCmds|$lazygitCmds)($| )" ]]
}

# ----------------------------------------------------------------------------
# fuzzy-cd : change directory using fuzzy search
# ----------------------------------------------------------------------------
# the -o -path entries are exclusion paths
# NOTE: named `fuzzy-cd` (not `fd`) to avoid shadowing the sharkdp/fd binary
fuzzy-cd() {
    local dir
    dir=$(find ${1:-.} \( -path '*/\.*' \
        -o -path '\./Music/*' \
        -o -path '\./Library/*' \
        -o -path '*/vendor/*' \
        -o -path '*/vendors/*' \
        -o -path '*/node_modules/*' \
        -o -path '*/.git/*' \
        -o -path '*/dist/*' \
        -o -path '*/build/*' \
        \) -prune -o -type d -print 2>/dev/null | fzf +m) &&
        cd "$dir"
}

# ----------------------------------------------------------------------------
# fssh : ssh connection using fuzzy search
# ----------------------------------------------------------------------------
fssh() {
    local sshLoginHost
    sshLoginHost=$(cat ~/.ssh/config | grep -i '^host' | awk '{print $2}' | fzf)

    if [ "$sshLoginHost" = "" ]; then
        # ex) Ctrl-C.
        return 1
    fi

    ssh ${sshLoginHost}
}

# ----------------------------------------------------------------------------
# peco-cdr [Ctrl + U] : fuzzy search of recently visited directories
# ----------------------------------------------------------------------------
# load the required shell functions
autoload -Uz add-zsh-hook
autoload -Uz cdr
autoload -Uz chpwd_recent_dirs

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
# peco-cdr
function peco-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | awk -F" " '{print $2}' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N peco-cdr
# NOTE: the `bindkey '^U' peco-cdr` lives in .zshrc *after* `bindkey -e`.
# `bindkey -e` re-selects the emacs keymap and resets ^U to kill-whole-line,
# so binding it here (function.zsh runs earlier) would be clobbered.

# ----------------------------------------------------------------------------
# ..  : fuzzy-pick an ancestor of $PWD and cd into it
# ----------------------------------------------------------------------------
# Replaces the old `alias ..='cd ..'`. The nearest parent is listed first, so
# `..`<Enter> == cd .. (feels instant); scroll down to jump further up.
function ..() {
    local dir="$PWD"
    local -a parents
    while [[ "$dir" != "/" ]]; do
        dir="${dir:h}"
        parents+=("$dir")
    done
    (( ${#parents} )) || return 0  # already at /
    local selected
    selected="$(print -l -- "${parents[@]}" | peco --prompt='cd ↑ >')"
    [[ -n "$selected" ]] && cd -- "$selected"
}

# ----------------------------------------------------------------------------
# fbr : fuzzy search of local Git branches + git switch
# ----------------------------------------------------------------------------
fbr() {
    local branches branch
    branches=$(git branch -vv) &&
    branch=$(echo "$branches" | fzf +m) &&
    git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# ----------------------------------------------------------------------------
# fbrm : fuzzy search of local + remote Git branches + git switch
# ----------------------------------------------------------------------------
fbrm() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# ----------------------------------------------------------------------------
# fshow : Git commit browser
# ----------------------------------------------------------------------------
fshow() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
        fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
            --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
                FZF-EOF"
}
