##############################################################################
# Plugins: Start
##############################################################################

# Articles
# - [Understanding zinit thoroughly](https://zenn.dev/xeres/articles/2021-05-05-understanding-zinit-syntax)

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
# - comment out because amazon q gives error (e.g. _zsh_highlight_widget_orig-s000-r305-accept-line:9: maximum nested...)
# zinit wait lucid light-mode atload'_zsh_autosuggest_start' for \
#     @'zsh-users/zsh-autosuggestions'
zinit light 'zsh-users/zsh-autosuggestions'

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
# zinit wait lucid pick'init.sh' nocompile'!' for 'babarot/enhancd'
# export ENHANCD_FILTER=fzf:peco:fzy

# NOTE: CLI binaries (peco, fzf, bat, eza, ripgrep, delta) are managed by
# Homebrew via the repo Brewfile (`make brew`), not zinit. Homebrew puts them
# on PATH for ALL shells — including non-interactive ones (agents, scripts,
# CI) — whereas zinit's `wait` turbo-loads them only after an interactive
# prompt renders, leaving them invisible to those shells.

if is_osx; then
    # AWS CLI v2 completion.
    # requires AWS CLI v2
    # Turbo-deferred: bashcompinit must run before the completer script loads
    # (atinit), and the aws registration after it (atload) — same order as the
    # old synchronous block, which errored with `command not found: compdef`
    # when reordered.
    zinit wait lucid light-mode \
        atinit'autoload -Uz bashcompinit && bashcompinit' \
        atload'complete -C /usr/local/bin/aws_completer aws' \
        for @'drgr33n/oh-my-zsh_aws2-plugin'
fi

# ----------------------------------------------------------------------------
# Plugins: End
# ----------------------------------------------------------------------------

zinit cdreplay -q
