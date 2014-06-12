if exists('g:autoloaded_dotoo_parser')
  finish
endif
let g:autoloaded_dotoo_parser = 1

" Lexer {{{1
let s:syntax_methods = {}
function! s:syntax_methods.matches(line) dict
  return a:line =~# self.pattern
endfunction

function! s:syntax_methods.matchlist(line) dict abort
  return matchlist(a:line, self.pattern)[1:]
endfunction

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
call s:define('metadata', '\v^(DEADLINE|CLOSED|SCHEDULED): \[(.*)\]$')
call s:define('properties', '\v^:PROPERTIES:$')
call s:define('logbook', '\v^:LOGBOOK:$')
call s:define('properties_content', '\v^:(END)@!([^:]+):\s*(.*)$')
call s:define('logbook_clock', '\v^CLOCK: \[([^\]]*)\](--\[([^\]]*)\])?( \=\>\s+\d{1,2}:\d{2})?')
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

let s:headline_methods = {}
function! s:headline_methods.done() dict
  return self.todo =~? join(g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, '|'):], '\|')
endfunction

function! s:headline_methods.log_state_change() dict
  if self.done() && get(self.properties, 'STYLE', '') == 'habit'
    let self.properties['LAST_REPEAT'] = '['.dotoo#time#new().to_string(g:dotoo#time#datetime_format).']'
    let repeat_to_state = get(self.properties, 'REPEAT_TO_STATE', '')
    let todo = self.todo
    if !empty(repeat_to_state)
      let self.todo = repeat_to_state
    endif
    let log = {
          \ 'type': s:syntax.logbook_state_change.type,
          \ 'to': todo, 'from': self.todo,
          \ 'time': dotoo#time#new()
          \ }
    call insert(self.logbook, log)
    if has_key(self, 'deadline')
      let repeat = get(self.deadline.datetime, 'repeat', '')
      let self.deadline = self.deadline.future_repeat()
      let self.deadline.datetime.repeat = repeat
    elseif has_key(self, 'scheduled')
      let repeat = get(self.scheduled.datetime, 'repeat', '')
      let self.scheduled = self.scheduled.future_repeat()
      let self.scheduled.datetime.repeat = repeat
    endif
  endif
endfunction

