if exists('g:autoloaded_dotoo_capture')
  finish
endif
let g:autoloaded_dotoo_capture = 1

call dotoo#utils#set('dotoo#capture#refile', expand('~/Documents/dotoo-files/refile.dotoo'))
call dotoo#utils#set('dotoo#capture#clock', 1)
call dotoo#utils#set('dotoo#capture#templates', {
      \ 't': {
      \   'description': 'Todo',
      \   'lines': [
      \     '* TODO %?',
      \     'DEADLINE: [%(strftime(g:dotoo#time#datetime_format))]'
      \   ],
      \  'target': 'refile'
      \ },
      \ 'n': {
      \   'description': 'Note',
      \   'lines': ['* %? :NOTE:'],
      \ },
      \ 'm': {
      \   'description': 'Meeting',
      \   'lines': ['* MEETING with %? :MEETING:'],
      \ },
      \ 'p': {
      \   'description': 'Phone call',
      \   'lines': ['* PHONE %? :PHONE:'],
      \ },
      \ 'h': {
      \   'description': 'Habit',
      \   'lines': [
      \     '* NEXT %?',
      \     'SCHEDULED: [%(strftime(g:dotoo#time#date_day_format)) +1m]',
      \     ':PROPERTIES:',
      \     ':STYLE: habit',
      \     ':REPEAT_TO_STATE: NEXT',
      \     ':END:'
      \   ]
      \ }
      \})

function! s:capture_menu()
  let ts = deepcopy(g:dotoo#capture#templates)
  let menu_lines = values(map(deepcopy(ts), {k, t -> "(".k.") ".t.description}))
  let acceptable_input = '[' . join(keys(ts),'') . ']'
  call add(menu_lines, 'Select capture template: ')
  return dotoo#utils#getchar(join(menu_lines, "\n"), acceptable_input)
endfunction

function! s:get_selected_template(short_key)
  return get(g:dotoo#capture#templates, a:short_key, '')
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
  silent exe 'keepalt' a:cmd s:capture_tmp_file
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

function! dotoo#capture#refile_now() abort
  let dotoo = dotoo#parser#parse({'lines': getline(1,'$'), 'force': 1})
  let headline = dotoo.headlines[0]
  if g:dotoo#capture#clock
    call dotoo#clock#stop(headline)
  endif
  let target = b:capture_target
  if type(target) == v:t_dict
    call target.add_headline(headline)
    call target.save('edit')
  else
    let btarget = bufname(target)
    if empty(btarget)
      if dotoo#utils#is_dotoo_file(target)
        let btarget = target
      else
        let btarget = g:dotoo#capture#refile
      endif
    endif
    call writefile(headline.serialize(), btarget, 'a')
  endif
endfunction

function! dotoo#capture#capture()
  let selected = s:capture_menu()
  if !empty(selected)
    let template = s:get_selected_template(selected)
    let template_lines = template.lines
    let capture_target = get(template, 'target', g:dotoo#capture#refile)
    let capture_target_headline = dotoo#agenda#get_headline_by_title(capture_target)
    let template_lines = s:capture_template_eval(template_lines)
    call s:capture_edit('split')
    let dotoo = dotoo#parser#parse({'lines': template_lines, 'force': 1})
    let headline = dotoo.headlines[0]
    let todo = headline.todo
    if g:dotoo#capture#clock | call dotoo#clock#start(headline, 0) | endif
    call headline.change_todo(todo) " work around clocking todo state change
    call setline(1, headline.serialize())
    let b:capture_target = capture_target_headline
    call s:capture_select()
  endif
endfunction
