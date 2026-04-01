##############################################################################
# Bootstrap
##############################################################################

# Shared shell bootstrap for login and interactive shells.
: "${DOTFILES_PATH:=$HOME/dotfiles}"

source "$DOTFILES_PATH/.config/zsh/function.zsh"
source "$DOTFILES_PATH/.config/zsh/env.zsh"
