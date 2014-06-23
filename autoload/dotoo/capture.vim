if exists('g:autoloaded_dotoo_capture')
  finish
endif
let g:autoloaded_dotoo_capture = 1

call dotoo#utils#set('dotoo#capture#refile', expand('~/Documents/org-files/refile.dotoo'))
call dotoo#utils#set('dotoo#capture#templates', [
      \ ['t', 'Todo', '* TODO %?'],
      \ ['n', 'Note', '* %? :NOTE:'],
      \ ['m', 'Meeting', '* MEETING with %? :MEETING:'],
      \ ['p', 'Phone call', '* PHONE %? :PHONE:'],
      \ ['h', 'Habit', ['* NEXT %?',
      \                'SCHEDULED: [%(strftime(g:dotoo#time#datetime_format)) +1m]',
      \                ':PROPERTIES:',
      \                ':STYLE: habit',
      \                ':REPEAT_TO_STATE: NEXT',
      \                ':END:']
      \ ]])

function! s:get_selected_template(short_key)
  for template in deepcopy(g:dotoo#capture#templates)
    if template[0] ==# a:short_key | return template | endif
  endfor
  return []
endfunction

function! s:eval_template_item(template)
  if a:template =~# '%(.*)'
    return substitute(a:template, '%(\(.*\))', '\=eval(submatch(1))', 'g')
  endif
  return a:template
endfunction

function! s:capture_eval(template)
  if type(a:template) == type('')
    return s:eval_template_item(a:template)
  elseif type(a:template) == type([])
    return map(a:template, 's:eval_template_item(v:val)')
  endif
  return a:template
endfunction

function! s:capture_edit(cmd)
  silent exe a:cmd g:dotoo#capture#refile
  setl nobuflisted
  setf dotoocapture
endfunction

function! s:save_capture_template(template)
  let tmpl = s:capture_eval(a:template)
  if expand('%:e') !=# 'dotoo'
    call s:capture_edit('split')
  endif
  call append(line('$') == 1 ? 0 : '$', tmpl)
  call search('%?', 'b')
  exe "normal! \<esc>viw\<c-g>"
endfunction

function! s:capture_menu()
  let menu_lines = map(deepcopy(g:dotoo#capture#templates), '"(".v:val[0].") ".v:val[1]')
  let acceptable_input = '[' . join(map(deepcopy(g:dotoo#capture#templates), 'v:val[0]'),'') . ']'
  call add(menu_lines, 'Select capture template: ')
  return dotoo#utils#getchar(join(menu_lines, "\n"), acceptable_input)
endfunction

function! dotoo#capture#capture()
  let selected = s:capture_menu()
  let template = s:get_selected_template(selected)
  if !empty(template)
    call s:save_capture_template(template[2])
  endif
endfunction
