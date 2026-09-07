" ============================================================================
" .vimrc - Portable Standalone Vim Configuration
" ============================================================================
" Mirroring the local Neovim / LazyVim environment for remote servers.
" Works 100% standalone out-of-the-box with zero external dependencies.
"
" Quick Remote Export:
"   scp ~/.dotfiles/neovim/.vimrc user@remote-server:~/.vimrc
" Or with GNU Stow:
"   cd ~/.dotfiles && stow neovim
" ============================================================================

scriptencoding utf-8

" ============================================================================
" 1. GENERAL & SYSTEM SETTINGS
" ============================================================================
set nocompatible
filetype plugin indent on
syntax on

" Allow switching buffers with unsaved changes
set hidden

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,latin1,ucs-bom,default
" Automatically sync Vim registers with the system clipboard
set clipboard=unnamedplus

" Leader keys (Space as leader, matching LazyVim)
let mapleader = " "
let maplocalleader = " "
nnoremap <Space> <Nop>
vnoremap <Space> <Nop>

" Global configuration flags
let g:autoformat = 0
let g:omni_sql_no_default_maps = 1

" ============================================================================
" 2. INDENTATION & FORMATTING (Default: 4 Spaces)
" ============================================================================
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent

" ============================================================================
" 3. DISPLAY, WRAPPING & WHITESPACE
" ============================================================================
set wrap
set linebreak
set breakindent

" Show invisible whitespace characters
set list
set listchars=tab:»\ ,trail:·,nbsp:␣,lead:·

" Line numbers & UI layout
set number
set relativenumber
set cursorline
if has('signs')
    set signcolumn=yes
endif
set scrolloff=4
set sidescrolloff=8
set splitbelow
set splitright
set mouse=a
set updatetime=250
set timeoutlen=300
set ttimeoutlen=50
set backspace=indent,eol,start

