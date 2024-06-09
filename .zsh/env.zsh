##############################################################################
# Env
##############################################################################

export HISTTIMEFORMAT='%Y%m%d %T%z | '
export EDITOR=vim

# ls
export LS_COLORS="uu=37"
# bat
export BAT_THEME="TwoDark"

if is_osx; then
    export HOMEBREW_PREFIX="/usr/local"

    export LDFLAGS="-L/opt/homebrew/opt/php@8.3/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/php@8.3/include"
    export LDFLAGS="-L/opt/homebrew/opt/icu4c/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/icu4c/include"
fi
