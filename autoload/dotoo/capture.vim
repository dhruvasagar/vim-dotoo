if exists('g:autoloaded_dotoo_capture')
  finish
endif
let g:autoloaded_dotoo_capture = 1

call dotoo#utils#set('dotoo#capture#refile', expand('~/Documents/dotoo-files/refile.dotoo'))
call dotoo#utils#set('dotoo#capture#clock', 1)
call dotoo#utils#set('dotoo#capture#templates', [
      \ ['t', 'Todo', ['* TODO %?',
      \                'DEADLINE: [%(strftime(g:dotoo#time#datetime_format))]']],
      \ ['n', 'Note', ['* %? :NOTE:']],
      \ ['m', 'Meeting', ['* MEETING with %? :MEETING:']],
      \ ['p', 'Phone call', ['* PHONE %? :PHONE:']],
      \ ['h', 'Habit', ['* NEXT %?',
      \                'SCHEDULED: [%(strftime(g:dotoo#time#date_day_format)) +1m]',
      \                ':PROPERTIES:',
      \                ':STYLE: habit',
      \                ':REPEAT_TO_STATE: NEXT',
      \                ':END:']]
      \ ])

function! s:capture_menu()
  let menu_lines = map(deepcopy(g:dotoo#capture#templates), '"(".v:val[0].") ".v:val[1]')
  let acceptable_input = '[' . join(map(deepcopy(g:dotoo#capture#templates), 'v:val[0]'),'') . ']'
  call add(menu_lines, 'Select capture template: ')
  return dotoo#utils#getchar(join(menu_lines, "\n"), acceptable_input)
endfunction

function! s:get_selected_template(short_key)
  for template in deepcopy(g:dotoo#capture#templates)
    if template[0] ==# a:short_key | return template | endif
  endfor
  return []
endfunction

function! s:capture_template_eval_line(template)
  if a:template =~# '%(.*)'
    return substitute(a:template, '%(\(.*\))', '\=eval(submatch(1))', 'g')
  endif
  return a:template
endfunction

function! s:capture_template_eval(template)
  return map(a:template, 's:capture_template_eval_line(v:val)')
endfunction

let s:capture_tmp_file = tempname()
function! s:capture_edit(cmd)
  silent exe a:cmd s:capture_tmp_file
  :%delete
  setl nobuflisted nofoldenable
  setf dotoocapture
endfunction

function! s:capture_select()
  let old_search = @/
  call search('%?', 'b')
  exe "normal! \<Esc>viw\<C-G>"
  let @/ = old_search
endfunction

function! dotoo#capture#capture()
  let selected = s:capture_menu()
  if !empty(selected)
    let template = s:get_selected_template(selected)
    let template_lines = template[2]
    let template_lines = s:capture_template_eval(template_lines)
    call s:capture_edit('split')
    let dotoo = dotoo#parser#parse({'lines': template_lines, 'force': 1})
    let headline = dotoo.headlines[0]
    let todo = headline.todo
    if g:dotoo#capture#clock | call dotoo#clock#start(headline, 0) | endif
    call headline.change_todo(todo) " work around clocking todo state change
    call setline(1, headline.serialize())
    call s:capture_select()
  endif
endfunction
