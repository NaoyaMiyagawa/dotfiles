# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
# ##############################################################################
# .zshrc
##############################################################################

# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# ----------------------------------------------------------------------------
# Load zsh settings
# ----------------------------------------------------------------------------

DOTFILES_PATH=$HOME/dotfiles

source $DOTFILES_PATH/.zshenv
source $DOTFILES_PATH/.config/zsh/function.zsh
source $DOTFILES_PATH/.config/zsh/env.zsh
source $DOTFILES_PATH/.config/zsh/alias.zsh
source $DOTFILES_PATH/.config/zsh/path.zsh

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

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
# Q post block. Keep at the bottom of this file.
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
