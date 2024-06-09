##############################################################################
# Functions
##############################################################################

# ----------------------------------------------------------------------------
# dotfilesのOS条件分岐用
# ----------------------------------------------------------------------------
# ostype returns the lowercase OS name
ostype() {
    uname | tr "[:upper:]" "[:lower:]"
}

# os_detect export the PLATFORM variable as you see fit
os_detect() {
    case "$(ostype)" in
        *'linux'*)  PLATFORM='linux'   ;;
        *'darwin'*) PLATFORM='osx'     ;;
        *'bsd'*)    PLATFORM='bsd'     ;;
        *)          PLATFORM='unknown' ;;
    esac

    # 参考 ： [ディストリビューションによって処理を替える - Qiita](https://qiita.com/taishin/items/a7e0c3e25616325a02a6)
    if [ "$PLATFORM" = "linux" ]; then
        RELEASE_FILE=/etc/os-release
        if grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
            PLATFORM='centos'
        elif grep -e '^NAME="Amazon' $RELEASE_FILE >/dev/null; then
            PLATFORM='amazonlinux'
        elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
            PLATFORM='ubuntu'
        else

        fi
    fi

    export PLATFORM
}

# is_osx returns true if running OS is Macintosh
is_osx() {
    if [ -z $PLATFORM ]; then os_detect; fi
    TARGET='osx'
    if [ "$PLATFORM" = $TARGET ]; then return 0; else return 1; fi
}

# is_amazonlinux returns true if running OS is AmazonLinux
is_amazonlinux() {
    if [ -z $PLATFORM ]; then os_detect; fi
    TARGET='amazonlinux'
    if [ "$PLATFORM" = $TARGET ]; then return 0; else return 1; fi
}

# is_centos returns true if running OS is CentOS
is_centos() {
    if [ -z $PLATFORM ]; then os_detect; fi
    TARGET='centos'
    if [ "$PLATFORM" = $TARGET ]; then return 0; else return 1; fi
}

# is_ubuntu returns true if running OS is Ubuntu
is_ubuntu() {
    if [ -z $PLATFORM ]; then os_detect; fi
    TARGET='ubuntu'
    if [ "$PLATFORM" = $TARGET ]; then return 0; else return 1; fi
}

# ----------------------------------------------------------------------------
# zsh hooks
# ----------------------------------------------------------------------------

# control commands to record in history
zshaddhistory() {
    local line="${1%%$'\n'}"
    local lsCmds="ls|ll|lla|ls"
    local gitCmds="ga|gd|gds|gf|gst"
    local lazygitCmds="lazygit|lg"

    [[ ! "$line" =~ "^(cd|$lsCmds|$gitCmds|$lazygitCmds)($| )" ]]
}

# ----------------------------------------------------------------------------
# fd ： 曖昧検索を使ったディレクトリ移動
# ----------------------------------------------------------------------------
# -o -path の箇所は除外パス
fd() {
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
# fssh ： 曖昧検索を使ったssh接続
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
# peco-cdr [Ctrl + U] ： 直近移動したディレクトリの曖昧検索
# ----------------------------------------------------------------------------
# 必要なshell関数を読み込み
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
bindkey '^u' peco-cdr

# ----------------------------------------------------------------------------
# fbr ： Git ローカルブランチの曖昧検索 + git switch
# ----------------------------------------------------------------------------
fbr() {
    local branches branch
    branches=$(git branch -vv) &&
    branch=$(echo "$branches" | fzf +m) &&
    git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# ----------------------------------------------------------------------------
# fbrm ： Git ローカル＋リモートブランチの曖昧検索 + git switch
# ----------------------------------------------------------------------------
fbrm() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# ----------------------------------------------------------------------------
# fbr ： Git コミットブラウザ
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
