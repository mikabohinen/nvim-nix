" vimrc.vim

" Section: Bootstrap and Environment Detection
" =============================================================================

set nocompatible
filetype plugin indent on
syntax enable

" Section: File Management and Directories
" =============================================================================

" XDG-compliant directory setup
if !empty($XDG_DATA_HOME)
  let s:data_home = substitute($XDG_DATA_HOME, '/$', '', '') . '/nvim/'
else
  let s:data_home = expand('~/.local/share/nvim/')
endif

" Persistent undo with directory management
if has('persistent_undo')
  set undofile
  let &undodir = s:data_home . 'undo//'
  if !isdirectory(&undodir)
    try
      call mkdir(&undodir, 'p')
    catch
      echohl ErrorMsg | echo "Failed to create undo directory: " . &undodir | echohl None
    endtry
  endif
endif

" Backup and swap with XDG compliance
set backup
let &backupdir = s:data_home . 'backup//'
let &directory = s:data_home . 'swap//'

for s:dir in [&backupdir, &directory]
  if !isdirectory(s:dir)
    try
      call mkdir(s:dir, 'p')
    catch
      echohl ErrorMsg
      echo "Failed to create directory: " . s:dir
      echohl None
    endtry
  endif
endfor

" Section: Functions
" =============================================================================

" rg is guaranteed to be available since it's packaged with nvim.nix
function! FuzzyFindFiles(cmdarg, cmdcomplete)
    let fnames = systemlist('rg --files --hidden --color=never --glob="!.git"')
    if empty(a:cmdarg)
        return fnames
    else
        return matchfuzzy(fnames, a:cmdarg)
    endif
endfunction

function! StripTrailingWhitespace()
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction

" Section: Search, Navigation, and Tags
" =============================================================================

" Enhanced search settings
set incsearch
set hlsearch
set ignorecase
set smartcase

" Better find and include settings
set findfunc=FuzzyFindFiles
set include=
set tags=./tags;

" Clear search highlighting
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Section: Display and Interface
" =============================================================================

set display=truncate
set scrolloff=1
set sidescrolloff=5
set ruler
set splitright
set number
set relativenumber
set showcmd
set confirm
set visualbell
set laststatus=2
set lazyredraw
set listchars=tab:▸\ ,trail:·,extends:❯,precedes:❮

" Section: File Browser
" =============================================================================

" Netrw improvements
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_keepdir = 0

" Section: Command Line and Completion
" =============================================================================

set history=1000
set wildmenu
set wildmode=longest:lastused,full
set wildoptions=tagfile,pum
set wildignore=*.o,*.obj

" Section: Editing text and indent
" =============================================================================

set backspace=indent,eol,start
set complete-=i
set infercase
set virtualedit=block
set shiftround
set smarttab
set autoread
set autowrite

if has('vim_starting')
  set tabstop=8
  set shiftwidth=0 softtabstop=-1
  set autoindent
  set omnifunc=syntaxcomplete#Complete
  set completefunc=syntaxcomplete#Complete
endif

" Section: Non-Leader Mappings
" =============================================================================

" Fix the & mapping
nnoremap & :&&<CR>
xnoremap & :&&<CR>

" Edit the current directory
nnoremap <silent> - :e %:h<CR>

" Quickfix and location list navigation
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap ]l :lnext<CR>
nnoremap [l :lprevious<CR>

" Buffer navigation
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
nnoremap [B :bfirst<CR>
nnoremap ]B :blast<CR>

" Section: Leader Mappings
" =============================================================================

let mapleader = " "
let maplocalleader = ","

" Section: External Commands and Integration
" =============================================================================

" grep settings
set grepformat=%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f\ \ %l%m
set grepprg=rg\ --vimgrep\ --hidden\ -g\ '!.git/*'

" Section: Commands
" =============================================================================

" Utility commands
command! StripWhitespace call StripTrailingWhitespace()

" Diagnostic commands
if has('nvim')
  command! DiagFloat lua vim.diagnostic.open_float()
  command! DiagQF lua vim.diagnostic.setqflist({open = true})
  command! DiagLoc lua vim.diagnostic.setloclist({open = true})
  command! DiagToggle lua vim.diagnostic.config({virtual_text = not vim.diagnostic.config().virtual_text})
  command! LspRestart lua vim.lsp.stop_client(vim.lsp.get_active_clients()); edit
  command! LspInfo lua vim.cmd('LspInfo')
endif

" Section: Autocommands
" =============================================================================

augroup vimrc
  autocmd!

  " Return to last cursor position
  autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

  " Language-specific settings
  autocmd FileType lisp,scheme,clojure setlocal lisp shiftwidth=2
  autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
  autocmd FileType html,css,javascript,typescript,json,nix,vim setlocal shiftwidth=2

augroup END

augroup LispAutoPair
  autocmd!
  autocmd FileType lisp,scheme,clojure inoremap <buffer> ( ()<Left>
augroup END

" Section: Final Setup
" =============================================================================

" Colorscheme
colorscheme habamax

" Better color detection
if $TERM !~? 'linux' && &t_Co == 8
  set t_Co=16
endif

" Load essential plugins
packadd! matchit
packadd! cfilter

" Simple status line - encourages active awareness over passive monitoring
set statusline=%f\ %h%w%m%r\ %=%{&ff}\ %{&fenc}\ %{&ft}\ %l,%c%V\ %P

" Session management
set sessionoptions=blank,buffers,folds,help,tabpages,winsize,terminal,sesdir,globals
set viewoptions-=options

" vim:set et sw=2 foldmethod=exp
