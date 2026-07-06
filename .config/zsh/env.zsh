##############################################################################
# Env
##############################################################################

# ls
export LS_COLORS="uu=37"
# bat
export BAT_THEME="TwoDark"
# claude
export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true
# obsidian wiki vault (per-machine location; override if the vault lives elsewhere)
export OBSIDIAN_VAULT="$HOME/Documents/Obsidian/main"

if is_osx; then
    export LDFLAGS="-L/opt/homebrew/opt/php@8.3/lib -L/opt/homebrew/opt/icu4c/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/php@8.3/include -I/opt/homebrew/opt/icu4c/include"
fi
