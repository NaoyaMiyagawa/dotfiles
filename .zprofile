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

## 実行したプロセスの消費時間が3秒以上かかったら
## 自動的に消費時間の統計情報を表示する。
REPORTTIME=3

# ----------------------------------------------------------------------------
# 補完

# 補完 ｜ 候補に色付け
autoload -Uz add-zsh-hook
autoload -U colors && colors
zstyle ':completion:*' list-colors "${LS_COLORS}"
# 補完 ｜ 候補をメニューから選択
zstyle ':completion:*:default' menu select=2
# 補完 ｜ キャッシュ利用で高速化
zstyle ':completion::complete:*' use-cache true
#
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' recent-dirs-insert both
# 補完 ｜ 大文字/小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# 補完 ｜ 各種設定
setopt always_last_prompt # 無駄なスクロールを避ける
setopt auto_cd            # ディレクトリ名だけでcdする
setopt auto_list          # 補完候補が複数ある時に、一覧表示
setopt auto_menu          # 補完キー連打で順に補完候補を自動で補完
setopt auto_param_slash   # ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt complete_in_word   # 語の途中でもカーソル位置で補完
setopt extended_glob      # 拡張globを有効にする。
setopt glob               #
setopt glob_complete      # globを展開しないで候補の一覧から補完する。
setopt list_types         #
setopt magic_equal_subst  # コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt mark_dirs          # ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt numeric_glob_sort  # 辞書順ではなく数字順に並べる。
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
