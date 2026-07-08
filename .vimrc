"##### Display settings #####
set number          "show line numbers
set expandtab       "use spaces for tabs
set laststatus=2    "set when the status line is shown in the bottom window
set title           "show the name of the file being edited
set ambiwidth=double
set showmatch       "show the matching bracket when one is typed
syntax on           "syntax highlighting
set tabstop=4       "set indent to 4 spaces
set autoindent      "auto indent
set wildmenu
set cursorline
set ruler

"##### Search settings #####
set hlsearch    "highlight all text matching the previous search pattern when one exists
set incsearch   "incremental search
set ignorecase  "search case-insensitively
set smartcase   "search case-sensitively when the search string contains uppercase letters
set wrapscan    "wrap around to the start when the search reaches the end

"##### vim-hybrid settings #####
set background=dark
let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1 " Remove this line if using the default palette.
let g:hybrid_use_iTerm_colors = 2
" let g:hybrid_custom_term_colors = 1
" let g:hybrid_reduced_contrast = 1 " Remove this line if using the default palette.
colorscheme hybrid

"disable vi compatibility (arrow keys work while in INSERT mode)
set nocompatible
"don't stop the cursor at the start/end of a line
set whichwrap=b,s,h,l,<,>,[,]
"specify what backspace can delete
" indent  : leading whitespace at the start of a line
" eol     : line break
" start   : characters before where insert mode started
set backspace=indent,eol,start
