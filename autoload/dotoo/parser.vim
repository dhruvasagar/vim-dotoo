if exists('g:autoloaded_dotoo_parser')
  finish
endif
let g:autoloaded_dotoo_parser = 1

let g:dotoo#parser#todo_keywords = ['WAITING',
      \ 'HOLD',
      \ 'TODO',
      \ 'NEXT',
      \ 'PHONE',
      \ 'MEETING',
      \ '|',
      \ 'CANCELLED',
      \ 'DONE']

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

let s:todo_keywords = join(filter(g:dotoo#parser#todo_keywords, 'v:val !~# "|"'), '|')
call s:define('blank', '\v^$')
call s:define('directive', '\v^#\+(\w+): (.*)$')
call s:define('headline', '\v^(\*+)\s?('.s:todo_keywords.')?\s?(\[\d+\])? ([^:]*)( :.*:)?$')
call s:define('metadata', '\v^(DEADLINE|CLOSED|SCHEDULED): \[(.*)\]$')
call s:define('properties', '\v^:PROPERTIES:$')
call s:define('logbook', '\v^:LOGBOOK:$')
call s:define('properties_content', '\v^:(END)@!([^:]+):\s*(.*)$')
call s:define('logbook_content', '\v^CLOCK: \[([^\]]*)\](--\[([^\]]*)\])?( \=\>\s+\d{1,2}:\d{2})?')
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
function! s:parse_line(token)
  return a:token.content[0]
endfunction

function! s:parse_directive(token)
  let directive = {}
  let directive[a:token.content[0]] = a:token.content[1]
  return directive
endfunction

function! s:sort_deadlines(h1, h2)
  return a:h1.next_deadline().diff(a:h2.next_deadline())
endfunction

function! s:parse_headline(token)
  let headline =  {
        \ 'level': len(a:token.content[0]),
        \ 'todo': a:token.content[1],
        \ 'priority': a:token.content[2],
        \ 'title': a:token.content[3],
        \ 'tags': a:token.content[4],
        \ 'lnum': a:token.lnum,
        \ 'content': '', 'metadata': {}, 'properties': {}, 'logbook': [], 'headlines': []
        \ }

  func headline.done() dict
    return self.todo =~? join(g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, '|'):], '\|')
  endfunc

  func headline.change_todo(index) dict
    if type(a:index) == type(0)
      let self.todo = g:dotoo#parser#todo_keywords[a:index]
    elseif type(a:index) == type('')
      let todo = get(filter(copy(g:dotoo#parser#todo_keywords), 'v:val =~? "^".a:index'), 0)
      if todo || !empty(todo)
        let self.todo = g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, todo)]
      endif
    endif
  endfunc

  func headline.select(string) dict
    let headlines = []
    if has_key(self, a:string) && !self.done() | let headlines += [self] | endif
    for headline in self.headlines
      let headlines += headline.select(a:string)
    endfor
    return sort(headlines, 's:sort_deadlines')
  endfunc

  func headline.next_deadline(...) dict
    let force = a:0 ? a:1 : 0
    if has_key(self, 'deadline')
      return self.deadline.next_repeat(force)
    endif
    return ''
  endfunc

  func headline.todo_title() dict
    if empty(self.todo)
      return self.title
    else
      return self.todo . ' ' . self.title
    endif
  endfunc

  return headline
endfunction

function! s:parse_metadata(token)
  let metadata = {}
  let metadata[tolower(a:token.content[0])] = dotoo#time#new(a:token.content[1])
  return metadata
endfunction

function! s:parse_properties(headline, index, tokens)
  let index = a:index + 1
  if index < len(a:tokens) | let token = a:tokens[index] | endif
  while index < len(a:tokens) && token.type ==# s:syntax.properties_content.type
    let content = {}
    let content.lnum = token.lnum
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
    let log.start = dotoo#time#new(token.content[0])
    let log.end = dotoo#time#new(token.content[2])
    let log.lnum = token.lnum
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

let s:dotoos = {}
let s:parsed_tokens = {}
function! dotoo#parser#parse(file, ...)
  if !filereadable(a:file) | return | endif
  let force = a:0 ? a:1 : 0
  let key = fnamemodify(a:file, ':p:t:r')
  if has_key(s:dotoos, key) && !force
    return s:dotoos[key]
  else
    if force || !has_key(s:dotoos, key)
      let root_headline = s:parse_headline({'lnum': 0, 'content': ['','','','','']})
      let s:dotoos[key] = { 'key': key, 'file': a:file, 'directives': {},
                          \ 'blank_lines': [], 'root_headline': root_headline }
      let s:parsed_tokens[key] = {}
    endif
    let dotoo = s:dotoos[key]
    let index = 0
    let tree = {}
    let tokens = s:tokenize(a:file)
    while index < len(tokens)
      let token = tokens[index]
      if has_key(s:parsed_tokens[key], token.lnum) && s:parsed_tokens[key][token.lnum] == token
        let index += 1
        continue
      else
        let s:parsed_tokens[key][token.lnum] = token
      endif
      if token.type ==# s:syntax.directive.type
        call extend(dotoo.directives, s:parse_directive(token))
        let index += 1
      elseif token.type ==# s:syntax.blank.type
        call add(dotoo.blank_lines, token.lnum)
        let index += 1
      elseif token.type ==# s:syntax.headline.type
        let headline = s:parse_headline(token)
        let headline.file = dotoo.file
        let parent = headline.level == 1 ? dotoo.root_headline : tree[headline.level - 1]
        let tree[headline.level] = headline
        let index = s:parse_headline_content(headline, index, tokens)
        call add(parent.headlines, headline)
      else
        let index += 1
      endif
    endwhile

    func dotoo.select(string) dict
      return self.root_headline.select(a:string)
    endfunc

    return dotoo
  endif
endfunction
