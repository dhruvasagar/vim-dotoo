if exists('g:autoloaded_dotoo_parser_headline')
  finish
endif
let g:autoloaded_dotoo_parser_headline = 1

let s:syntax = dotoo#parser#lexer#syntax()
let s:headline_methods = {}
function! s:headline_methods.done() dict
  return self.todo =~? join(g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, '|'):], '\|')
endfunction

function! s:headline_methods.repeatable() dict
  if has_key(self.metadata, 'deadline')
    return !empty(get(self.metadata.deadline.datetime, 'repeat', ''))
  elseif has_key(self.metadata, 'scheduled')
    return !empty(get(self.metadata.scheduled.datetime, 'repeat', ''))
  endif
  return 0
endfunction

function! s:headline_methods.log_state_change() dict
  if self.done() 
    call self.metadata.set_future_date()
    if self.repeatable()
      let prev_todo = self.todo
      let self.todo = self.properties.repeat_to_state()
      call self.logbook.log({
            \ 'type': s:syntax.logbook_state_change.type,
            \ 'to': prev_todo, 'from': self.todo,
            \ 'time': dotoo#time#new()
            \ })
    else
      call self.metadata.close()
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

function! s:headline_methods.metadate(...) dict
  let date = a:0 ? a:1 : dotoo#time#new()
  let force = a:0 == 2 ? a:2 : 0
  let metadate = self.next_deadline(date, force)
  if empty(metadate)
    let metadate = self.metadata.closed
  endif
  return metadate
endfunction

function! s:headline_methods.next_deadline(...) dict
  let date = a:0 ? a:1 : dotoo#time#new()
  let force = a:0 == 2 ? a:2 : 0
  if has_key(self.metadata, 'deadline')
    return self.metadata.deadline.next_repeat(date, force)
  elseif has_key(self.metadata, 'scheduled')
    return self.metadata.scheduled.next_repeat(date, force)
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

function! s:headline_methods.line() dict
  let headline = []
  call add(headline, repeat('*', self.level))
  if !empty(self.todo) | call add(headline, self.todo) | endif
  if !empty(self.priority) | call add(headline, self.priority) | endif
  call add(headline, self.title)
  if !empty(self.tags) | call add(headline, self.tags) | endif
  return join(headline)
endfunction

function! s:headline_methods.serialize() dict
  let lines = []
  call add(lines, self.line())
  call add(lines, self.content)
  call add(lines, self.metadata.serialize())
  call extend(lines, self.properties.serialize())
  call extend(lines, self.logbook.serialize())
  call extend(lines, map(self.headlines, 'v:val.serialize()'))
  call filter(lines, '!empty(v:val)')
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

function! s:sort_deadlines(h1, h2)
  return a:h1.next_deadline().diff(a:h2.next_deadline())
endfunction

function! dotoo#parser#headline#new(...) abort
  let file = a:0 ? a:1 : ''
  let tokens = a:0 == 2 ? a:2 : []
  let token = len(tokens) ? remove(tokens, 0) : {'lnum': 0, 'content': map(range(5),'""')}

  let headline =  {
        \ 'file': file,
        \ 'level': len(token.content[0]),
        \ 'todo': token.content[1],
        \ 'priority': token.content[2],
        \ 'title': token.content[3],
        \ 'tags': token.content[4],
        \ 'lnum': token.lnum,
        \ 'content': '', 'metadata': {}, 'properties': {}, 'logbook': {}, 'headlines': []
        \ }

  if has_key(token, 'type')
    while len(tokens)
      let token = remove(tokens, 0)
      if token.type ==# s:syntax.line.type
        let headline.content .= token.content[0]
      elseif token.type == s:syntax.metadata.type
        let metadata = dotoo#parser#metadata#new(token)
        call extend(headline, metadata)
        call extend(headline.metadata, metadata)
      elseif token.type == s:syntax.properties.type
        call extend(headline.properties,  dotoo#parser#properties#new(tokens))
      elseif token.type == s:syntax.logbook.type
        call extend(headline.logbook, dotoo#parser#logbook#new(tokens))
      elseif token.type == s:syntax.headline.type
        call insert(tokens, token)
        break
      endif
    endwhile
  endif

  call extend(headline, s:headline_methods)
  let headline.id = sha256(string(headline))
  return headline
endfunction
