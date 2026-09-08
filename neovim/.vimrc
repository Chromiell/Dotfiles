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
set timeoutlen=1000  " Gives 1000ms to complete multi-key leader shortcuts
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
" 7. TOP BUFFERLINE (Display active buffers across the top)
" ============================================================================
set showtabline=2 " Always show top bar

function! s:GetBufferOrder() abort
    let l:listed = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    if !exists('g:buffer_order')
        let g:buffer_order = []
    endif
    " Remove closed buffers from custom order list
    call filter(g:buffer_order, 'index(l:listed, v:val) != -1')
    " Append newly opened buffers
    for l:b in l:listed
        if index(g:buffer_order, l:b) == -1
            call add(g:buffer_order, l:b)
        endif
    endfor
    return g:buffer_order
endfunction

" Move buffer left (-1) or right (+1)
function! s:MoveBuffer(dir) abort
    let l:current = bufnr('%')
    let l:order = s:GetBufferOrder()
    let l:idx = index(l:order, l:current)
    if l:idx == -1 | return | endif

    let l:new_idx = l:idx + a:dir
    if l:new_idx >= 0 && l:new_idx < len(l:order)
        let l:temp = l:order[l:idx]
        let l:order[l:idx] = l:order[l:new_idx]
        let l:order[l:new_idx] = l:temp
        let g:buffer_order = l:order
        redrawtabline
    endif
endfunction

" Repeating loop to continuously shift buffer with [ or ]
function! s:MoveBufferRepeatable(dir) abort
    call s:MoveBuffer(a:dir)
    while 1
        redraw
        let l:c = nr2char(getchar())
        if l:c ==# '['
            call s:MoveBuffer(-1)
        elseif l:c ==# ']'
            call s:MoveBuffer(1)
        else
            call feedkeys(l:c, 'm')
            break
        endif
    endwhile
endfunction

function! PureBufferLine() abort
    let l:s = ''
    let l:current = bufnr('%')
    let l:buffers = s:GetBufferOrder()

    for l:b in l:buffers
        let l:name = bufname(l:b)
        let l:name = empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':t')
        let l:mod = getbufvar(l:b, '&modified') ? ' [+]' : ''
        let l:pin = getbufvar(l:b, 'pinned', 0) ? '📌 ' : ''

        " Highlight current active buffer vs inactive buffers
        if l:b == l:current
            let l:s .= '%#TabLineSel# ' . l:pin . l:b . ': ' . l:name . l:mod . ' '
        else
            let l:s .= '%#TabLine# ' . l:pin . l:b . ': ' . l:name . l:mod . ' '
        endif
    endfor

    " Fill remaining space
    let l:s .= '%#TabLineFill#%='
    return l:s
endfunction

" Navigate buffers according to top bufferline visual order
function! s:NavBuffer(dir) abort
    let l:current = bufnr('%')
    let l:order = s:GetBufferOrder()
    let l:idx = index(l:order, l:current)

    if l:idx == -1
        if a:dir > 0 | bnext | else | bprevious | endif
        return
    endif

    let l:count = len(l:order)
    if l:count <= 1 | return | endif

    let l:new_idx = (l:idx + a:dir) % l:count
    if l:new_idx < 0
        let l:new_idx += l:count
    endif

    execute 'buffer ' . l:order[l:new_idx]
endfunction

set tabline=%!PureBufferLine()

" ============================================================================
" 8. CUSTOM UTILITIES & FUNCTIONS
" ============================================================================

" 8.1 Copy Project Path (<leader>fP)
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

" 8.2 Trim Trailing Whitespace (<leader>ct)
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

" 8.3 Delete Marks on Current Line (<leader>md)
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

" 8.4 Color Converter: Hex <-> HSL (<leader>co and :ToggleHexHsl)
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

" 8.5 Timestamp <-> Date Converter (<leader>cx in Visual mode)
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

