# ##############################################################################
# .zshrc
##############################################################################
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# ----------------------------------------------------------------------------
# Load zsh settings
# ----------------------------------------------------------------------------

DOTFILES_PATH=$HOME/dotfiles

# macOS /etc/zshrc resets interactive history defaults, so reload ours here.
source $DOTFILES_PATH/.zshenv
source $DOTFILES_PATH/.config/zsh/bootstrap.zsh
source $DOTFILES_PATH/.config/zsh/alias.zsh

# ----------------------------------------------------------------------------
# General

# Emacs mode | Enable Ctrl+A for line start and Ctrl+E for line end in the terminal
bindkey -e
bindkey "[D" backward-word
bindkey "[C" forward-word
bindkey '^u' peco-cdr
# # Enable Alt+Left/Right to navigate through words
# bindkey "\e\e[D" backward-word
# bindkey "\e\e[C" forward-word

## If a command takes 3 seconds or more to run,
## automatically display timing statistics.
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
#setopt correct            # Handle spelling mistakes

# ----------------------------------------------------------------------------
# History

# History | Various settings
# setopt append_history          # Append to the history file instead of overwriting it, useful when using multiple zsh sessions
setopt EXTENDED_HISTORY       # Record start and end times
setopt auto_pushd             # Run pushd automatically when using cd
setopt extended_history       # Also record timestamps in $HISTFILE
setopt hist_expand            # Automatically expand history during completion
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # Do not keep duplicate commands in history
setopt hist_ignore_dups       # Do not record duplicates
setopt hist_ignore_space      # Exclude command lines starting with a space from history
setopt hist_no_store          # Do not store the history command itself in history
setopt hist_reduce_blanks     # Compress extra spaces before saving
setopt hist_save_no_dups      # Remove older duplicates when saving duplicate commands
setopt hist_verify            # Allow editing after recalling a history entry and before execution
setopt histignorealldups      # Do not show duplicates in history
setopt inc_append_history     # Append history incrementally
setopt interactive_comments   # Treat text after # as a comment even on the command line
setopt no_beep                # Disable the beep sound
setopt print_eight_bit        # Allow display of Japanese filenames
setopt share_history          # Share history across other terminals

# ----------------------------------------------------------------------------
# Search

# Search | Fuzzy search settings
zstyle ":history-search-multi-word" page-size "30"                   # Number of displayed lines
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold" # Style for matching text
zstyle ":plugin:history-search-multi-word" active "bg=blue"          # Style for the selected line
# bindkey "^R" history-incremental-search-backward
# bindkey "^S" history-incremental-search-forward

# ----------------------------------------------------------------------------
# Reset completion
# ----------------------------------------------------------------------------

autoload -Uz compinit
compinit

# ----------------------------------------------------------------------------
# Load zinit
# ----------------------------------------------------------------------------

source $DOTFILES_PATH/.config/zsh/zinit/index.zsh
source $DOTFILES_PATH/.config/zsh/zinit/_plugin.zsh

# ----------------------------------------------------------------------------
# Load prompt theme
# ----------------------------------------------------------------------------

source $DOTFILES_PATH/.config/zsh/prompt_theme.zsh

# ----------------------------------------------------------------------------
# New
# ----------------------------------------------------------------------------

# Load tmux if it's the first shell
# if [ $SHLVL = 1 ]; then
#     if command -v tmux &>/dev/null; then
#         tmux attach -t default || tmux new -s default
#     fi
# fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Q post block. Keep at the bottom of this file.

# pnpm
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"


# opencode
export PATH=/Users/miyagawa/.opencode/bin:$PATH

# cmux: clear sidebar state when shell exits so stale Claude info doesn't linger
_cmux_shell_exit() {
  [ -n "$CMUX_SURFACE_ID" ] && command -v cmux >/dev/null 2>&1 && cmux claude-hook stop 2>/dev/null || true
}
add-zsh-hook zshexit _cmux_shell_exit
