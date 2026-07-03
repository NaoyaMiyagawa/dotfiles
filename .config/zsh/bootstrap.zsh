##############################################################################
# Bootstrap
##############################################################################

# Shared shell bootstrap for login and interactive shells. Both .zprofile and
# .zshrc source this; the guard makes the second source a no-op. Deliberately
# NOT exported: child shells don't inherit functions, so they must re-run it.
[[ -n "${DOTFILES_ZSH_BOOTSTRAPPED:-}" ]] && return
DOTFILES_ZSH_BOOTSTRAPPED=1

: "${DOTFILES_PATH:=$HOME/dotfiles}"

source "$DOTFILES_PATH/.config/zsh/function.zsh"
source "$DOTFILES_PATH/.config/zsh/env.zsh"

# restore last directory for this cmux workspace
cmux-restore-dir
