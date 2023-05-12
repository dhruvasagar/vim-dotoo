if exists('g:autoloaded_dotoo_agenda_views_todos')
  finish
endif
let g:autoloaded_dotoo_agenda_views_todos = 1

let s:todos_deadlines = {} "{{{1
function! s:build_todos(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:todos_deadlines)
    let s:todos_deadlines = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter('empty(v:val.metadate()) && !empty(v:val.todo) && !v:val.done()')
      call dotoo#agenda#apply_filters(headlines)
      let s:todos_deadlines[dotoo.file] = headlines
    endfor
  endif
  let todos = []
  for file in keys(s:todos_deadlines)
    let key = fnamemodify(file, ':p:t:r')
    let headlines = s:todos_deadlines[file]
    for headline in headlines
      let todo = printf('%s %10s: %2s %-70s %s', '',
            \ headline.key,
            \ headline.priority,
            \ headline.todo_title(),
            \ headline.tags)
      call add(todos, todo)
    endfor
  endfor
  if empty(todos)
    call add(todos, printf('%2s %s', '', 'No Unscheduled TODOs!'))
  endif
  let header = []
  call add(header, 'Unscheduled TODOs')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(todos, join(header, ', '))
  return todos
endfunction

let s:todos_view = {
      \ 'key': 't',
      \ 'name': 'Todos',
      \}
function! s:todos_view.content(dotoos, ...) dict "{{{1
  let force = a:0 ? a:1 : 0
  return s:build_todos(a:dotoos, force)
endfunction

function! dotoo#agenda_views#todos#register() "{{{1
  call dotoo#agenda#register_view(s:todos_view)
endfunction
