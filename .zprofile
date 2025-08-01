# Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"
##############################################################################
# .zprofile
##############################################################################

# ----------------------------------------------------------------------------
# 全般

# emacsモード｜terminalで、Ctrl+A:行頭、Ctrl+E:行末 を有効にする設定
bindkey -e
bindkey "[D" backward-word
bindkey "[C" forward-word
# # Enable Alt+Left/Right to navigate through words
# bindkey "\e\e[D" backward-word
# bindkey "\e\e[C" forward-word

## 実行したプロセスの消費時間が3秒以上かかったら
## 自動的に消費時間の統計情報を表示する。
REPORTTIME=3

# ----------------------------------------------------------------------------
# Completion

# Completion | Colorize completion candidates
autoload -Uz add-zsh-hook
autoload -U colors && colors
zstyle ':completion:*' list-colors "${LS_COLORS}"
# Completion | Select completion candidates from menu
zstyle ':completion:*:default' menu select=2
# Completion | Use cache for faster completion
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' recent-dirs-insert both
# Completion | Ignore case
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# Completion | for cd
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# Completion | settings for cd command
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:*:cd:*:local-directories' menu yes select
zstyle ':completion:*:*:cd:*:path-directories' menu yes select
# Completion | Improve directory completion
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}completing %B%d%b%f'
# Completion | Various settings
setopt always_last_prompt # Avoid unnecessary scrolling
setopt auto_cd            # cd with just the directory name
setopt auto_list          # Display multiple completion candidates
setopt auto_menu          # Auto-complete with consecutive completion keys
setopt auto_param_slash   # Add a trailing slash to directory completions
setopt complete_in_word   # Complete at word boundaries
setopt extended_glob      # Enable extended globbing
setopt glob               # Enable globbing
setopt glob_complete      # Expand globs without completing
setopt list_types         #
setopt magic_equal_subst  # Allow completion for options like --prefix=/usr
setopt mark_dirs          # Add a trailing slash to directory completions
setopt numeric_glob_sort  # Sort numbers numerically
#setopt correct            # スペルミス対応

# ----------------------------------------------------------------------------
# 履歴

# 履歴 ｜ 各種設定
# setopt append_history          # 複数の zsh を同時に使う時など history ファイルに上書きせず追加
setopt EXTENDED_HISTORY       # 開始と終了を記録
setopt auto_pushd             # cd したら pushd
setopt extended_history       # $HISTFILEに時間も記録
setopt hist_expand            # 補完時にヒストリを自動的に展開
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # 同じコマンドをヒストリに残さない
setopt hist_ignore_dups       # 重複を記録しない
setopt hist_ignore_space      # スペースで始まるコマンド行はヒストリリストから削除
setopt hist_no_store          # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks     # 余分な空白は詰めて記録
setopt hist_save_no_dups      # 重複するコマンドが保存されるとき、古い方を削除する。
setopt hist_verify            # ヒストリを呼び出してから実行する間に一旦編集可能
setopt histignorealldups      # ヒストリーに重複を表示しない
setopt inc_append_history     # 履歴をインクリメンタルに追加
setopt interactive_comments   # コマンドラインでも # 以降をコメントと見なす
setopt no_beep                # ビープ音を消す
setopt print_eight_bit        # 日本語ファイル名を表示可能にする
setopt share_history          # 他のターミナルとヒストリーを共有

# ----------------------------------------------------------------------------
# 検索

# 検索 ｜ 曖昧サーチ設定
zstyle ":history-search-multi-word" page-size "30"                   # 表示行数
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold" # 一致箇所のスタイル
zstyle ":plugin:history-search-multi-word" active "bg=blue"          # 選択行のスタイル
# bindkey "^R" history-incremental-search-backward
# bindkey "^S" history-incremental-search-forward

# Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
