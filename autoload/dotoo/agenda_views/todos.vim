if exists('g:autoloaded_dotoo_agenda_views_todos')
  finish
endif
let g:autoloaded_dotoo_agenda_views_todos = 1

function! s:set_todos_modified(mod)
  let &l:modified = a:mod
endfunction

let s:todos_deadlines = {}
let s:todos_headlines = []
function! s:build_todos(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let add_todos_headlines = force || empty(s:todos_headlines)
  if force || empty(s:todos_deadlines)
    let s:todos_deadlines = {}
    let s:todos_headlines = []
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter('empty(v:val.metadate()) && !empty(v:val.todo)')
      let s:todos_deadlines[dotoo.key] = headlines
    endfor
  endif
  let todos = []
  for key in keys(s:todos_deadlines)
    let headlines = s:todos_deadlines[key]
    if add_todos_headlines | call extend(s:todos_headlines, headlines) | endif
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
  return todos
endfunction

function! s:todos_view(todos)
  let old_view = winsaveview()
  call dotoo#agenda#edit('pedit!')
  setl modifiable
  silent normal! ggdG
  silent call setline(1, 'Unscheduled TODOs')
  silent call setline(2, a:todos)
  setl nomodified nomodifiable
  call winrestview(old_view)
endfunction

function! s:goto_headline(cmd)
  let headline = s:todos_headlines[line('.')-2]
  if a:cmd ==# 'edit' | quit | split | endif
  exec a:cmd '+'.headline.lnum headline.file
  if empty(&filetype) | edit | endif
  normal! zv
endfunction

function! s:start_headline_clock()
  let old_view = winsaveview()
  call s:goto_headline('edit')
  call dotoo#clock#start()
  call dotoo#agenda#refresh_view()
  call s:set_todos_modified(1)
  call winrestview(old_view)
endfunction

function! s:stop_headline_clock()
  let old_view = winsaveview()
  call s:goto_headline('edit')
  call dotoo#clock#stop()
  call dotoo#agenda#refresh_view()
  call s:set_todos_modified(1)
  call winrestview(old_view)
endfunction

function! s:change_headline_todo()
  let headline = s:todos_headlines[line('.')-2]
  let selected = dotoo#utils#change_todo_menu()
  if !empty(selected)
    call headline.change_todo(selected)
    let old_view = winsaveview()
    call headline.save()
    call dotoo#agenda#refresh_view(0)
    call s:set_todos_modified(getbufvar(bufnr('#'), '&modified'))
    call winrestview(old_view)
  endif
endfunction

function! s:undo_headline_change()
  let headline = s:todos_headlines[line('.')-2]
  let old_view = winsaveview()
  call headline.undo()
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

let s:view_name = 'todos'
let s:todos_view = {'mapped': 0}
function! s:todos_view.map() dict
  if self.mapped | return | endif
  let self.mapped = 1
  nnoremap <buffer> <silent> <nowait> c :<C-U>call <SID>change_headline_todo()<CR>
  nnoremap <buffer> <silent> <nowait> u :<C-U>call <SID>undo_headline_change()<CR>
  nnoremap <buffer> <silent> <nowait> i :<C-U>call <SID>start_headline_clock()<CR>
  nnoremap <buffer> <silent> <nowait> o :<C-U>call <SID>stop_headline_clock()<CR>
  nnoremap <buffer> <silent> <nowait> <CR> :<C-U>call <SID>goto_headline('edit')<CR>
  nnoremap <buffer> <silent> <nowait> <C-S> :<C-U>call <SID>goto_headline('split')<CR>
  nnoremap <buffer> <silent> <nowait> <C-V> :<C-U>call <SID>goto_headline('vsplit')<CR>
  nnoremap <buffer> <silent> <nowait> <C-T> :<C-U>call <SID>goto_headline('tabe')<CR>
  nmap <buffer> <silent> <Tab> <C-V>
endfunction

function! s:todos_view.show(dotoos,...) dict "{{{2
  let force = a:0 ? a:1 : 0
  call s:todos_view(s:build_todos(a:dotoos, force))
  call self.map()
endfunction

function! dotoo#agenda_views#todos#register()
  call dotoo#agenda#register_view(s:view_name, s:todos_view)
endfunction
