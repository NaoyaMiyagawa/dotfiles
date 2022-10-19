##############################################################################
# .zshrc
##############################################################################

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# ----------------------------------------------------------------------------
# Load zsh settings
# ----------------------------------------------------------------------------

DOTFILES_PATH=$HOME/dotfiles

source $DOTFILES_PATH/.zprofile
source $DOTFILES_PATH/.zsh/function.zsh
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

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
