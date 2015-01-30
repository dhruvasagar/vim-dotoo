if exists('g:autoloaded_dotoo_parser_lexer')
  finish
endif
let g:autoloaded_dotoo_parser_lexer = 1

" Syntax Methods {{{1
let s:syntax_methods = {}
function! s:syntax_methods.matches(line) dict
  return a:line =~# self.pattern
endfunction

function! s:syntax_methods.matchlist(line) dict abort
  return matchlist(a:line, self.pattern)[1:]
endfunction

" Syntax Definition {{{1
let s:syntax = {}
function! s:define(name, pattern)
  let obj = {
        \ 'type': a:name,
        \ 'pattern': a:pattern,
        \ 'order': len(s:syntax),
        \ }
  call extend(obj, s:syntax_methods)
  let s:syntax[a:name] = obj
endfunction

let s:todo_keywords_todo = g:dotoo#parser#todo_keywords[:index(g:dotoo#parser#todo_keywords,'|')-1]
let s:todo_keywords_done = g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords,'|'):]
let s:todo_keywords_regex = join(s:todo_keywords_todo+s:todo_keywords_done, '|')
call s:define('blank', '\v^$')
call s:define('directive', '\v^#\+(\w+): (.*)$')
call s:define('headline', '\v^(\*+)\s?('.s:todo_keywords_regex.')?\s?(\[\d+\])? ([^:]*)( :.*:)?$')
call s:define('metadata', '\v^(DEADLINE|CLOSED|SCHEDULED): ([\<\[])(.*)([\>\]])$')
call s:define('properties', '\v^:PROPERTIES:$')
call s:define('logbook', '\v^:LOGBOOK:$')
call s:define('properties_content', '\v^:(END)@!([^:]+):\s*(.*)$')
call s:define('logbook_clock', '\v^CLOCK: \[([^\]]*)\](--\[([^\]]*)\])?( \=\>\s+(\d{1,2}:\d{2}))?')
call s:define('logbook_state_change', '\v^- State "([^"]*)"\s+from "([^"]*)"\s+\[([^\]]*)\]')
call s:define('drawer_end', '\v^:END:$')
call s:define('line', '\v^(.*)$')

function! s:type_order(a, b)
  return s:syntax[a:a].order - s:syntax[a:b].order
endfunction

function! s:type_keys()
  return sort(keys(s:syntax), 's:type_order')
endfunction

function! s:type(line)
  for key in s:type_keys()
    if s:syntax[key].matches(a:line)
      return key
    endif
  endfor
endfunction

function! s:tokenize_line(lnum, line)
  let token = {}
  let token.lnum = a:lnum
  let token.type = s:type(a:line)
  let token.content = s:syntax[token.type].matchlist(a:line)
  return token
endfunction

" Public Api {{{1
function! dotoo#parser#lexer#syntax()
  return s:syntax
endfunction

function! dotoo#parser#lexer#tokenize(lines) abort
  let lnum = 1
  let tokens = []
  for line in a:lines
    call add(tokens, s:tokenize_line(lnum, line))
    let lnum += 1
  endfor
  return tokens
endfunction