" ============================================================================
" 4. SEARCH, HISTORY & DIFF
" ============================================================================
set ignorecase
set smartcase
set incsearch
set hlsearch
set wildmenu
set wildmode=longest:full,full
set wildignore+=*.o,*.obj,*.bin,*.dll,*.exe,*.so,*.pyc,*.png,*.jpg,*.jpeg,*.gif,*.zip,*.tar.gz,*/.git/*,*/node_modules/*,*/vendor/*

" Persistent undo across sessions
if has('persistent_undo')
    let s:undo_dir = expand('~/.vim/undo')
    if !isdirectory(s:undo_dir)
        call mkdir(s:undo_dir, 'p', 0700)
    endif
    let &undodir = s:undo_dir
    set undofile
endif

" Modern diff algorithm (histogram + indent-heuristic)
if has('patch-8.1.0360')
    set diffopt+=internal,algorithm:histogram,indent-heuristic
endif

" ============================================================================
" 5. TOKYONIGHT MOON THEME & HIGHLIGHTS (24-bit TrueColor)
" ============================================================================
if has('termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif
set background=dark

function! s:ApplyTokyoNightHighlights() abort
    " Core Editor Colors
    highlight Normal            guibg=#222436 guifg=#c8d3f5 ctermbg=235 ctermfg=253
    highlight CursorLine        guibg=#2f334d ctermbg=236 cterm=NONE
    highlight CursorLineNr      guifg=#ff9e64 guibg=#2f334d gui=bold ctermfg=215 cterm=bold
    highlight LineNr            guifg=#828bb8 ctermfg=242
    highlight LineNrAbove       guifg=#828bb8 ctermfg=242
    highlight LineNrBelow       guifg=#828bb8 ctermfg=242
    highlight SignColumn        guibg=#222436 ctermbg=NONE
    highlight FoldColumn        guibg=#222436 ctermbg=NONE
    highlight Whitespace        guifg=#3b4261 ctermfg=238
    highlight NonText           guifg=#3b4261 ctermfg=238
    highlight SpecialKey        guifg=#3b4261 ctermfg=238
    highlight ExtraWhitespace   guibg=#681d23 guifg=#686868 ctermbg=52 ctermfg=242

    " Search & Selection
    highlight Search            guibg=#3e68d7 guifg=#c8d3f5 ctermbg=26 ctermfg=253
    highlight IncSearch         guibg=#ff9e64 guifg=#1e2030 ctermbg=215 ctermfg=234
    highlight Visual            guibg=#2d3f76 ctermbg=237
    highlight MatchParen        guibg=#3e68d7 guifg=#ff9e64 gui=bold ctermbg=26 ctermfg=215 cterm=bold

    " Statusline & Windows
    highlight StatusLine        guibg=#1e2030 guifg=#82aaff gui=bold ctermbg=234 ctermfg=111
    highlight StatusLineNC      guibg=#1e2030 guifg=#545c7e ctermbg=234 ctermfg=242
    highlight VertSplit         guibg=#1e2030 guifg=#1e2030 ctermbg=234 ctermfg=234
    highlight Pmenu             guibg=#1e2030 guifg=#c8d3f5 ctermbg=234 ctermfg=253
    highlight PmenuSel          guibg=#2d3f76 guifg=#82aaff gui=bold ctermbg=237 ctermfg=111

    " Syntax
    highlight Comment           guifg=#636da6 gui=italic ctermfg=61
    highlight String            guifg=#c3e88d ctermfg=150
    highlight Function          guifg=#82aaff ctermfg=111
    highlight Keyword           guifg=#c099ff gui=italic ctermfg=141
    highlight Statement         guifg=#c099ff ctermfg=141
    highlight Identifier        guifg=#c8d3f5 ctermfg=253
    highlight Type              guifg=#65bcff ctermfg=75
    highlight Special           guifg=#4fd6be ctermfg=79
    highlight Constant          guifg=#ff9e64 ctermfg=215

    " Git Diffs
    highlight DiffAdd           guibg=#283b4d guifg=NONE ctermbg=24
    highlight DiffChange        guibg=#272d43 guifg=NONE ctermbg=236
    highlight DiffText          guibg=#394b70 guifg=NONE gui=bold ctermbg=60
    highlight DiffDelete        guibg=#3f2d3d guifg=#ff757f ctermbg=52 ctermfg=204

    " Statusline Mode Colors
    highlight StatModeNorm      guibg=#82aaff guifg=#1e2030 gui=bold ctermbg=111 ctermfg=234 cterm=bold
    highlight StatModeIns       guibg=#c3e88d guifg=#1e2030 gui=bold ctermbg=150 ctermfg=234 cterm=bold
    highlight StatModeVis       guibg=#c099ff guifg=#1e2030 gui=bold ctermbg=141 ctermfg=234 cterm=bold
    highlight StatModeRep       guibg=#ff757f guifg=#1e2030 gui=bold ctermbg=204 ctermfg=234 cterm=bold
    highlight StatModeCmd       guibg=#ff9e64 guifg=#1e2030 gui=bold ctermbg=215 ctermfg=234 cterm=bold
    highlight StatGit           guibg=#2f334d guifg=#ff9e64 gui=bold ctermbg=236 ctermfg=215 cterm=bold
    highlight StatFile          guibg=#1e2030 guifg=#c8d3f5 ctermbg=234 ctermfg=253
    highlight StatEnc           guibg=#2f334d guifg=#82aaff ctermbg=236 ctermfg=111
    highlight StatPos           guibg=#82aaff guifg=#1e2030 gui=bold ctermbg=111 ctermfg=234 cterm=bold

    " Quickfix Syntax Highlighting
    highlight qfFileName    guifg=#82aaff gui=bold ctermfg=111 cterm=bold
    highlight qfLineNr      guifg=#ff9e64 ctermfg=215
    highlight qfSeparator   guifg=#444a73 ctermfg=239
    highlight qfError       guifg=#ff757f ctermfg=204

    " Bufferbar / Tabline Colors
    highlight TabLine     guibg=#12131d guifg=#828bb8 gui=NONE ctermbg=234 ctermfg=242 cterm=NONE
    highlight TabLineSel  guibg=#2f334d guifg=#82aaff gui=bold ctermbg=236 ctermfg=215 cterm=bold
    highlight TabLineFill guibg=#12131d guifg=#12131d gui=NONE ctermbg=234 ctermfg=234 cterm=NONE
endfunction

call s:ApplyTokyoNightHighlights()

" Trailing Whitespace highlighting engine (MiniTrailspace matching)
let g:trailspace_enabled = 1
function! s:UpdateTrailspace() abort
    if g:trailspace_enabled
        if !exists('w:trailspace_match')
            let w:trailspace_match = matchadd('ExtraWhitespace', '\s\+$')
        endif
    else
        if exists('w:trailspace_match')
            silent! call matchdelete(w:trailspace_match)
            unlet w:trailspace_match
        endif
    endif
endfunction

function! s:ToggleTrailspace() abort
    let g:trailspace_enabled = !g:trailspace_enabled
    windo call s:UpdateTrailspace()
    if g:trailspace_enabled
        echomsg "Trailspace highlight enabled"
    else
        echomsg "Trailspace highlight disabled"
    endif
endfunction

" ============================================================================
" 6. LUALINE-STYLE STATUSLINE (with Git status & dynamic mode indicators)
" ============================================================================
function! ModeStatus() abort
    let l:m = mode()
    if l:m ==# 'n'
        return '%#StatModeNorm# NORMAL '
    elseif l:m ==# 'i'
        return '%#StatModeIns# INSERT '
    elseif l:m ==# 'v' || l:m ==# 'V' || l:m ==# "\<C-v>"
        return '%#StatModeVis# VISUAL '
    elseif l:m ==# 'R' || l:m ==# 'Rv'
        return '%#StatModeRep# REPLACE '
    elseif l:m ==# 'c'
        return '%#StatModeCmd# COMMAND '
    endif
    return '%#StatModeNorm# ' . l:m . ' '
endfunction

function! GitBranchStatus() abort
    if exists('b:git_status_cache')
        return b:git_status_cache
    endif
    let l:dir = expand('%:p:h')
    if empty(l:dir) || !isdirectory(l:dir)
        let b:git_status_cache = ''
        return ''
    endif
    let l:branch = trim(system('git -C ' . shellescape(l:dir) . ' rev-parse --abbrev-ref HEAD 2>/dev/null'))
    if v:shell_error != 0 || empty(l:branch)
        let b:git_status_cache = ''
        return ''
    endif
    let l:count = trim(system('git -C ' . shellescape(l:dir) . ' status --porcelain 2>/dev/null | grep -v "\.swp$" | wc -l'))
    let l:cnt = str2nr(l:count)
    if l:cnt > 0
        let b:git_status_cache = ' 󰊢 ' . l:branch . ' (' . l:cnt . ') '
    else
        let b:git_status_cache = ' 󰊢 ' . l:branch . ' '
    endif
    return b:git_status_cache
endfunction

function! RefreshGitCache() abort
    unlet! b:git_status_cache
endfunction

set laststatus=2
set statusline=%{%ModeStatus()%}
set statusline+=%{GitBranchStatus()}
set statusline+=%#StatFile#\ %f\ %m%r%h%w
set statusline+=%=
set statusline+=%#StatEnc#\ %{&fileencoding?&fileencoding:&encoding}\ [%{&fileformat}]\ %Y\
set statusline+=%#StatPos#\ %l:%c\ %P\

" ============================================================================
" 7. CUSTOM UTILITIES & FUNCTIONS
" ============================================================================

" 7.1 Copy Project Path (<leader>fP)
function! s:CopyProjectPath() abort
    let l:buf_name = expand('%:p')
    if empty(l:buf_name)
        echohl WarningMsg | echo "No file in current buffer" | echohl None
        return
    endif
    let l:root = finddir('.git/..', l:buf_name . ';')
    if empty(l:root)
        let l:root = findfile('package.json', l:buf_name . ';')
        if !empty(l:root) | let l:root = fnamemodify(l:root, ':p:h') | endif
    endif
    if empty(l:root)
        let l:root = findfile('Makefile', l:buf_name . ';')
        if !empty(l:root) | let l:root = fnamemodify(l:root, ':p:h') | endif
    endif
    if empty(l:root)
        let l:root = getcwd()
    else
        let l:root = fnamemodify(l:root, ':p')
    endif

    let l:root = substitute(l:root, '/$', '', '')
    let l:path = l:buf_name
    if stridx(l:buf_name, l:root . '/') == 0
        let l:path = strpart(l:buf_name, len(l:root) + 1)
    endif

    if has('clipboard')
        silent! call setreg('+', l:path)
        silent! call setreg('*', l:path)
    endif
    call setreg('"', l:path)
    echomsg "Copied: " . l:path
endfunction

" 7.2 Trim Trailing Whitespace (<leader>ct)
function! s:TrimTrailingWhitespace() abort
    let l:save_view = winsaveview()
    silent! undojoin
    keeppatterns %s/\s\+$//e
    call winrestview(l:save_view)
    echomsg "Trailing whitespace trimmed in file!"
endfunction

function! s:TrimTrailingWhitespaceSelection() range abort
    let l:save_view = winsaveview()
    silent! undojoin
    exe 'keeppatterns ' . a:firstline . ',' . a:lastline . 's/\s\+$//e'
    call winrestview(l:save_view)
    echomsg "Trailing whitespace trimmed in selection!"
endfunction

" 7.3 Delete Marks on Current Line (<leader>md)
function! s:DeleteLineMarks() abort
    let l:cur_line = line('.')
    let l:marks = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    let l:deleted = 0
    for l:i in range(len(l:marks))
        let l:m = l:marks[l:i]
        let l:pos = getpos("'" . l:m)
        if l:pos[1] == l:cur_line && (l:pos[0] == 0 || l:pos[0] == bufnr('%'))
            exe 'delmarks ' . l:m
            let l:deleted += 1
        endif
    endfor
    if l:deleted > 0
        echomsg "Deleted " . l:deleted . " marks from this line."
    else
        echomsg "No marks found on this line."
    endif
endfunction

" 7.4 Color Converter: Hex <-> HSL (<leader>co and :ToggleHexHsl)
function! s:Max3(a, b, c) abort
    let l:m = a:a > a:b ? a:a : a:b
    return l:m > a:c ? l:m : a:c
endfunction

function! s:Min3(a, b, c) abort
    let l:m = a:a < a:b ? a:a : a:b
    return l:m < a:c ? l:m : a:c
endfunction

function! s:HexToHsl(hex) abort
    let l:clean = substitute(a:hex, '^#', '', '')
    if len(l:clean) != 6 | return a:hex | endif
    let l:r = str2nr(l:clean[0:1], 16) / 255.0
    let l:g = str2nr(l:clean[2:3], 16) / 255.0
    let l:b = str2nr(l:clean[4:5], 16) / 255.0
    let l:max = s:Max3(l:r, l:g, l:b)
    let l:min = s:Min3(l:r, l:g, l:b)
    let l:d = l:max - l:min
    let l:l = (l:max + l:min) / 2.0
    let l:h = 0.0
    let l:s = 0.0

    if l:d != 0.0
        let l:s = l:l > 0.5 ? (l:d / (2.0 - l:max - l:min)) : (l:d / (l:max + l:min))
        if l:max == l:r
            let l:h = (l:g - l:b) / l:d + (l:g < l:b ? 6.0 : 0.0)
        elseif l:max == l:g
            let l:h = (l:b - l:r) / l:d + 2.0
        else
            let l:h = (l:r - l:g) / l:d + 4.0
        endif
        let l:h = l:h / 6.0
    endif

    let l:h_deg = round(l:h * 360.0 * 100.0) / 100.0
    let l:s_pct = round(l:s * 100.0 * 100.0) / 100.0
    let l:l_pct = round(l:l * 100.0 * 100.0) / 100.0

    let l:h_str = substitute(printf("%.2f", l:h_deg), '\.\?0\+$', '', '')
    let l:s_str = substitute(printf("%.2f", l:s_pct), '\.\?0\+$', '', '')
    let l:l_str = substitute(printf("%.2f", l:l_pct), '\.\?0\+$', '', '')

    return printf('hsl(%s, %s%%, %s%%)', l:h_str, l:s_str, l:l_str)
endfunction

function! s:Hue2Rgb(p, q, t) abort
    let l:t = a:t
    if l:t < 0.0 | let l:t += 1.0 | endif
    if l:t > 1.0 | let l:t -= 1.0 | endif
    if l:t < (1.0 / 6.0) | return a:p + (a:q - a:p) * 6.0 * l:t | endif
    if l:t < 0.5         | return a:q | endif
    if l:t < (2.0 / 3.0) | return a:p + (a:q - a:p) * (2.0 / 3.0 - l:t) * 6.0 | endif
    return a:p
endfunction

function! s:HslToHex(h, s, l) abort
    let l:h = str2float(a:h) / 360.0
    let l:s = str2float(a:s) / 100.0
    let l:l = str2float(a:l) / 100.0

    if l:s == 0.0
        let [l:r, l:g, l:b] = [l:l, l:l, l:l]
    else
        let l:q = l:l < 0.5 ? (l:l * (1.0 + l:s)) : (l:l + l:s - l:l * l:s)
        let l:p = 2.0 * l:l - l:q
        let l:r = s:Hue2Rgb(l:p, l:q, l:h + 1.0 / 3.0)
        let l:g = s:Hue2Rgb(l:p, l:q, l:h)
        let l:b = s:Hue2Rgb(l:p, l:q, l:h - 1.0 / 3.0)
    endif

    let l:ir = float2nr(round(l:r * 255.0))
    let l:ig = float2nr(round(l:g * 255.0))
    let l:ib = float2nr(round(l:b * 255.0))

    return printf('#%02x%02x%02x', l:ir, l:ig, l:ib)
endfunction

function! s:ToggleHexHsl() abort
    let l:line = getline('.')
    let l:col = col('.')

    " 1. Check for Hex pattern (#RRGGBB)
    let l:start = 0
    while 1
        let l:m = matchstrpos(l:line, '#\x\{6\}', l:start)
        if empty(l:m[0]) | break | endif
        let l:s_idx = l:m[1] + 1
        let l:e_idx = l:m[2]
        if l:col >= l:s_idx && l:col <= l:e_idx
            let l:hsl = s:HexToHsl(l:m[0])
            let l:newline = strpart(l:line, 0, l:s_idx - 1) . l:hsl . strpart(l:line, l:e_idx)
            call setline('.', l:newline)
            echomsg "Converted Hex -> HSL: " . l:hsl
            return
        endif
        let l:start = l:e_idx
    endwhile

    " 2. Check for HSL pattern (hsl(h, s%, l%))
    let l:start = 0
    while 1
        let l:m = matchstrpos(l:line, 'hsl(\s*\([0-9.]\+\)\s*,\s*\([0-9.]\+\)%\?\s*,\s*\([0-9.]\+\)%\?\s*)', l:start)
        if empty(l:m[0]) | break | endif
        let l:s_idx = l:m[1] + 1
        let l:e_idx = l:m[2]
        if l:col >= l:s_idx && l:col <= l:e_idx
            let l:tokens = matchlist(l:m[0], 'hsl(\s*\([0-9.]\+\)\s*,\s*\([0-9.]\+\)%\?\s*,\s*\([0-9.]\+\)%\?\s*)')
            let l:hex = s:HslToHex(l:tokens[1], l:tokens[2], l:tokens[3])
            let l:newline = strpart(l:line, 0, l:s_idx - 1) . l:hex . strpart(l:line, l:e_idx)
            call setline('.', l:newline)
            echomsg "Converted HSL -> Hex: " . l:hex
            return
        endif
        let l:start = l:e_idx
    endwhile

    echohl WarningMsg | echo "No Hex or HSL format found under cursor" | echohl None
endfunction

command! -nargs=0 ToggleHexHsl call s:ToggleHexHsl()

" 7.5 Timestamp <-> Date Converter (<leader>cx in Visual mode)
function! s:ToggleDateTimestamp() abort
    let l:orig_reg = getreg('x')
    let l:orig_type = getregtype('x')
    normal! gv"xy
    let l:text = trim(getreg('x'))

    let l:new_text = ''
    if l:text =~# '^\d\+$'
        let l:new_text = strftime('%Y-%m-%d %H:%M:%S', str2nr(l:text))
        echomsg 'Converted Timestamp -> Date: ' . l:new_text
    else
        let l:m = matchlist(l:text, '^\(\d\{4\}\)-\(\d\{2\}\)-\(\d\{2\}\) \(\d\{2\}\):\(\d\{2\}\):\(\d\{2\}\)$')
        if !empty(l:m)
            let l:res = trim(system('date -d ' . shellescape(l:text) . ' +%s 2>/dev/null'))
            if v:shell_error == 0 && l:res =~# '^\d\+$'
                let l:new_text = l:res
            elseif has('python3')
                python3 import vim, datetime
                python3 dt = datetime.datetime.strptime(vim.eval('l:text'), '%Y-%m-%d %H:%M:%S')
                python3 vim.command(f"let l:new_text = '{int(dt.timestamp())}'")
            endif
            echomsg 'Converted Date -> Timestamp: ' . l:new_text
        else
            echohl ErrorMsg | echo 'Selection is not a valid timestamp or YYYY-MM-DD HH:MM:SS string' | echohl None
            call setreg('x', l:orig_reg, l:orig_type)
            return
        endif
    endif

    if !empty(l:new_text)
        call setreg('x', l:new_text, 'v')
        normal! gv"xp
    endif
    call setreg('x', l:orig_reg, l:orig_type)
endfunction

" 7.6 Quickfix Window Editing (dd and visual d, matching quicker.nvim)
function! s:QfDeleteLine() abort
    let l:cur_line = line('.')
    let l:is_loc = getwininfo(win_getid())[0].loclist == 1
    let l:qf_list = l:is_loc ? getloclist(0) : getqflist()
    if len(l:qf_list) >= l:cur_line && l:cur_line > 0
        call remove(l:qf_list, l:cur_line - 1)
        if l:is_loc
            call setloclist(0, l:qf_list, 'r')
        else
            call setqflist(l:qf_list, 'r')
        endif
        let l:new_line = min([l:cur_line, len(l:qf_list)])
        if l:new_line > 0
            call cursor(l:new_line, 1)
        endif
    endif
endfunction

function! s:QfDeleteSelection() range abort
    let l:start_line = a:firstline
    let l:end_line = a:lastline
    let l:is_loc = getwininfo(win_getid())[0].loclist == 1
    let l:qf_list = l:is_loc ? getloclist(0) : getqflist()
    let l:total = len(l:qf_list)
    if l:total > 0
        let l:start_idx = max([1, l:start_line]) - 1
        let l:end_idx = min([l:total, l:end_line]) - 1
        if l:start_idx <= l:end_idx
            for l:i in range(l:end_idx, l:start_idx, -1)
                call remove(l:qf_list, l:i)
            endfor
            if l:is_loc
                call setloclist(0, l:qf_list, 'r')
            else
                call setqflist(l:qf_list, 'r')
            endif
            let l:new_line = min([l:start_line, len(l:qf_list)])
            if l:new_line > 0
                call cursor(l:new_line, 1)
            endif
        endif
    endif
endfunction

" 7.7 Diff Two Buffers (<leader>bc)
function! s:DiffTwoBuffers() abort
    let l:buf1 = input('Enter first buffer number: ')
    if empty(l:buf1) | return | endif
    let l:buf2 = input('Enter second buffer number: ')
    if empty(l:buf2) | return | endif
    tabnew
    execute 'buffer ' . l:buf1
    diffthis
    vsplit
    execute 'buffer ' . l:buf2
    diffthis
    wincmd h
endfunction

" 7.8 Git Blame Sidebar (<leader>gb)
function! s:GitBlame() abort
    let l:file = expand('%:p')
    if empty(l:file) | return | endif
    vsplit
    wincmd h
    vertical resize 35
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline
    execute 'silent %!git blame -w -L ' . line('.') . ',+20 --date=short ' . shellescape(l:file)
    setlocal nomodifiable
    wincmd l
endfunction

" 7.9 Format / Indent File (<leader>cf)
function! s:FormatIndent() abort
    let l:save_view = winsaveview()
    keepjumps normal! gg=G
    call winrestview(l:save_view)
    echomsg "File auto-indented!"
endfunction

" Streamlined Project Grep using Quickfix
function! s:ProjectGrep() abort
    call inputsave()
    let l:query = input('Search term: ')
    call inputrestore()
    redraw!

    if empty(l:query)
        return
    endif

    if executable('rg')
        " Run ripgrep in background with --vimgrep formatting (file:line:col:text)
        let l:cmd = 'rg --vimgrep --smart-case --hidden --glob ' . shellescape('!.git/*') . ' ' . shellescape(l:query)
        let l:qf_results = system(l:cmd)

        " Populate the quickfix list
        call setqflist([], 'r', {
            \ 'title': 'Grep: ' . l:query,
            \ 'lines': split(l:qf_results, "\n")
            \ })
    else
        " Native Vim fallback when ripgrep is missing
        try
            execute 'silent vimgrep /' . escape(l:query, '/') . '/j **/*'
        catch /^Vim\%((\a\+)\)\=:E480/
            " Catch 'E480: No match'
        endtry
    endif

    " Open the quickfix window at the bottom if matches exist
    if !empty(getqflist())
        botright cwindow
    else
        echomsg "No matches found for: " . l:query
    endif
