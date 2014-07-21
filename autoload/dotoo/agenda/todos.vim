let s:plugin_name = 'todos'
let s:todos_plugin = {'showing': 0, 'mapped': 0}
function! s:todos_plugin.map() dict
  if self.mapped | return | endif
  let self.mapped = 1
  exec 'nnoremap <buffer> <silent> <nowait> T :<C-U>call dotoo#agenda#toggle_agenda_plugin("' . s:plugin_name . '")<CR>'
endfunction

function! s:todos_plugin.build_todos_list(dotoo_values)
  let todos = []
  " For plugin's header line
  call dotoo#agenda#add_headline('')
  for dotoo in values(a:dotoo_values)
    let headlines = dotoo.filter('empty(v:val.metadate()) && !empty(v:val.todo)')
    for headline in headlines
      let todo = printf('%s %10s: %-70s %s', '',
            \ dotoo.key,
            \ headline.todo_title(),
            \ headline.tags)
      call add(todos, todo)
      call dotoo#agenda#add_headline(headline)
    endfor
  endfor
  return todos
endfunction

function! s:todos_plugin.view(todos)
  setl modifiable
  if has_key(self, 'start_line') && has_key(self, 'end_line')
    silent! exe self.start_line.','.self.end_line.':delete'
    call remove(self, 'start_line')
    call remove(self, 'end_line')
  endif
  if self.showing
    let self.start_line = line('$') + 1
    let lnum = self.start_line
    let lines = ['Unscheduled Todos:']
    if empty(a:todos)
      call add(lines, 'No unscheduled todos')
    else
      call extend(lines, a:todos)
    endif
    silent call append(self.start_line - 1, lines)
    let self.end_line = self.start_line + len(lines) - 1
  endif
  setl nomodified nomodifiable
endfunction

function! s:todos_plugin.show(date, agenda_dotoos) dict "{{{2
  call self.map()
  let todos = self.build_todos_list(a:agenda_dotoos)
  call self.view(todos)
endfunction

function! s:todos_plugin.toggle(date, agenda_dotoos) dict
  let self.showing = !self.showing
  call self.show(a:date, a:agenda_dotoos)
endfunction

function! dotoo#agenda#todos#register_agenda_plugin()
  call dotoo#agenda#register_agenda_plugin(s:plugin_name, s:todos_plugin)
endfunction