" 8.6 Quickfix Window Editing (dd and visual d, matching quicker.nvim)
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

" 8.7 Diff Two Buffers (<leader>bc)
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

" 8.8 Git Blame Sidebar (<leader>gb)
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

" 8.9 Format / Indent File (<leader>cf)
function! s:FormatIndent() abort
    let l:save_view = winsaveview()
    keepjumps normal! gg=G
    call winrestview(l:save_view)
    echomsg "File auto-indented!"
endfunction

" 8.10 Project Grep using Quickfix (<leader>fg and <leader>\)
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

" 8.11 Dynamic Visual Surround (gsa)
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

" 8.12 Dynamic Comment Toggler (gcc / gc)
function! s:ToggleComment() range abort
    let l:cms = empty(&commentstring) ? '# %s' : &commentstring
    let l:parts = split(l:cms, '%s', 1)
    let l:left = trim(l:parts[0])
    let l:right = len(l:parts) > 1 ? trim(l:parts[1]) : ''

    let l:left_esc = escape(l:left, '/*~[]$^.')
    let l:right_esc = escape(l:right, '/*~[]$^.')

    " Check if all non-empty lines in target range are commented
    let l:all_commented = 1
    let l:has_content = 0
    for l:lnum in range(a:firstline, a:lastline)
        let l:line = trim(getline(l:lnum))
        if empty(l:line) | continue | endif
        let l:has_content = 1
        let l:pat = !empty(l:right) ? '^\s*' . l:left_esc . '.*' . l:right_esc . '$' : '^\s*' . l:left_esc
        if l:line !~# l:pat
            let l:all_commented = 0
            break
        endif
    endfor

    if !l:has_content | return | endif

    " Apply comment or uncomment
    for l:lnum in range(a:firstline, a:lastline)
        let l:line = getline(l:lnum)
        if empty(trim(l:line)) | continue | endif

        if l:all_commented
            if !empty(l:right)
                let l:line = substitute(l:line, '\s*' . l:left_esc . '\s\?', '', '')
                let l:line = substitute(l:line, '\s\?' . l:right_esc . '$', '', '')
            else
                let l:line = substitute(l:line, l:left_esc . '\s\?', '', '')
            endif
        else
            let l:indent = matchstr(l:line, '^\s*')
            let l:content = strpart(l:line, len(l:indent))
            if !empty(l:right)
                let l:line = l:indent . l:left . ' ' . l:content . ' ' . l:right
            else
                let l:line = l:indent . l:left . ' ' . l:content
            endif
        endif
        call setline(l:lnum, l:line)
    endfor
endfunction