endfunction

" Dynamic Visual Surround (supports quotes, brackets, and angle brackets)
function! s:VisualSurround() abort
    " Force screen redraw so Vim immediately waits for character input
    redraw
    let l:c = nr2char(getchar())
    if empty(l:c) || l:c ==# "\<Esc>" | return | endif

    let l:open = l:c
    let l:close = l:c
    if l:c ==# '('     | let l:open = '( ' | let l:close = ' )'
    elseif l:c ==# ')' | let l:open = '('  | let l:close = ')'
    elseif l:c ==# '[' | let l:open = '[ ' | let l:close = ' ]'
    elseif l:c ==# ']' | let l:open = '['  | let l:close = ']'
    elseif l:c ==# '{' | let l:open = '{ ' | let l:close = ' }'
    elseif l:c ==# '}' | let l:open = '{'  | let l:close = '}'
    elseif l:c ==# '<' | let l:open = '< ' | let l:close = ' >'
    elseif l:c ==# '>' | let l:open = '<'  | let l:close = '>'
    endif

    " Save registers to avoid overwriting clipboards
    let l:save_reg = getreg('"')
    let l:save_type = getregtype('"')

    " Yank visual selection into register z, wrap it, and paste it back over selection
    normal! gv"zy
    call setreg('z', l:open . getreg('z') . l:close, getregtype('z'))
    normal! gv"zp

    " Restore original register content
    call setreg('"', l:save_reg, l:save_type)
