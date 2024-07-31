if ! command -v starship &>/dev/null; then
    if is_osx; then
        brew install starship
    else
        command curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
fi

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