" 8.13 Pure Vimscript Multi-Cursor Submode (<leader>mi)
function! s:MultiCursorMode() range abort
    let l:lines = range(a:firstline, a:lastline)
    if len(l:lines) <= 1
        echohl WarningMsg | echo "Multi-cursor requires selecting multiple lines" | echohl None
        return
    endif

    let l:start_col = col('.')
    let l:cols = {}
    for l:lnum in l:lines
        let l:cols[l:lnum] = min([l:start_col, max([1, len(getline(l:lnum))])])
    endfor

    let l:match_ids = []

    " Submode loop
    while 1
        " Clear & redraw cursor highlights across all selected lines
        for l:id in l:match_ids | silent! call matchdelete(l:id) | endfor
        let l:match_ids = []
        let l:pos_list = []
        for l:lnum in l:lines
            call add(l:pos_list, [l:lnum, l:cols[l:lnum]])
        endfor
        for l:i in range(0, len(l:pos_list) - 1, 8)
            call add(l:match_ids, matchaddpos('IncSearch', l:pos_list[l:i : l:i + 7], 100))
        endfor

        redraw
        echo "-- MULTI-CURSOR -- [w/b/e/h/l/$/0/x/dw/r/i/a/c] (<Esc> or <Enter> to exit)"

        let l:nr = getchar()
        let l:char = type(l:nr) == type(0) ? nr2char(l:nr) : l:nr

        " Exit submode on Esc, Enter, q, or Ctrl-C
        if l:char ==# "\<Esc>" || l:char ==# "\<CR>" || l:char ==# 'q' || l:nr == 3 || l:nr == 13
            break
        endif

        " Handle Insert / Change modes (i, a, I, A, c, s)
        if l:char =~# '^[iaIACSs]$' || l:char ==# 'cc' || l:char ==# 'cw' || l:char ==# 'ciw'
            let l:input_str = ""
            while 1
                redraw
                echo "-- MULTI-CURSOR INSERT -- " . l:char . l:input_str
                let l:in_nr = getchar()
                let l:in_char = type(l:in_nr) == type(0) ? nr2char(l:in_nr) : l:in_nr

                " Confirm insertion on Esc, Enter, or Ctrl-C
                if l:in_char ==# "\<Esc>" || l:in_char ==# "\<CR>" || l:in_nr == 3 || l:in_nr == 13
                    break
                elseif l:in_char ==# "\<BS>" || l:in_nr == 8
                    if len(l:input_str) > 0
                        let l:input_str = strpart(l:input_str, 0, len(l:input_str) - 1)
                    endif
                else
                    let l:input_str .= l:in_char
                endif
            endwhile

            " Replay insertion on all lines
            let l:cmd = l:char . l:input_str . "\<Esc>"
            for l:lnum in l:lines
                call cursor(l:lnum, l:cols[l:lnum])
                execute "normal! " . l:cmd
                let l:cols[l:lnum] = col('.')
            endfor

        " Handle Replace char (r{char})
        elseif l:char ==# 'r'
            let l:r_nr = getchar()
            let l:r_char = type(l:r_nr) == type(0) ? nr2char(l:r_nr) : l:r_nr
            for l:lnum in l:lines
                call cursor(l:lnum, l:cols[l:lnum])
                execute "normal! r" . l:r_char
                let l:cols[l:lnum] = col('.')
            endfor

        " Handle Normal motions & edits (w, b, e, h, l, $, 0, x, ~, dw, db, de, etc.)
        else
            let l:full_cmd = l:char
            if l:char =~# '^[dftyg]$'
                let l:next_nr = getchar()
                let l:next_char = type(l:next_nr) == type(0) ? nr2char(l:next_nr) : l:next_nr
                let l:full_cmd .= l:next_char
                if l:next_char =~# '^[ftFT]$'
                    let l:t_nr = getchar()
                    let l:full_cmd .= type(l:t_nr) == type(0) ? nr2char(l:t_nr) : l:t_nr
                endif
            endif

            for l:lnum in l:lines
                call cursor(l:lnum, l:cols[l:lnum])
                execute "normal! " . l:full_cmd
                let l:cols[l:lnum] = col('.')
            endfor
        endif
    endwhile

    " Clean up visual highlights
    for l:id in l:match_ids | silent! call matchdelete(l:id) | endfor
    redraw | echo ""
endfunction

" 8.14 Smart Save with Sudo Fallback & New File Prompt (<C-s>)
function! s:SmartSave() abort
    let l:file = expand('%')

    " Prompt for a filename if current buffer is unnamed
    if empty(l:file)
        call inputsave()
        let l:filename = input('Save as: ', '', 'file')
        call inputrestore()
        redraw!

        if empty(l:filename)
            echohl WarningMsg | echo "Save cancelled: No filename provided" | echohl None
            return
        endif

        execute 'file ' . fnameescape(l:filename)
        let l:file = expand('%')
    endif

    " Save via sudo tee if file is read-only or not writable
    if &readonly || (filewritable(l:file) != 1 && filereadable(l:file))
        execute 'silent write !sudo tee ' . shellescape(l:file) . ' >/dev/null'
        edit!
        echomsg "File saved with sudo privileges: " . l:file
    else
        " Attempt standard write; fallback to sudo if permission is denied
        try
            write
        catch /^Vim\%((\a\+)\)\=:E\(45\|212\|505\)/
            execute 'silent write !sudo tee ' . shellescape(l:file) . ' >/dev/null'
            edit!
            echomsg "File saved with sudo privileges: " . l:file
        endtry
    endif
