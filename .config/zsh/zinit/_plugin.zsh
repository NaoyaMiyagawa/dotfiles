##############################################################################
# Plugins: Start
##############################################################################

# Articles
# - [zinit をしっかりと理解する](https://zenn.dev/xeres/articles/2021-05-05-understanding-zinit-syntax)

# Modifiers
# - wait : lazy load. it's called 'Turbo mode'. wait = wait"0"
# - lucid : not to show loading message
# - blockf : block plugins to modify $fpath. better to use with plugins of completion

# Syntax
# - load : load a plugin with tracking
# - light : load a plugin without tracking. faster
# - snippet : load a snippet of code
# - ice : apply modifiers for the following plugin load once
# - for : apply modifiers for the following multiple plugins

# 補完をリセット
autoload -Uz compinit && compinit

# ----------------------------------------------------------------------------
# Zsh Supports
# ----------------------------------------------------------------------------

# - zsh-users/zsh-completions                       : provide additional completion definitions
# - zsh-users/zsh-autosuggestions                   : suggest commands as you type based on history
# - zdharma-continuum/fast-syntax-highlighting      : syntax highlighting
# - OMZ::lib/clipboard.zsh                          : absorb clipboard differences between OSs
# - OMZ::lib/completion.zsh                         : make zsh completions easier to use
# - OMZ::lib/compfix.zsh                            : make zsh completions easier to use
# - OMZ::plugins/gnu-utils/gnu-utils.plugin.zsh     : make non-GNU OSes use GNU tools without prefix
# - OMZ::plugins/dotenv/dotenv.plugin.zsh           : automatically load .env files if they exist

zinit wait lucid blockf light-mode for \
    @'zsh-users/zsh-completions' \
    @'zdharma-continuum/fast-syntax-highlighting' \
    @'OMZ::lib/clipboard.zsh' \
    @'OMZ::plugins/gnu-utils/gnu-utils.plugin.zsh' \
    @'OMZ::plugins/dotenv/dotenv.plugin.zsh'

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#55aa55,bg=white,underline"
zinit wait lucid light-mode atload'_zsh_autosuggest_start' for \
    @'zsh-users/zsh-autosuggestions'

# ----------------------------------------------------------------------------
# Git Supports
# ----------------------------------------------------------------------------

# Alias
# - OMZ::plugins/git/git.plugin.zsh                 : define git completions and a ton of aliases
# - OMZ::plugins/github/github.plugin.zsh           : define commands to manage GitHub repositories

zinit wait lucid blockf light-mode for \
    @'OMZ::plugins/git/git.plugin.zsh' \
    @'OMZ::plugins/github/github.plugin.zsh'

# Tools
# - paulirish/git-open                              : `git open` open repository in browser
# - mollifier/cd-gitroot                            : `cd-gitroot` jump to the root directory of the current repository

zinit wait'1' lucid light-mode for \
    @'paulirish/git-open' \
    @'mollifier/cd-gitroot'

# dandavision/delta
zinit ice wait'1' lucid from"gh-r" as"program" mv"delta* -> delta" pick"delta/delta"
zinit light 'dandavison/delta'

# ----------------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------------

# - zdharma-continuum/history-search-multi-word     : provide additional completion definitions
# - zsh-users/zsh-autosuggestions                   : suggest commands as you type based on history
# - mollifier/cd-bookmark                           : bookmark directories

# history-search plugin
zinit wait lucid for \
    @'zdharma-continuum/history-search-multi-word' \
    @'djui/alias-tips' \
    @'mollifier/cd-bookmark'

export ZSH_PLUGINS_ALIAS_TIPS_TEXT='----- alias-tips: '

# enhancd | enhanced `cd`
zinit wait lucid pick'init.sh' nocompile'!' for 'babarot/enhancd'
export ENHANCD_FILTER=fzf:peco:fzy

# peco ｜ fuzzy-search
zinit wait lucid from"gh-r" as"program" pick"*/peco" for @'peco/peco'

# fzf ｜ fuzzy-search
zinit wait lucid from"gh-r" as"program" for @'junegunn/fzf'

# bat ｜ enhanced `less`
zinit wait lucid light-mode as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat" for @'sharkdp/bat'

# rust, cargo | required for rust based plugins
zinit wait lucid light-mode for @'zdharma-continuum/zinit-annex-rust'

# eza | Rust based reinforced ls/exa https://github.com/eza-community/eza
zinit wait lucid light-mode from"gh-r" as"program" mv"eza* -> eza" pick"eza/eza" for @'eza-community/eza'

# ripgrep ｜ enhanced `grep`
zinit wait'3' lucid light-mode from"gh-r" as"program" mv"ripgrep* -> rg" pick"rg/rg" for @'BurntSushi/ripgrep'

# asdf
zinit wait lucid light-mode for @'asdf-vm/asdf'

if is_osx; then
    # AWS CLI v2の補完。
    # 要 AWS CLI v2
    # この順序で記述しないと `complete:13: command not found: compdef` のようなエラーになるので注意
    autoload bashcompinit && bashcompinit
    source ~/.zinit/plugins/drgr33n---oh-my-zsh_aws2-plugin/aws2_zsh_completer.sh
    complete -C '/usr/local/bin/aws_completer' aws
    zinit light drgr33n/oh-my-zsh_aws2-plugin
fi

# ----------------------------------------------------------------------------
# Plugins: End
# ----------------------------------------------------------------------------

zinit cdreplay -q
