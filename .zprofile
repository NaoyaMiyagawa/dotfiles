# Added by Kiro CLI
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="${PATH:+$PATH:}$HOME/.local/bin" ;; esac
# Q pre block. Keep at the top of this file.
##############################################################################
# .zprofile
##############################################################################

# Shared bootstrap for login shells and task runners.
: "${DOTFILES_PATH:=$HOME/dotfiles}"
source "$DOTFILES_PATH/.config/zsh/bootstrap.zsh"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

