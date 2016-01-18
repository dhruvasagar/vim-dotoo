if exists('g:autoloaded_dotoo_parser_headline')
  finish
endif
let g:autoloaded_dotoo_parser_headline = 1

let s:syntax = dotoo#parser#lexer#syntax()
let s:headline_methods = {}
function! s:headline_methods.done() dict
  return self.todo =~? join(g:dotoo#parser#todo_keywords[index(g:dotoo#parser#todo_keywords, '|'):], '\|')
endfunction

function! s:headline_methods.bare_object() dict
  let bare_object = deepcopy(self)
  call remove(bare_object, 'headlines')
  return bare_object
endfunction

function! s:headline_methods.repeatable() dict
  if has_key(self.metadata, 'deadline')
    return self.metadata.deadline.repeatable()
  elseif has_key(self.metadata, 'scheduled')
    return self.metadata.scheduled.repeatable()
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
  elseif type(a:index) == type('') && !empty(a:index)
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

function! s:headline_methods.metadate() dict
  let metadate = self.deadline()
  if empty(metadate) && has_key(self.metadata, 'closed')
    return self.metadata.closed
  endif
  return metadate
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
  call extend(lines, self.content)
  call add(lines, self.metadata.serialize())
  call extend(lines, self.properties.serialize())
  call extend(lines, self.logbook.serialize())
  let child_headlines = map(deepcopy(self.headlines), 'v:val.serialize()')
  call map(child_headlines, 'extend(lines, v:val)')
  call filter(lines, '!empty(v:val)')
  return lines
endfunction

function! s:headline_methods.is_split_open() dict
  return get(self, 'split_open', 0)
endfunction

function! s:headline_methods.open() dict
  if expand('%:p') !=# self.file
    let self.split_open = 1
    let self.split_winnr = winnr()
    silent exe 'noauto split' self.file
  endif
endfunction

function! s:headline_methods.close() dict
  if self.is_split_open()
    quit
    exec self.split_winnr . 'wincmd w'
    call remove(self, 'split_open')
    call remove(self, 'split_winnr')
  endif
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
  silent exec self.lnum.','.self.last_lnum.':delete'
endfunction

function! s:headline_methods.undo() dict
  call self.open()
  normal! u
  call self.close()
endfunction

function! s:headline_methods.is_clocking() dict
  return self.logbook.is_clocking()
endfunction

function! s:headline_methods.start_clock(...) dict
  let persist = a:0 ? a:1 : 1
  if !self.properties.is_habit() && !self.is_clocking()
    call self.logbook.start_clock()
    if persist | call self.save() | endif
  endif
endfunction

function! s:headline_methods.stop_clock(...) dict
  let persist = a:0 ? a:1 : 1
  if !self.properties.is_habit() && self.is_clocking()
    call self.logbook.stop_clock()
    if persist | call self.save() | endif
  endif
endfunction

function! s:headline_methods.log_summary(time, span) dict
  return self.logbook.summary(a:time, a:span)
endfunction

function! s:headline_methods.equal(other) dict
  if empty(a:other) | return 0 | endif
  if !has_key(a:other, 'todo_title') || !has_key(a:other, 'level') || !has_key(a:other, 'lnum') || !has_key(a:other, 'file')
    return 0
  endif
  return self.todo_title() == a:other.todo_title() && self.level == a:other.level && self.lnum == a:other.lnum && self.file == a:other.file
endfunction

function! s:headline_methods.add_headline(headline) dict
  let a:headline.level = self.level + 1
  call add(self.headlines, a:headline)
endfunction

function! s:headline_methods.insert_headline(headline) dict
  let a:headline.level = self.level + 1
  call insert(self.headlines, a:headline)
endfunction

function! s:headline_methods.remove_headline(headline) dict
  let index = index(self.headlines, a:headline)
  call remove(self.headlines, index)
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
        \ 'key': fnamemodify(file, ':p:t:r'),
        \ 'file': file,
        \ 'level': len(token.content[0]),
        \ 'todo': token.content[1],
        \ 'priority': token.content[2],
        \ 'title': token.content[3],
        \ 'tags': dotoo#utils#strip(token.content[4]),
        \ 'lnum': token.lnum,
        \ 'content': [],
        \ 'metadata': dotoo#parser#metadata#new(),
        \ 'properties': dotoo#parser#properties#new(),
        \ 'logbook': dotoo#parser#logbook#new(),
        \ 'headlines': []
        \ }

  if has_key(token, 'type')
    while len(tokens)
      let token = remove(tokens, 0)
      if token.type ==# s:syntax.line.type
        call add(headline.content, token.content[0])
      elseif token.type == s:syntax.metadata.type
        call extend(headline.metadata, dotoo#parser#metadata#new(token))
      elseif token.type == s:syntax.properties.type
        call extend(headline.properties, dotoo#parser#properties#new(tokens))
      elseif token.type == s:syntax.logbook.type
        call extend(headline.logbook, dotoo#parser#logbook#new(tokens))
      elseif token.type == s:syntax.headline.type
        call insert(tokens, token)
        if len(token.content[0]) > headline.level
          let hl = dotoo#parser#headline#new(file, tokens)
          call add(headline.headlines, hl)
        else
          break
        endif
      endif
    endwhile
  endif

  call extend(headline, s:headline_methods)
  let headline.last_lnum = headline.lnum + len(headline.serialize()) - 1
  let headline.id = sha256(string(headline))

  " Has side-effects
  " if headline.is_clocking()
  "   call dotoo#clock#start(headline)
  " endif

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
