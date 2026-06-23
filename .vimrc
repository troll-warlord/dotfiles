" === General ===
set nocompatible              " disable Vi compatibility
filetype plugin indent on     " filetype detection, plugins, indent rules
syntax enable                 " syntax highlighting

set encoding=utf-8
set backspace=indent,eol,start  " backspace over everything in insert mode
set mouse=a                     " enable mouse (scroll, click)

" system clipboard - pick one based on platform
if has('macunix')
    set clipboard=unnamed         " macOS
else
    set clipboard=unnamedplus     " Linux / WSL
endif

" === Appearance ===
set number                    " absolute line numbers
set relativenumber            " relative numbers on other lines (easy 5j / 10k jumps)
set cursorline                " highlight current line
set colorcolumn=100           " column ruler
set laststatus=2              " always show status bar
set showcmd                   " show partial commands bottom-right
set showmatch                 " briefly jump to matching bracket/paren
set scrolloff=8               " keep 8 lines of context above/below cursor

" === Search ===
set incsearch                 " jump to match as you type
set hlsearch                  " highlight all matches
set ignorecase                " case-insensitive...
set smartcase                 " ...unless pattern contains uppercase
nnoremap <Esc><Esc> :nohlsearch<CR>

" === Indentation defaults (4 spaces) ===
set expandtab                 " spaces instead of tabs
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

" === Per-filetype indentation ===
augroup filetype_indent
    autocmd!
    " 2-space: YAML, JSON, HTML, CSS, JS/TS
    autocmd FileType yaml,json              setlocal tabstop=2 shiftwidth=2 softtabstop=2
    autocmd FileType html,css               setlocal tabstop=2 shiftwidth=2 softtabstop=2
    autocmd FileType javascript,typescript  setlocal tabstop=2 shiftwidth=2 softtabstop=2
    " 4-space: Python, shell (PEP 8 / common convention)
    autocmd FileType python,sh,bash         setlocal tabstop=4 shiftwidth=4 softtabstop=4
augroup END

" === Whitespace visibility ===
set list
set listchars=tab:>\ ,trail:.,nbsp:+   " mark tabs, trailing spaces, non-breaking spaces

" === Splits ===
set splitright                " vertical splits open right
set splitbelow                " horizontal splits open below

" === Files ===
set noswapfile
set nobackup
set undofile                  " persist undo history across sessions
set undodir=~/.vim/undodir    " mkdir -p ~/.vim/undodir

" === Completion / wildmenu ===
set wildmenu
set wildmode=list:longest
set completeopt=menuone,noselect

" === Performance ===
set updatetime=300            " faster CursorHold (default 4000ms)
set timeoutlen=500            " key sequence timeout