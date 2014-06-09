if exists('g:autoloaded_doto_parser')
  finish
endif
let g:autoloaded_doto_parser = 1

" Lexer {{{1
let s:syntax = {}

function! s:define(name, pattern)
  let obj = {
        \ 'type': a:name,
        \ 'pattern': a:pattern,
        \ 'order': len(s:syntax),
        \ }

  func obj.matches(line) dict
    return a:line =~# self.pattern
  endfunc

  func obj.matchlist(line) dict
    return matchlist(a:line, self.pattern)[1:]
  endfunc

  let s:syntax[a:name] = obj
endfunction

call s:define('blank', '\v^$')
call s:define('directive', '\v^#\+(\w+): (.*)$')
call s:define('headline', '\v^(\*+)\s?([A-Z]+)?\s?(\[\d+\])? ([^:]*)( :.*:)?$')
call s:define('metadata', '\v^(DEADLINE|CLOSED|SCHEDULED): \[(.*)\]$')
call s:define('properties', '\v^:PROPERTIES:$')
call s:define('logbook', '\v^:LOGBOOK:$')
call s:define('properties_content', '\v^:(END)@!([^:]+):\s*(.*)$')
call s:define('logbook_content', '\v^CLOCK: \[(.*)\]--\[(.*)\] \=\>\s+\d{1,2}:\d{2}')
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

function! s:tokenize(file) abort
  if !filereadable(a:file) | return | endif
  let lnum = 1
  let tokens = []
  let lines = readfile(a:file)
  for line in lines
    let token = {}
    let token.type = s:type(line)
    let token.lnum = lnum
    let token.content = s:syntax[token.type].matchlist(line)
    cal add(tokens, token)
    let lnum += 1
  endfor
  return tokens
endfunction

" Parser {{{1
let s:dotos = {}
function! s:parse_line(token)
  return a:token.content[0]
endfunction

function! s:parse_directive(token)
  let directive = {}
  let directive[a:token.content[0]] = a:token.content[1]
  return directive
endfunction

function! s:parse_headline(token)
  return {
        \ 'level': len(a:token.content[0]),
        \ 'todo': a:token.content[1],
        \ 'priority': a:token.content[2],
        \ 'title': a:token.content[3],
        \ 'tags': a:token.content[4],
        \ 'content': '', 'metadata': {}, 'properties': {}, 'logbook': [], 'children': []
        \ }
endfunction

function! s:parse_metadata(token)
  let metadata = {}
  let metadata[tolower(a:token.content[0])] = doto#time#new(a:token.content[1])
  return metadata
endfunction

function! s:parse_properties(headline, index, tokens)
  let index = a:index + 1
  if index < len(a:tokens) | let token = a:tokens[index] | endif
  while index < len(a:tokens) && token.type ==# s:syntax.properties_content.type
    let content = {}
    let content[token.content[1]] = token.content[2]
    cal extend(a:headline.properties, content)
    let index += 1
    if index < len(a:tokens) | let token = a:tokens[index] | endif
  endwhile
  return index
endfunction

function! s:parse_logbook(headline, index, tokens)
  let index = a:index + 1
  if index < len(a:tokens) | let token = a:tokens[index] | endif
  while index < len(a:tokens) && token.type ==# s:syntax.logbook_content.type
    let log = {}
    let log.start = doto#time#new(token.content[0])
    let log.end = doto#time#new(token.content[1])
    call add(a:headline.logbook, log)
    let index += 1
    if index < len(a:tokens) | let token = a:tokens[index] | endif
  endwhile
  return index
endfunction

function! s:parse_headline_content(headline, index, tokens)
  let index = a:index + 1
  let token = a:tokens[index]
  while index < len(a:tokens) && token.type !=# s:syntax.headline.type
    if token.type ==# s:syntax.line.type
      let a:headline.content .= s:parse_line(token)
    elseif token.type ==# s:syntax.metadata.type
      call extend(a:headline, s:parse_metadata(token))
    elseif token.type ==# s:syntax.properties.type
      let index = s:parse_properties(a:headline, index, a:tokens)
    elseif token.type ==# s:syntax.logbook.type
      let index = s:parse_logbook(a:headline, index, a:tokens)
    endif
    let index += 1
    if index < len(a:tokens) | let token = a:tokens[index] | endif
  endwhile
  return index
endfunction

let s:parsed_tokens = {}
function! doto#parser#parse(file, ...)
  let force = a:0 ? a:1 : 0
  let key = fnamemodify(a:file, ':p:t:r')
  if has_key(s:dotos, key) && !force
    return s:dotos[key]
  else
    if !has_key(s:dotos, key)
      let s:dotos[key] = {'directives': {}, 'headlines': []}
    endif
    if !has_key(s:parsed_tokens, key)
      let s:parsed_tokens[key] = {}
    endif
    if !filereadable(a:file) | return | endif
    let index = 0
    let tree = {}
    let tokens = s:tokenize(a:file)
    while index < len(tokens)
      let token = tokens[index]
      if has_key(s:parsed_tokens, token.lnum) && s:parsed_tokens[token.lnum] == token
        let index += 1
        continue
      else
        let s:parsed_tokens[token.lnum] = token
      endif
      if token.type ==# s:syntax.directive.type
        call extend(s:dotos[key].directives, s:parse_directive(token))
        let index += 1
      elseif token.type ==# s:syntax.blank.type
        call add(s:dotos[key].headlines, '')
        let index += 1
      elseif token.type ==# s:syntax.headline.type
        let headline = s:parse_headline(token)
        let parent = headline.level == 1 ? s:dotos[key].headlines : tree[headline.level - 1].children
        let tree[headline.level] = headline
        let index = s:parse_headline_content(headline, index, tokens)
        call add(parent, headline)
      else
        let index += 1
      endif
    endwhile
    return s:dotos[key]
  endif
endfunction
