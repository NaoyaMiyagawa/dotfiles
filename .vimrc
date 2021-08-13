"#####表示設定#####
set number          "行番号を表示する
set expandtab       "タブに空白を使う
set laststatus=2    "最下ウィンドウにいつステータス行が表示されるかを設定する
set title           "編集中のファイル名を表示
set ambiwidth=double
set showmatch       "括弧入力時の対応する括弧を表示
syntax on           "コードの色分け
set tabstop=4       "インデントをスペース4つ分に設定
set autoindent      "オートインデント
set wildmenu
set cursorline
set ruler

"#####検索設定#####
set hlsearch    "前回の検索パターンが存在するとき、それにマッチするテキストを全て強調表示する。
set incsearch   "インクリメンタルサーチ
set ignorecase  "大文字/小文字の区別なく検索する
set smartcase   "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan    "検索時に最後まで行ったら最初に戻る

"#####vim-hybrid設定#####
set background=dark
let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1 " Remove this line if using the default palette.
let g:hybrid_use_iTerm_colors = 2
" let g:hybrid_custom_term_colors = 1
" let g:hybrid_reduced_contrast = 1 " Remove this line if using the default palette.
colorscheme hybrid

"viとの互換性を無効にする(INSERT中にカーソルキーが有効になる)
set nocompatible
"カーソルを行頭，行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]
"BSで削除できるものを指定する
" indent  : 行頭の空白
" eol     : 改行
" start   : 挿入モード開始位置より手前の文字
set backspace=indent,eol,start
