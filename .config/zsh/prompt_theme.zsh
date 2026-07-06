if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    # Never install as a shell-startup side effect; starship is in the Brewfile.
    print -u2 "prompt_theme: starship not found — run 'make brew' in ~/dotfiles"
fi
