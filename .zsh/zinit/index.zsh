# ----------------------------------------------------------------------------
# zinit 本体読み込み
#
# https://github.com/zdharma-continuum/zinit
# ----------------------------------------------------------------------------

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" &&
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" ||
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

### End of Zinit's installer chunk

source $DOTFILES_PATH/.zsh/zinit/_plugin.zsh

# # for "There are insecure files:" Error when executing "compaudit"
# # https://stackoverflow.com/questions/13762280/zsh-compinit-insecure-directories
# # [[ -e! compaudit ]] && compaudit | xargs chmod g-w
# # compaudit && compaudit | xargs chmod g-w
# if [ ! -e compaudit ]; then
#     # https://github.com/zsh-users/zsh-completions/issues/433
#     for f in $(compaudit); do
#         chown $(whoami):admin $f
#         chmod go-w $f
#     done
#     compaudit | xargs chown root
#     compaudit | xargs chmod go-w
# fi
