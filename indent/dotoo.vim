" Based on indent of https://github.com/plasticboy/vim-markdown
if exists("b:did_indent") | finish | endif
let b:did_indent = 1

setlocal indentexpr=GetDotooIndent()
setlocal nolisp
setlocal autoindent

" Only define the function once
" TODO: isn't this build in?
if exists("*GetDotooIndent") | finish | endif

" TODO: function for *s
function! s:is_list_start(line)
    return a:line =~ '^\s*[-+*] \+' && a:line !~ '^\*'
endfunction
function! s:is_checkbox_start(line)
    return a:line =~ '^\s*- \[[ -X]\] \+'
endfunction

function! s:is_blank_line(line)
    return a:line =~ '^$'
endfunction

" TODO _ between words for consistency?
function! s:prevnonblank(lnum)
    let i = a:lnum
    while i > 1 && s:is_blank_line(getline(i))
        let i -= 1
    endwhile
    return i
endfunction

function GetDotooIndent()
    " Find a non-blank line above the current line.
    let lnum = prevnonblank(v:lnum - 1)
    " At the start of the file use zero indent.
    if lnum == 0 | return 0 | endif

    let ind = indent(lnum)
    let line = getline(lnum)    " Last line
    let cline = getline(v:lnum) " Current line
    " Current line is the first line of an item, do not change indent
    if s:is_list_start(cline) 
        return indent(v:lnum)
    " Last line is the first line of an item, increase indent
    elseif s:is_checkbox_start(line)
        return ind + 6
    elseif s:is_list_start(line)
        return ind + 2
    else
        return ind
    endif
endfunction
