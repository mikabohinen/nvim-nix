" vimrc.vim

" Vim configuration following minimalist philosophy

" Section: Bootstrap


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
set wildoptions=tagfile
set wildmode=longest:longest,full
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

" Colorscheme
colorscheme habamax

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

" =============================================================================
" LEADER MAPPINGS
" =============================================================================

let mapleader = " "
let maplocalleader = ","

" File operations
nnoremap <leader><leader> :find *
nnoremap <leader>ff :find *
nnoremap <leader>fF :find **/*

" Buffer management
nnoremap <leader>fb :buffer *
nnoremap <leader>fB :sbuffer *
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
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

" Quick toggle
nnoremap <silent> <leader>c :call ToggleQuickFix()<CR>

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
  autocmd FileType lisp,scheme,clojure setlocal lisp shiftwidth=2
  autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
  autocmd FileType html,css,javascript,typescript,json,nix setlocal shiftwidth=2

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
    split
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

" vim:set et sw=2 foldmethod=expr