function! s:headline_methods.change_todo(index) dict
  if type(a:index) == type(0)
    let self.todo = g:dotoo#parser#todo_keywords[a:index]
  elseif type(a:index) == type('')
    let todo = get(filter(copy(g:dotoo#parser#todo_keywords), 'v:val =~? "^".a:index'), 0)
    if todo || !empty(todo)
      let self.todo = g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, todo)]
    endif
  endif
  call self.log_state_change()
endfunction

function! s:headline_methods.filter(expr) dict
  let headlines = []
  let expr = substitute(a:expr, 'v:val', 'self', 'g')
  if eval(expr)
    call add(headlines, self)
  endif
  for headline in self.headlines
    let headlines += headline.filter(a:expr)
  endfor
  return sort(headlines, 's:sort_deadlines')
endfunction

function! s:headline_methods.next_deadline(...) dict
  let date = a:0 ? a:1 : dotoo#time#new()
  let force = a:0 == 2 ? a:2 : 0
  if has_key(self, 'deadline')
    return self.deadline.next_repeat(date, force)
  elseif has_key(self, 'scheduled')
    return self.scheduled.next_repeat(date, force)
  endif
  return ''
endfunction

function! s:headline_methods.todo_title() dict
  if empty(self.todo)
    return self.title
  else
    return self.todo . ' ' . self.title
  endif
endfunction

function! s:headline_methods.serialize() dict
  let lines = []
  let headline = []
  call add(headline, repeat('*', self.level))
  if !empty(self.todo) | call add(headline, self.todo) | endif
  if !empty(self.priority) | call add(headline, self.priority) | endif
  call add(headline, self.title)
  if !empty(self.tags) | call add(headline, self.tags) | endif
  call add(lines, join(headline))
  if !empty(self.content)
    call add(lines, self.content)
  endif
  if has_key(self, 'deadline')
    call add(lines, 'DEADLINE: ['.self.deadline.to_string(1).']')
  elseif has_key(self, 'scheduled')
    call add(lines, 'SCHEDULED: ['.self.deadline.to_string(1).']')
  elseif has_key(self, 'closed')
    call add(lines, 'CLOSED: ['.self.deadline.to_string().']')
  endif
  if !empty(self.properties)
    let properties = []
    for property in items(self.properties)
      call add(properties, ':'.property[0].': '.property[1])
    endfor
    call add(lines, ':PROPERTIES:')
    let lines += properties
    call add(lines, ':END:')
  endif
  if !empty(self.logbook)
    call add(lines, ':LOGBOOK:')
    for log in self.logbook
      if log.type == s:syntax.logbook_clock.type
        let diff_time = log['end'].diff_time(log['start']).to_string('%H:%M')
        call add(lines, 'CLOCK: [' .
              \ log['start'].to_string(g:dotoo#time#datetime_format) .
              \ '--' .
              \ log['end'].to_string(g:dotoo#time#datetime_format) .
              \ ' => ' . diff_time)
      elseif log.type == s:syntax.logbook_state_change.type
        call add(lines, '- State ' .
              \ '"'.log['to'].'"' .
              \ ' from ' .
              \ '"'.log['from'].'"' .
              \ ' [' . log['time'].to_string(g:dotoo#time#datetime_format) . ']')
      endif
    endfor
    call add(lines, ':END:')
  endif
  if !empty(self.headlines)
    for headline in headlines
      call add(lines, headline.serialize())
    endfor
  endif
  return lines
endfunction

function! s:headline_methods.save() dict
  exec 'buffer' self.file
  call setline(self.lnum, self.serialize())
endfunction

function! s:headline_methods.undo_save() dict
  exec 'buffer' self.file
  normal! u
endfunction

function! dotoo#parser#create_headline(...)
  let token = a:0 ? a:1 : {'lnum': 0, 'content': map(range(5),'""')}
  let headline =  {
        \ 'level': len(token.content[0]),
        \ 'todo': token.content[1],
        \ 'priority': token.content[2],
        \ 'title': token.content[3],
        \ 'tags': token.content[4],
        \ 'lnum': token.lnum,
        \ 'content': '', 'metadata': {}, 'properties': {}, 'logbook': [], 'headlines': []
        \ }
  call extend(headline, s:headline_methods)
  let headline.id = sha256(string(headline))
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
  while index < len(a:tokens) && token.type !=# s:syntax.drawer_end.type
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
  while index < len(a:tokens) && token.type !=# s:syntax.drawer_end.type
    let log = {'type': token.type}
    if token.type ==# s:syntax.logbook_clock.type
      let log.start = dotoo#time#new(token.content[0])
      let log.end = dotoo#time#new(token.content[2])
    elseif token.type ==# s:syntax.logbook_state_change.type
      let log.to = token.content[0]
      let log.from = token.content[1]
      let log.time = dotoo#time#new(token.content[2])
    endif
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
      let metadata = s:parse_metadata(token)
      call extend(a:headline, metadata)
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

let s:dotoo_methods = {}
function! s:dotoo_methods.filter(expr) dict
  return self.root_headline.filter(a:expr)
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
      let root_headline = dotoo#parser#create_headline()
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
        let headline = dotoo#parser#create_headline(token)
        let headline.file = dotoo.file
        let parent = headline.level == 1 ? dotoo.root_headline : tree[headline.level - 1]
        let tree[headline.level] = headline
        let index = s:parse_headline_content(headline, index, tokens)
        call add(parent.headlines, headline)
      else
        let index += 1
      endif
    endwhile
    call extend(dotoo, s:dotoo_methods)
    return dotoo
  endif
endfunction
