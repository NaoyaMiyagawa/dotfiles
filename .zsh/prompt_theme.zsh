if [[ ! -f /usr/local/bin/starship ]]; then
    command curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

eval "$(starship init zsh)"
