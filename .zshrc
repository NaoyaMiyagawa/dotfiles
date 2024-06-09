# Q pre block. Keep at the top of this file.
# [[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
##############################################################################
# .zshrc
##############################################################################

# ----------------------------------------------------------------------------
# Load zsh settings
# ----------------------------------------------------------------------------

DOTFILES_PATH=$HOME/dotfiles

export XDG_CONFIG_HOME="$HOME/.config"

# source $DOTFILES_PATH/.zprofile
source $DOTFILES_PATH/.zsh/function.zsh
source $DOTFILES_PATH/.zsh/env.zsh
source $DOTFILES_PATH/.zsh/alias.zsh
source $DOTFILES_PATH/.zsh/path.zsh

# ----------------------------------------------------------------------------
# Load zinit
# ----------------------------------------------------------------------------

source $DOTFILES_PATH/.zsh/zinit/index.zsh

# ----------------------------------------------------------------------------
# Load prompt theme
# ----------------------------------------------------------------------------

source $DOTFILES_PATH/.zsh/prompt_theme.zsh

# ----------------------------------------------------------------------------
# New
# ----------------------------------------------------------------------------

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Q post block. Keep at the bottom of this file.
# [[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