endfunction

" ============================================================================
" TOP BUFFERLINE (Display active buffers across the top)
" ============================================================================
set showtabline=2 " Always show top bar

function! PureBufferLine() abort
    let l:s = ''
    let l:current = bufnr('%')
    let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')

    for l:b in l:buffers
        let l:name = bufname(l:b)
        let l:name = empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':t')
        let l:mod = getbufvar(l:b, '&modified') ? ' [+]' : ''

        " Highlight current active buffer vs inactive buffers
        if l:b == l:current
            let l:s .= '%#TabLineSel# ' . l:b . ': ' . l:name . l:mod . ' '
        else
            let l:s .= '%#TabLine# ' . l:b . ': ' . l:name . l:mod . ' '
        endif
    endfor

    " Fill remaining space
    let l:s .= '%#TabLineFill#%='
    return l:s
endfunction

set tabline=%!PureBufferLine()

" ============================================================================
" 8. KEYMAPS & SHORTCUTS (Faithful to LazyVim & project keymaps)
" ============================================================================

" --- General & Editing ---
nnoremap <silent> <leader>fP :call <SID>CopyProjectPath()<CR>
nnoremap <silent> <leader>ct :call <SID>TrimTrailingWhitespace()<CR>
vnoremap <silent> <leader>ct :call <SID>TrimTrailingWhitespaceSelection()<CR>
nnoremap <silent> <leader>cT :call <SID>ToggleTrailspace()<CR>
nnoremap <silent> <leader>co :call <SID>ToggleHexHsl()<CR>
vnoremap <silent> <leader>cx :<C-u>call <SID>ToggleDateTimestamp()<CR>

