##############################################################################
# Plugins
##############################################################################

# 補完をリセット
autoload -Uz compinit && compinit

# ----------------------------------------------------------------------------
# oh-my-zsh: snippet
# ----------------------------------------------------------------------------
# OS間のクリップボードの差異を吸収するコマンド定義
zinit snippet 'OMZ::lib/clipboard.zsh'
# zsh の補完を使いやすく設定する
zinit snippet 'OMZ::lib/completion.zsh'
zinit snippet 'OMZ::lib/compfix.zsh'
# Gitの補完と大量のエイリアスを定義する
zinit snippet 'OMZ::plugins/git/git.plugin.zsh'
# GitHub のレポジトリを管理するためのコマンドを定義する
zinit snippet 'OMZ::plugins/github/github.plugin.zsh'
# 非GNU系OSにインストールしたGNU系ツールをプリフィックスなしで使えるようにする
zinit snippet 'OMZ::plugins/gnu-utils/gnu-utils.plugin.zsh'
# .zshrc を zcompile してロードしてくれる src コマンドを定義する
zinit snippet 'OMZ::plugins/zsh_reload/zsh_reload.plugin.zsh'
# 作業ディレクトリに .env ファイルがあった場合に自動的にロードする
# zinit snippet 'OMZ::plugins/dotenv/dotenv.plugin.zsh'

# ----------------------------------------------------------------------------
# Zsh Supports
# ----------------------------------------------------------------------------

# コマンド補完
zinit wait lucid light-mode for \
    zsh-users/zsh-completions \
    jsforce/jsforce-zsh-completions

# コマンドハイライト
zinit wait lucid light-mode for atload'_zsh_highlight' 'zdharma/fast-syntax-highlighting'

# コマンドをサジェストする
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#55aa55,bg=white,underline"
zinit wait lucid light-mode for atload'_zsh_autosuggest_start' 'zsh-users/zsh-autosuggestions'

# ----------------------------------------------------------------------------
# Git Supports
# ----------------------------------------------------------------------------

# `git open` | クローンしたGit作業ディレクトリで、コマンド `git open` を実行するとブラウザでGitHubが開く
zinit wait lucid light-mode for paulirish/git-open

# ls の代替コマンド k でgithub連携あり
zinit wait lucid light-mode for pick'k.sh' 'supercrabtree/k'

# gitの拡張コマンド
zinit wait"2" lucid light-mode as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX" for 'tj/git-extras'

# git diif や tig の可読性を良くする（前提｜`HOMEBREW_PREFIX` に Homebrew のpathを設定している）
# zinit snippet --command "${HOMEBREW_PREFIX}/share/git-core/contrib/diff-highlight/diff-highlight"

# diff-so-fancy
# zinit ice wait'2' lucid as"program" pick"bin/git-dsf"
# zinit load zdharma/zsh-diff-so-fancy

# dandavision/delta
zinit wait lucid light-mode from"gh-r" as"program" mv"delta* -> delta" pick"delta/delta" for 'dandavison/delta'

# ----------------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------------

# history-search plugin
zinit load zdharma/history-search-multi-word

# エイリアスが使える際に表示する
export ZSH_PLUGINS_ALIAS_TIPS_TEXT='------ alias-tips: '
zinit wait lucid light-mode for 'djui/alias-tips'

# fzf - incremental search (load from binary file)
zinit wait lucid from"gh-r" as"program" for 'junegunn/fzf-bin'
# fzf を使ったウィジェットが複数バンドルされたもの
zinit wait'3' lucid light-mode for 'mollifier/anyframe'

# vim ｜ https://zdharma.github.io/zinit/wiki/Compiling-programs/
zinit wait'1' lucid light-mode as"program" atclone"rm -f src/auto/config.cache; ./configure" atpull"%atclone" make pick"src/vim" for 'vim/vim'

# 作業中のGitのルートディレクトリまでジャンプするコマンドを定義する
zinit wait'1' lucid light-mode for 'mollifier/cd-gitroot'
# ディレクトリをブックマークする
zinit wait'1' lucid light-mode for 'mollifier/cd-bookmark'

# 文章を複数キーワードで一括ハイライトする
zinit wait'3' lucid light-mode for pick"h.sh" 'paoloantinori/hhighlighter'

# fzf で絵文字を検索＆入力する
zinit wait'3' lucid light-mode for 'b4b4r07/emoji-cli'

# enhancd | cd上位互換
zinit wait lucid pick'init.sh' nocompile'!' for 'b4b4r07/enhancd'
export ENHANCD_FILTER=fzf:peco:fzy

# peco ｜ fuzzy-search
zinit wait lucid light-mode from"gh-r" as"command" mv"peco* -> peco" pick"peco/peco" for 'peco/peco'

# ripgrep ｜ grep上位互換
zinit wait'3' lucid light-mode from"gh-r" as"program" mv"ripgrep* -> rg" pick"rg/rg" for 'BurntSushi/ripgrep'

# exa ｜ ls上位互換
zinit wait lucid light-mode from"gh-r" as"program" mv"exa* -> exa" pick"exa/exa" for 'ogham/exa'

# LS_COLORS ｜ https://zdharma.github.io/zinit/wiki/LS_COLORS-explanation/
zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

# bat ｜ less上位互換
zinit wait lucid light-mode from"gh-r" as"program" mv"bat* -> bat" pick"bat/bat" for '@sharkdp/bat'

# fd ｜ find上位互換
zinit wait'3' lucid light-mode from"gh-r" as"program" mv"fd* -> fd" pick"fd/fd" for '@sharkdp/fd'

# ----------------------------------------------------------------------------
# Plugins: End
# ----------------------------------------------------------------------------

zinit cdreplay -q