endfunction

" 8.15 File Explorer (Netrw tree mode - Toggle at current buffer location)
let g:netrw_banner = 0
let g:netrw_liststyle = 0
let g:netrw_altv = 1
let g:netrw_winsize = 25

function! s:ToggleExplorer() abort
    " Check if any window in the current tab is a Netrw explorer
    for l:w in range(1, winnr('$'))
        if getwinvar(l:w, '&ft') ==# 'netrw'
            execute l:w . 'close'
            return
        endif
    endfor

    " If netrw is not open, open it at current buffer directory
    let l:dir = expand('%:p:h')
    if empty(l:dir) || &ft ==# 'netrw'
        let l:dir = getcwd()
    endif
    execute 'Lexplore ' . fnameescape(l:dir)
endfunction

" 8.16 Display Marks in Sign Column
highlight MarkSign guifg=#ff9e64 guibg=NONE gui=bold ctermfg=215 cterm=bold

if has('signs')
    " Define signs for marks a-z and A-Z
    for s:c in range(char2nr('a'), char2nr('z'))
        let s:char = nr2char(s:c)
        execute 'sign define Mark_' . s:char . ' text=' . s:char . ' texthl=MarkSign'
    endfor
    for s:c in range(char2nr('A'), char2nr('Z'))
        let s:char = nr2char(s:c)
        execute 'sign define Mark_' . s:char . ' text=' . s:char . ' texthl=MarkSign'
    endfor
endif

function! s:UpdateMarkSigns() abort
    if !has('signs') | return | endif
    let l:buf = bufnr('%')

    " Clear previous mark signs in current buffer
    call sign_unplacelist([{'buffer': l:buf, 'group': 'MarkSigns'}])

    " Place signs for active marks
    let l:marks = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    for l:i in range(len(l:marks))
        let l:m = l:marks[l:i]
        let l:pos = getpos("'" . l:m)
        if l:pos[1] > 0 && (l:pos[0] == 0 || l:pos[0] == l:buf)
            call sign_place(0, 'MarkSigns', 'Mark_' . l:m, l:buf, {'lnum': l:pos[1], 'priority': 10})
        endif
    endfor
endfunction

function! s:SetMarkInteractive() abort
    redraw
    let l:nr = getchar()
    let l:c = type(l:nr) == type(0) ? nr2char(l:nr) : l:nr
    if l:c =~# '^[a-zA-Z]$'
        execute 'normal! m' . l:c
        call s:UpdateMarkSigns()
    endif
endfunction

function! s:DeleteAllMarks()
    " Save current buffer number so we can return to it
    let l:current_buf = bufnr('%')

    " Suppress autocommands for speed and clear local marks across all buffers
    noautocmd bufdo delmarks!

    " Return to the original buffer without triggering autocommands
    execute 'noautocmd buffer ' . l:current_buf

    " Delete all global marks (A-Z) and numbered jump marks (0-9)
    delmarks A-Z 0-9
endfunction

" 8.17 Buffer Pinning & Mass Close Utilities
function! s:TogglePinBuffer() abort
    let b:pinned = get(b:, 'pinned', 0) ? 0 : 1
    let l:name = empty(expand('%:t')) ? '[No Name]' : expand('%:t')
    if b:pinned
        echomsg "Pinned buffer: " . l:name
    else
        echomsg "Unpinned buffer: " . l:name
    endif
    redrawtabline
endfunction

