" Based on of https://github.com/plasticboy/vim-markdown indent script

if exists("b:did_indent") | finish | endif
let b:did_indent = 1

setlocal indentexpr=GetDotooIndent()
setlocal nolisp
setlocal autoindent

" Only define the function once
if exists("*GetDotooIndent") | finish | endif

function! s:is_list_start(line)
    return a:line =~ '^\s*[-+] \+'
endfunction
function! s:is_checkbox_start(line)
    return a:line =~ '^\s*- \[[ -X]\] \+'
endfunction
function! s:is_headline(line)
    return a:line =~ '^*\+ \+'
endfunction

function! s:item_depth(line)
    return strlen(substitute(a:line, '^\(\*\+\) .*$', '\1', ''))
endfunction

function GetDotooIndent()
    " Find a non-blank line above the current line.
    let lnum = prevnonblank(v:lnum - 1)
    " At the start of the file use zero indent.
    if lnum == 0 | return 0 | endif
    let ind = indent(lnum)
    let line = getline(lnum)    " Last line
    let cline = getline(v:lnum) " Current line
    " Current line is the first line of a list item or headline, do not change indent
    if s:is_list_start(cline) || s:is_headline(cline)
        return indent(v:lnum)
    " Last line is the first line of a list item or headline, increase indent
    elseif s:is_checkbox_start(line)
        return ind + 6
    elseif s:is_list_start(line)
        return ind + 2
    elseif s:is_headline(line)
        return s:item_depth(line) + 1
    else
        return ind
    endif
endfunction
