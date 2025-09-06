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

" Persistent undo with better directory management
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

function! FuzzyFindFunc(cmdarg, cmdcomplete)
    return systemlist("fd --hidden . \| fzf --filter='" 
        \.. a:cmdarg .. "'")
endfunction

function! FuzzyFilterQf(...) abort
    call setqflist(matchfuzzy(getqflist(), join(a:000, " "), {'key': 'text'}))
endfunction

function! StripTrailingWhitespace()
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction

function! LspDiagnosticCounts()
  if !has('nvim')
    return ''
  endif
  
  let l:errors = luaeval('#vim.diagnostic.get(0, {severity = vim.diagnostic.severity.ERROR})')
  let l:warnings = luaeval('#vim.diagnostic.get(0, {severity = vim.diagnostic.severity.WARN})')
  let l:hints = luaeval('#vim.diagnostic.get(0, {severity = vim.diagnostic.severity.HINT})')
  
  let l:result = ''
  if l:errors > 0
    let l:result .= ' E:' . l:errors
  endif
  if l:warnings > 0
    let l:result .= ' W:' . l:warnings
  endif
  if l:hints > 0
    let l:result .= ' H:' . l:hints
  endif
  
  return l:result
endfunction


" Section: Search, Navigation, and Tags
" =============================================================================

" Enhanced search settings
set incsearch
set hlsearch
set ignorecase
set smartcase

" Better find and include settings
set findfunc=FuzzyFindFunc
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

" Section: Command Line and Completion
" =============================================================================

set history=1000
set wildmenu
set wildmode=longest:lastused,full
set wildoptions=tagfile
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.DS_Store,*.db
set wildignore+=node_modules/**,*.git/**,*.hg/**,*.svn/**

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

" Section: Non Leader Mappings
" =============================================================================

" Window movement
nnoremap <C-J> <C-w>w
nnoremap <C-K> <C-w>W

" Easy expansion of current directory
cnoremap <expr> %% getcmdtype () == ':' ? expand('%:h').'/' : "%%"

" Fix the & mapping
nnoremap & :&&<CR>
xnoremap & :&&<CR>

" Section: Leader Mappings
" =============================================================================

let mapleader = " "
let maplocalleader = ","

" Enhanced search patterns
nnoremap <leader>/ /\v
vnoremap <leader>/ /\v
nnoremap <leader>? ?\v
vnoremap <leader>? ?\v

" File operations
nnoremap <leader><leader> :find<space>
nnoremap <leader>ff :find<space>
nnoremap <leader>fF :vert sf<space>

" Buffer management
nnoremap <leader>fb :buffer<space>
nnoremap <leader>fB :sbuffer<space>
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
nnoremap [B :bfirst<CR>
nnoremap ]B :blast<CR>
nnoremap <leader>bd :bdelete<CR>

" Search operations
nnoremap <leader>fw :grep ''<Left>
nnoremap <leader>fW :grep <C-R><C-W><cr>
nnoremap <leader>fs :lgrep ''<Left>
nnoremap <leader>fS :lgrep <C-R><C-W><cr>
nnoremap <leader>fc :Cfilter<space>
nnoremap <leader>fz :Cfuzzy<space>

" Search utilities
cnoremap <C-space> .*
cnoremap <A-9> \(
cnoremap <A-0> \)

" Quickfix and location lists
nnoremap <leader>qq :copen<CR>
nnoremap <leader>qQ :cclose<CR>
nnoremap <leader>qo :colder<space>
nnoremap <leader>qn :cnewer<space>
nnoremap <leader>ll :lopen<CR>
nnoremap <leader>lL :lclose<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap ]l :lnext<CR>
nnoremap [l :lprevious<CR>

" LSP mappings
nnoremap <leader>cR :LspRestart<CR>
nnoremap <leader>cI :LspInfo<CR>

" Section: External Commands and Integration
" =============================================================================

" grep settings
set grepformat=%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f\ \ %l%m
set grepprg=rg\ --vimgrep\ --hidden\ -g\ '!.git/*'

" Section: Commands
" =============================================================================

" Fuzzy finding
command! -nargs=1 Cfuzzy call FuzzyFilterQf(<f-args>)

" Utility commands
command! StripWhitespace call StripTrailingWhitespace()
command! -nargs=? -complete=help H vertical help <args>
command! -nargs=* -complete=file O call s:Open(<f-args>)

" Diagnostic commands
if has('nvim')
  command! DiagnosticsQF lua vim.diagnostic.setqflist({open = true})
  command! DiagnosticsLoc lua vim.diagnostic.setloclist({open = true})
  command! DiagnosticsAll lua vim.diagnostic.setqflist({open = true, title = 'All Project Diagnostics'})
  command! DiagnosticsErrors lua vim.diagnostic.setqflist({severity = vim.diagnostic.severity.ERROR, open = true, title = 'Project Errors'})
  command! DiagnosticsWarnings lua vim.diagnostic.setqflist({severity = vim.diagnostic.severity.WARN, open = true, title = 'Project Warnings'})
  command! DiagnosticsToggleVirtualText lua vim.diagnostic.config({virtual_text = not vim.diagnostic.config().virtual_text})
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

  " Auto-balance windows on resize
  autocmd VimResized * wincmd =

  " Strip trailing whitespace on save
  autocmd BufWritePre *.py,*.js,*.ts,*.lua,*.nix,*.md,*.txt
    \ call StripTrailingWhitespace()

  " Smart commenting (basic version)
  autocmd FileType vim setlocal commentstring=\"\ %s
  autocmd FileType vim setlocal keywordprg=:help |
      \ if &foldmethod !=# 'diff' | setlocal foldmethod=expr foldlevel=1 | endif |
      \ setlocal foldexpr=getline(v:lnum)=~'^\"\ Section:'?'>1':'='
  autocmd FileType python,bash,sh,zsh setlocal commentstring=#\ %s
  autocmd FileType nix setlocal commentstring=#\ %s
  autocmd FileType haskell setlocal commentstring=--\ %s
  autocmd FileType java setlocal commentstring=//\ %s

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

" Load matchit for better % matching and cfilter for fuzzy filtering quickfix
" list
packadd! matchit
packadd! cfilter

" Better status line
set statusline=%f\ %h%w%m%r%{LspDiagnosticCounts()}\ %=%{&ff}\ %{&fenc}\ %{&ft}\ %l,%c%V\ %P

" Session management
set sessionoptions=blank,buffers,folds,help,tabpages,winsize,terminal,sesdir,globals
set viewoptions-=options

" =============================================================================
" END OF CONFIGURATION
" =============================================================================

" vim:set et sw=2 foldmethod=exp