function! s:CloseUnpinnedBuffers() abort
    let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let l:closed = 0

    for l:buf in l:buffers
        " Skip if buffer is explicitly pinned
        if getbufvar(l:buf, 'pinned', 0) == 1
            continue
        endif

        " Safely delete unpinned buffer with confirmation prompt for unsaved changes
        execute 'confirm bdelete ' . l:buf
        let l:closed += 1
    endfor

    echomsg l:closed . " unpinned buffer(s) closed."

    redrawtabline
endfunction

" ============================================================================
" 9. KEYMAPS & SHORTCUTS (Faithful to LazyVim & project keymaps)
" ============================================================================

" --- General & Editing ---
nnoremap <silent> <leader>fP :call <SID>CopyProjectPath()<CR>
nnoremap <silent> <leader>ct :call <SID>TrimTrailingWhitespace()<CR>
vnoremap <silent> <leader>ct :call <SID>TrimTrailingWhitespaceSelection()<CR>
nnoremap <silent> <leader>cT :call <SID>ToggleTrailspace()<CR>
nnoremap <silent> <leader>co :call <SID>ToggleHexHsl()<CR>
vnoremap <silent> <leader>cx :<C-u>call <SID>ToggleDateTimestamp()<CR>

" Save buffer with Ctrl+S (Automatic Sudo Fallback)
nnoremap <silent> <C-s> :call <SID>SmartSave()<CR>
inoremap <silent> <C-s> <Esc>:call <SID>SmartSave()<CR>gi
vnoremap <silent> <C-s> <Esc>:call <SID>SmartSave()<CR>gv

" Indentation (stays in visual mode after indenting)
nnoremap <Tab> >>
nnoremap <S-Tab> <<
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Marks (With Instant Sign Column Display)
nnoremap <silent> m :call <SID>SetMarkInteractive()<CR>
nnoremap <silent> <leader>md :call <SID>DeleteLineMarks()<CR>:call <SID>UpdateMarkSigns()<CR>
nnoremap <silent> <leader>mD :call <SID>DeleteAllMarks()<CR>:call <SID>UpdateMarkSigns()<CR>

" Buffer Navigation & Reordering
nnoremap <silent> H :call <SID>NavBuffer(-1)<CR>
nnoremap <silent> L :call <SID>NavBuffer(1)<CR>
nnoremap <silent> [b :call <SID>NavBuffer(-1)<CR>
nnoremap <silent> ]b :call <SID>NavBuffer(1)<CR>
nnoremap <silent> <leader>b[ :call <SID>MoveBufferRepeatable(-1)<CR>
nnoremap <silent> <leader>b] :call <SID>MoveBufferRepeatable(1)<CR>
nnoremap <silent> <leader>bb :buffers<CR>:buffer<Space>
nnoremap <silent> <leader>bd :confirm bdelete<CR>

" Window Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <silent> <leader>wd :close<CR>

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi

" Toggle Comments
nnoremap <silent> gcc :call <SID>ToggleComment()<CR>
xnoremap <silent> gc :<C-u>'<,'>call <SID>ToggleComment()<CR>

" Interactive Multi-Cursor Submode
xnoremap <silent> <leader>mi :<C-u>'<,'>call <SID>MultiCursorMode()<CR>

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
nnoremap <silent> <leader>e :call <SID>ToggleExplorer()<CR>
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

" Buffer Pinning & Mass Operations
nnoremap <silent> <leader>bp :call <SID>TogglePinBuffer()<CR>
nnoremap <silent> <leader>bP :call <SID>CloseUnpinnedBuffers()<CR>

" ============================================================================
" 10. AUTOCOMMANDS
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

" Refresh mark signs in sign column
autocmd BufEnter,BufWritePost,CursorHold * call s:UpdateMarkSigns()

" Automatically wipe netrw buffers when closed so they don't linger
augroup NetrwBufferCleanup
    autocmd!
    autocmd FileType netrw setlocal bufhidden=wipe
augroup END
