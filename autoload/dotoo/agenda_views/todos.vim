if exists('g:autoloaded_dotoo_agenda_views_todos')
  finish
endif
let g:autoloaded_dotoo_agenda_views_todos = 1

let s:todos_deadlines = {} "{{{1
function! s:build_todos(dotoos, ...)
  let force = a:0 ? a:1 : 0
  if force || empty(s:todos_deadlines)
    let s:todos_deadlines = {}
    call dotoo#agenda#headlines([])
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter('empty(v:val.metadate()) && !empty(v:val.todo)')
      let s:todos_deadlines[dotoo.key] = headlines
    endfor
  endif
  let todos = []
  call dotoo#agenda#headlines([])
  for key in keys(s:todos_deadlines)
    let headlines = s:todos_deadlines[key]
    call dotoo#agenda#headlines(headlines, 1)
    for headline in headlines
      let todo = printf('%s %10s: %-70s %s', '',
            \ key,
            \ headline.todo_title(),
            \ headline.tags)
      call add(todos, todo)
    endfor
  endfor
  if empty(todos)
    call add(todos, printf('%2s %s', '', 'No Unscheduled TODOs!'))
  endif
  call insert(todos, 'Unscheduled TODOs')
  return todos
endfunction

let s:view_name = 'todos' "{{{1
let s:todos_view = {}
function! s:todos_view.content(dotoos,...) dict "{{{1
  let force = a:0 ? a:1 : 0
  return s:build_todos(a:dotoos, force)
endfunction

function! dotoo#agenda_views#todos#register() "{{{1
  call dotoo#agenda#register_view(s:view_name, s:todos_view)
endfunction