" Indentation (stays in visual mode after indenting)
nnoremap <Tab> >>
nnoremap <S-Tab> <<
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Marks
nnoremap <silent> <leader>md :call <SID>DeleteLineMarks()<CR>
nnoremap <silent> <leader>mD :delmarks! \| delmarks A-Z0-9<CR>

" Buffer Navigation
nnoremap <silent> H :bprevious<CR>
nnoremap <silent> L :bnext<CR>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> <leader>b[ :bprevious<CR>
nnoremap <silent> <leader>b] :bnext<CR>
nnoremap <silent> <leader>bb :buffers<CR>:buffer<Space>
nnoremap <silent> <leader>bd :confirm bdelete<CR>

" Window Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi

" Search & Clear
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>

" Project Grep via Quickfix
nnoremap <silent> <leader>fg :call <SID>ProjectGrep()<CR>
nnoremap <silent> <leader>\  :call <SID>ProjectGrep()<CR>

" Find files in project
nnoremap <leader>ff :find<Space>
set path+=**

" Quickfix list navigation
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>

" Spelling navigation & toggle (<leader>uo, ]s, [s)
nnoremap <silent> <leader>uo :setlocal spell!<CR>
set spelllang=en,it

" Git & Diffing
nnoremap <silent> <leader>bc :call <SID>DiffTwoBuffers()<CR>
nnoremap <silent> <leader>gd :vsplit \| Gdiffsplit<CR>
nnoremap <silent> <leader>gb :call <SID>GitBlame()<CR>
nnoremap <silent> <leader>gH :execute '!git log -p %'<CR>

