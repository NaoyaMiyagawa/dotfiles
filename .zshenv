##############################################################################
# .zshenv
#
# Reference:
# - https://www.m3tech.blog/entry/dotfiles-bonsai#こだわり-ホームディレクトリの掃除
# - https://github.com/NagayamaRyoga/dotfiles/blob/main/config/zsh/.zshenv
##############################################################################

# ----------------------------------------------------------------------------
# XDG Base Directory Specification
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# ----------------------------------------------------------------------------

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ----------------------------------------------------------------------------
# History
# ----------------------------------------------------------------------------

# zsh
export HISTFILE="$XDG_STATE_HOME/zsh_history"

# ts-node | https://github.com/TypeStrong/ts-node#ts_node_history
export TS_NODE_HISTORY="$XDG_STATE_HOME/ts_node_repl_history"

# node | https://nodejs.org/api/repl.html#environment-variable-options
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"

export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"

export MYSQL_HISTFILE="$XDG_STATE_HOME/mysql_history"

export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"

export HISTTIMEFORMAT='%Y%m%d %T%z | '
export EDITOR=vim
