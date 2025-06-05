" Vim configuration following minimalist philosophy
" Based on Tim Pope's sensible.vim and community best practices

" =============================================================================
" CORE VIM SETTINGS
" =============================================================================

" Enable vim improvements
set nocompatible
filetype plugin indent on
syntax enable

" Essential behavior
set backspace=indent,eol,start
set hidden
set autoread
set complete-=i
set smarttab

" Command line and completion
set history=1000
set wildmenu
set wildmode=list:longest,full
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.DS_Store,*.db
set wildignore+=node_modules/**,*.git/**,*.hg/**,*.svn/**

" Enhanced file finding
set path+=**

" Display settings
set display=truncate
set scrolloff=1
set sidescrolloff=5
set ruler
set number
set relativenumber
set showcmd
set laststatus=2

" Session management
set sessionoptions-=options
set viewoptions-=options

" =============================================================================
" SEARCH AND NAVIGATION
" =============================================================================

" Smart searching
set incsearch
set hlsearch
set ignorecase
set smartcase

" Enhanced search patterns
nnoremap / /\v
vnoremap / /\v
nnoremap ? ?\v
vnoremap ? ?\v

" Clear search highlighting
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Keep search centered
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap * *zzzv
nnoremap # #zzzv

" Enhanced text movement
nnoremap j gj
nnoremap k gk

" =============================================================================
" LEADER MAPPINGS
" =============================================================================

let mapleader = " "
let maplocalleader = ","

" File operations (vim native)
nnoremap <leader>f :find *
nnoremap <leader>F :find **/*

" Buffer management
nnoremap <leader>b :buffer *
nnoremap <leader>B :sbuffer *
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
nnoremap <leader>d :bdelete<CR>

" Search operations
nnoremap <leader>s :vimgrep // **/*<Left><Left><Left><Left><Left><Left>
nnoremap <leader>S :grep -r "" .<Left><Left><Left>

" Quickfix and location lists
nnoremap <leader>q :copen<CR>
nnoremap <leader>Q :cclose<CR>
nnoremap <leader>l :lopen<CR>
nnoremap <leader>L :lclose<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap ]l :lnext<CR>
nnoremap [l :lprevious<CR>

" Quick toggle
nnoremap <silent> <leader>c :call ToggleQuickFix()<CR>


" =============================================================================
" FILE MANAGEMENT
" =============================================================================

" Persistent undo
if has('persistent_undo')
  set undofile
  set undodir=~/.vim/undo//
  if !isdirectory(expand('~/.vim/undo'))
    call mkdir(expand('~/.vim/undo'), 'p')
  endif
endif

" Backup and swap files
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" Create backup directories
for s:dir in [&backupdir, &directory]
  if !isdirectory(s:dir)
    call mkdir(s:dir, 'p')
  endif
endfor

" =============================================================================
" ABBREVIATIONS AND COMMANDS
" =============================================================================

" Common typo corrections
iabbrev teh the
iabbrev adn and
iabbrev seperate separate
iabbrev definately definitely
iabbrev recieve receive

" Command shortcuts
command! W w
command! Q q
command! WQ wq
command! Wq wq
command! Qa qa

" Configuration access
command! EditVimrc edit ~/src/nvim-nix/vimrc.vim
command! ReloadVimrc source ~/src/nvim-nix/vimrc.vim

" Utility commands
command! StripWhitespace call StripTrailingWhitespace()
command! -nargs=? -complete=help H vertical help <args>

" =============================================================================
" FUNCTIONS
" =============================================================================

function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction

function! StripTrailingWhitespace()
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction


" =============================================================================
" AUTOCOMMANDS
" =============================================================================

augroup vimrc
  autocmd!

  " Return to last cursor position
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif

  " Auto-balance windows on resize
  autocmd VimResized * wincmd =

  " Strip trailing whitespace on save
  autocmd BufWritePre *.py,*.js,*.ts,*.lua,*.nix,*.md,*.txt
    \ call StripTrailingWhitespace()

  " Enhanced buffer behavior
  autocmd FileType help nnoremap <buffer> q :q<CR>
  autocmd FileType qf nnoremap <buffer> q :q<CR>
  autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>

  " Language-specific settings
  autocmd FileType lisp,scheme,clojure setlocal lisp
  autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
  autocmd FileType html,css,javascript,typescript,json setlocal shiftwidth=2

augroup END

" =============================================================================
" MISCELLANEOUS
" =============================================================================

" Enhanced status line
set statusline=%f\ %h%w%m%r\ %=%{&ff}\ %{&fenc}\ %{&ft}\ %l,%c%V\ %P

" UTF-8 encoding
if &encoding ==# 'latin1' && has('gui_running')
  set encoding=utf-8
endif

" Load matchit for better % matching
packadd! matchit

" =============================================================================
" END OF CONFIGURATION
" =============================================================================