" File Explorer (Netrw tree mode)
let g:netrw_banner = 0
let g:netrw_liststyle = 0
let g:netrw_altv = 1
let g:netrw_winsize = 25
nnoremap <silent> <leader>e :Lexplore<CR>
nnoremap <silent> <leader>fe :Lexplore<CR>

" Format file or visual selection
nnoremap <silent> <leader>cf :call <SID>FormatIndent()<CR>
vnoremap <silent> <leader>cf =

" File / Buffer Management
nnoremap <silent> <leader>fn :enew<CR>

" Paste from Wayland system clipboard
if executable('wl-paste')
    nnoremap <silent> <leader>P :put =system('wl-paste --no-newline')<CR>
    nnoremap <silent> <leader>p :put! =system('wl-paste --no-newline')<CR>
endif

" Visual Surround (LazyVim / gsa style)
xnoremap <silent> gsa :<C-u>call <SID>VisualSurround()<CR>

" ============================================================================
" 9. AUTOCOMMANDS
" ============================================================================
augroup DotfilesVimrc
    autocmd!
    " Maintain TokyoNight palette on colorscheme change
    autocmd ColorScheme * call s:ApplyTokyoNightHighlights()

    " Update Git branch status in statusline
    autocmd BufEnter,BufWritePost,FocusGained * call RefreshGitCache()

    " Trailing whitespace matcher per window
    autocmd BufWinEnter,WinEnter * call s:UpdateTrailspace()

    " Restore last cursor position when reopening files
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    " Enable autoindent on file read
    autocmd BufReadPost,BufNewFile * setlocal autoindent

    " PHP Specific Configuration
    autocmd FileType php setlocal commentstring=//\ %s

    " CSS & SCSS Configuration (4 spaces)
    autocmd FileType scss,css setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

    " YAML Configuration (2 spaces)
    autocmd FileType yaml,yml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

    " Blade templates
    autocmd BufRead,BufNewFile *.blade.php setlocal filetype=html.php

    " Quickfix window custom mappings (dd and d)
    autocmd FileType qf nnoremap <buffer><silent> dd :call <SID>QfDeleteLine()<CR>
    autocmd FileType qf xnoremap <buffer><silent> d :call <SID>QfDeleteSelection()<CR>
augroup END

" Sync yank register with Wayland system clipboard via wl-copy
if executable('wl-copy')
    augroup WaylandClipboardSync
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system('wl-copy', join(v:event.regcontents, "\n")) | endif
    augroup END
endif
