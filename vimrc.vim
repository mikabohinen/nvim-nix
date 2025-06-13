" vimrc.vim

" Vim configuration following a minimalist philosophy

" Section: Bootstrap and Environment Detection
" =============================================================================

set nocompatible
filetype plugin indent on
syntax enable

" Environment detection for cross-platform compatibility
let s:is_windows = has('win32') || has('win64')
let s:is_mac = has('mac') || has('macunix')
let s:is_gui = has('gui_running')
let s:has_terminal = exists(':terminal')

" Section: File Management and Directories
" =============================================================================

" XDG-compliant directory setup
if !empty($XDG_DATA_HOME)
  let s:data_home = substitute($XDG_DATA_HOME, '/$', '', '') . '/nvim/'
elseif s:is_windows
  let s:data_home = expand('~/AppData/Local/nvim/')
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

" Section: Search, Navigation, and Tags
" =============================================================================

" Enhanced search settings
set incsearch
set hlsearch
set ignorecase
set smartcase

" Better path and include settings
set path+=**
set include=
set tags=./tags;

" Clear search highlighting
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Keep search centered
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap * *zzzv
nnoremap # #zzzv

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

" List characters
if (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8') && v:version >= 700
  let &listchars = "tab:\u21e5\u00b7,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
  let &fillchars = "vert:\u250b,fold:\u00b7"
else
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<
endif

" Section: Command Line and Completion
" =============================================================================

set history=1000
set wildmenu
set wildmode=longest:longest,full
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
nnoremap <leader><leader> :find *
nnoremap <leader>ff :find *
nnoremap <leader>fF :find **/*

" Buffer management
nnoremap <leader>fb :buffer *
nnoremap <leader>fB :sbuffer *
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
nnoremap [B :bfirst
nnoremap ]B :blast
nnoremap <leader>bd :bdelete<CR>

" Search operations
nnoremap <leader>fw :grep "" .<Left><Left><Left>
nnoremap <leader>fW :vimgrep // **/*<Left><Left><Left><Left><Left><Left>
nnoremap <leader>fs :lgrep "" .<Left><Left><Left>
nnoremap <leader>fS :lvimgrep // **/*<Left><Left><Left><Left><Left><Left>

" Quickfix and location lists
nnoremap <leader>q :copen<CR>
nnoremap <leader>Q :cclose<CR>
nnoremap <leader>l :lopen<CR>
nnoremap <leader>L :lclose<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap ]l :lnext<CR>
nnoremap [l :lprevious<CR>

" Global nix mappings under <leader>n
nnoremap <leader>nr :NixRun
nnoremap <leader>nb :NixBuild
nnoremap <leader>ns :NixShell<CR>
nnoremap <leader>nu :NixUpdate<CR>
nnoremap <leader>nc :NixCheck<CR>
nnoremap <leader>ni :NixInfo<CR>
nnoremap <leader>nS :NixSearch
nnoremap <leader>ne :NixEval
nnoremap <leader>nC :NixClean<CR>

" Quick file access
nnoremap <leader>ef :EditFlake<CR>
nnoremap <leader>ed :EditDefault<CR>

" LSP mappings
nnoremap <leader>cR :LspRestart<CR>
nnoremap <leader>cI :LspInfo<CR>

" Section: External Commands and Integration
" =============================================================================

" Enhanced grep settings
set grepformat=%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f\ \ %l%m
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case
elseif executable('ag')
  set grepprg=ag\ --vimgrep
elseif has('unix')
  set grepprg=grep\ -rn\ $*\ /dev/null
endif

" Section: Abbreviations and Commands
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

" Section: Functions
" =============================================================================

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

function! s:Open(...) abort
  let cmd = s:is_windows ? 'start' : executable('xdg-open') ? 'xdg-open' : 'open'
  let args = a:0 ? copy(a:000) : [expand('%:p')]
  call map(args, 'shellescape(v:val)')
  return system(cmd . ' ' . join(args, ' '))
endfunction

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

augroup nix_mappings
  autocmd!

  " Nix-specific mappings for .nix files
  autocmd FileType nix nnoremap <buffer> <localleader>r :NixRun<CR>
  autocmd FileType nix nnoremap <buffer> <localleader>b :NixBuild<CR>
  autocmd FileType nix nnoremap <buffer> <localleader>c :NixCheck<CR>
  autocmd FileType nix nnoremap <buffer> <localleader>u :NixUpdate<CR>
  autocmd FileType nix nnoremap <buffer> <localleader>s :NixShell<CR>
  autocmd FileType nix nnoremap <buffer> <localleader>i :NixInfo<CR>

  " Global nix development mappings
  autocmd FileType nix nnoremap <buffer> <leader>ef :EditFlake<CR>
  autocmd FileType nix nnoremap <buffer> <leader>ed :EditDefault<CR>
augroup END

augroup LispAutoPair
  autocmd!
  autocmd FileType lisp,scheme,clojure inoremap <buffer> ( ()<Left>
augroup END

" =============================================================================
" NIX INTEGRATION COMMANDS
" =============================================================================

" Helper function to run nix commands with proper output
function! s:RunNixCommand(cmd, args, async)
  let l:full_cmd = 'nix ' . a:cmd . ' ' . a:args

  if a:async && (has('nvim') || has('job'))
    " Async execution for long-running commands
    echo '🚀 Running: ' . l:full_cmd

    if has('nvim')
      call jobstart(l:full_cmd, {
        \ 'on_stdout': function('s:NixJobOutput'),
        \ 'on_stderr': function('s:NixJobError'),
        \ 'on_exit': function('s:NixJobExit'),
        \ 'stdout_buffered': v:false,
        \ 'stderr_buffered': v:false,
        \ })
    else
      " Vim 8+ job support
      call job_start(l:full_cmd, {
        \ 'out_cb': function('s:NixJobOutputVim'),
        \ 'err_cb': function('s:NixJobErrorVim'),
        \ 'exit_cb': function('s:NixJobExitVim'),
        \ })
    endif
  else
    " Synchronous execution
    echo '⏳ Executing: ' . l:full_cmd
    let l:result = system(l:full_cmd)

    if v:shell_error == 0
      if !empty(l:result)
        echo l:result
      endif
      echo '✓ ' . l:full_cmd . ' completed'
    else
      echohl ErrorMsg
      echo '✗ ' . l:full_cmd . ' failed:'
      echo l:result
      echohl None
    endif
  endif
endfunction

" Job callback functions for Neovim
function! s:NixJobOutput(job_id, data, event)
  for line in a:data
    if !empty(line)
      echo line
    endif
  endfor
endfunction

function! s:NixJobError(job_id, data, event)
  for line in a:data
    if !empty(line)
      echohl ErrorMsg | echo line | echohl None
    endif
  endfor
endfunction

function! s:NixJobExit(job_id, code, event)
  if a:code == 0
    echo '✓ Nix command completed successfully'
  else
    echohl ErrorMsg
    echo '✗ Nix command failed with code ' . a:code
    echohl None
  endif
endfunction

" Job callback functions for Vim 8+
function! s:NixJobOutputVim(channel, msg)
  echo a:msg
endfunction

function! s:NixJobErrorVim(channel, msg)
  echohl ErrorMsg | echo a:msg | echohl None
endfunction

function! s:NixJobExitVim(job, status)
  if a:status == 0
    echo '✓ Nix command completed successfully'
  else
    echohl ErrorMsg
    echo '✗ Nix command failed with code ' . a:status
    echohl None
  endif
endfunction

" Nix command definitions
command! -nargs=? -complete=custom,s:NixRunComplete NixRun
  \ call s:RunNixCommand('run', empty(<q-args>) ? '.' : <q-args>, 1)

command! -nargs=? -complete=custom,s:NixBuildComplete NixBuild
  \ call s:RunNixCommand('build', empty(<q-args>) ? '.' : <q-args>, 1)

command! -nargs=? NixShell call s:NixDevelopShell(<q-args>)

command! -nargs=? -complete=custom,s:NixInputComplete NixUpdate
  \ call s:RunNixCommand('flake update', empty(<q-args>) ? '' : '--update-input ' . <q-args>, 1)

command! -nargs=* NixCheck
  \ call s:RunNixCommand('flake check', <q-args>, 1)

command! NixClean call s:NixClean()

command! -nargs=? NixInfo
  \ call s:RunNixCommand('flake show', empty(<q-args>) ? '.' : <q-args>, 0)

command! -nargs=1 NixSearch
  \ call s:RunNixCommand('search nixpkgs', <q-args>, 1)

command! -nargs=+ NixWhyDepends
  \ call s:RunNixCommand('why-depends', <q-args>, 0)

command! -nargs=1 NixEval
  \ call s:RunNixCommand('eval', '--expr ' . shellescape(<q-args>), 0)

" Helper functions for specific commands
function! s:NixDevelopShell(target)
  let l:target = empty(a:target) ? '.' : a:target

  if has('nvim')
    vsplit
    execute 'terminal nix develop ' . l:target
    startinsert
  elseif has('terminal')
    execute 'terminal nix develop ' . l:target
  else
    echo 'Opening nix develop shell in background...'
    execute '!nix develop ' . l:target
  endif
endfunction

function! s:NixClean()
  let l:confirm = input('Clean nix store and remove old generations? (y/N): ')
  if tolower(l:confirm) ==# 'y' || tolower(l:confirm) ==# 'yes'
    echo '🧹 Cleaning nix store...'
    call s:RunNixCommand('store gc', '', 1)
    call s:RunNixCommand('profile wipe-history', '', 0)
  else
    echo 'Cancelled.'
  endif
endfunction

" Completion functions
function! s:NixRunComplete(ArgLead, CmdLine, CursorPos)
  return ".#default\n.#neovim\n."
endfunction

function! s:NixBuildComplete(ArgLead, CmdLine, CursorPos)
  return ".#default\n.#neovim\n."
endfunction

function! s:NixInputComplete(ArgLead, CmdLine, CursorPos)
  return "nixpkgs\nflake-utils\nneovim-nightly-overlay"
endfunction

" Quick file editing commands
command! EditFlake edit flake.nix
command! EditDefault edit default.nix

" Section: Platform-Specific Tweaks
" =============================================================================

if s:is_mac
  set macmeta
elseif s:is_windows
  set shell=cmd
  set shellcmdflag=/c
endif

if $TERM =~# '^screen'
  if exists('+ttymouse') && &ttymouse ==# ''
    set ttymouse=xterm
  endif
endif

" Section: Colorscheme and Final Setup
" =============================================================================

" Better color detection
if $TERM !~? 'linux' && &t_Co == 8
  set t_Co=16
endif

colorscheme habamax

" Load matchit for better % matching
packadd! matchit

" UTF-8 encoding fallback
if &encoding ==# 'latin1' && s:is_gui
  set encoding=utf-8
endif

" Better status line
set statusline=%f\ %h%w%m%r%{LspDiagnosticCounts()}\ %=%{&ff}\ %{&fenc}\ %{&ft}\ %l,%c%V\ %P

" Session management
set sessionoptions=blank,buffers,folds,help,tabpages,winsize,terminal,sesdir,globals
set viewoptions-=options

" =============================================================================
" END OF CONFIGURATION
" =============================================================================

" vim:set et sw=2 foldmethod=expr
