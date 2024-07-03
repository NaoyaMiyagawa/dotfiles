# Q pre block. Keep at the top of this file.
# [[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
##############################################################################
# .zshrc
##############################################################################

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

# 初回シェル時のみ tmux実行
if [ $SHLVL = 1 ]; then
    tmux attach -t default || tmux new -s default
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Q post block. Keep at the bottom of this file.
# [[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
