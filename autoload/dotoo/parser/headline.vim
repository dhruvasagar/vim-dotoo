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

function! s:headline_methods.deadline() dict
  if has_key(self.metadata, 'deadline')
    return self.metadata.deadline
  elseif has_key(self.metadata, 'scheduled')
    return self.metadata.scheduled
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
  call add(headline, self.todo)
  call add(headline, self.priority)
  call add(headline, self.title)
  call add(headline, self.tags)
  call filter(headline, '!empty(v:val)')
  return join(headline)
endfunction

function! s:headline_methods.serialize() dict
  let lines = []
  call add(lines, self.line())
  call add(lines, self.content)
  call add(lines, self.metadata.serialize())
  call extend(lines, self.properties.serialize())
  call extend(lines, self.logbook.serialize())
  let child_headlines = map(deepcopy(self.headlines), 'v:val.serialize()')
  call map(child_headlines, 'extend(lines, v:val)')
  call filter(lines, '!empty(v:val)')
  return lines
endfunction

function! s:headline_methods.open() dict
  silent exe 'noauto split' self.file
endfunction

function! s:headline_methods.close() dict
  quit
endfunction

function! s:headline_methods.save() dict
  let old_view = winsaveview()
  call self.open()
  call self.delete()
  call append(self.lnum-1, self.serialize())
  call self.close()
  call winrestview(old_view)
endfunction

function! s:headline_methods.delete() dict
  call self.open()
  silent exec self.lnum.','.self.last_lnum.':delete'
  call self.close()
endfunction

function! s:headline_methods.undo() dict
  call self.open()
  normal! u
  call self.close()
endfunction

function! s:headline_methods.start_clock() dict
  call self.logbook.start_clock()
  call self.save()
endfunction

function! s:headline_methods.stop_clock() dict
  call self.logbook.stop_clock()
  call self.save()
endfunction

function! s:headline_methods.equal(other) dict
  if empty(a:other) | return 0 | endif
  if !has_key(a:other, 'todo_title') || !has_key(a:other, 'level') || !has_key(a:other, 'lnum') || !has_key(a:other, 'file')
    return 0
  endif
  return self.todo_title() == a:other.todo_title() && self.level == a:other.level && self.lnum == a:other.lnum && self.file == a:other.file
endfunction

function! s:sort_deadlines(h1, h2)
  return a:h1.deadline().diff(a:h2.deadline())
endfunction

function! s:cache_headline(headline)
  if !has_key(s:headlines, a:headline.file)
    let s:headlines[a:headline.file] = {}
  endif
  let s:headlines[a:headline.file][a:headline.lnum] = a:headline
endfunction

let s:headlines = {}
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
        \ 'content': '',
        \ 'metadata': dotoo#parser#metadata#new(),
        \ 'properties': dotoo#parser#properties#new(),
        \ 'logbook': dotoo#parser#logbook#new(),
        \ 'headlines': []
        \ }

  if has_key(token, 'type')
    while len(tokens)
      let token = remove(tokens, 0)
      if token.type ==# s:syntax.line.type
        let headline.content .= token.content[0]
      elseif token.type == s:syntax.metadata.type
        call extend(headline.metadata, dotoo#parser#metadata#new(token))
      elseif token.type == s:syntax.properties.type
        call extend(headline.properties, dotoo#parser#properties#new(tokens))
      elseif token.type == s:syntax.logbook.type
        call extend(headline.logbook, dotoo#parser#logbook#new(tokens))
      elseif token.type == s:syntax.headline.type
        let headline.last_lnum = token.lnum - 1
        call insert(tokens, token)
        if len(token.content[0]) > headline.level
          call add(headline.headlines, dotoo#parser#headline#new(file, tokens))
        else
          break
        endif
      endif
    endwhile

    if !has_key(headline, 'last_lnum') | let headline.last_lnum = '$' | endif
  endif

  call extend(headline, s:headline_methods)
  let headline.id = sha256(string(headline))

  " Cache headlines for lookup
  call s:cache_headline(headline)

  return headline
endfunction

function! dotoo#parser#headline#get(...)
  let file = a:0 ? a:1 : expand('%:p')
  let lnum = a:0 == 2 ? a:2 : line('.')
  if has_key(s:headlines, file)
    return get(s:headlines[file], lnum)
  endif
endfunction
