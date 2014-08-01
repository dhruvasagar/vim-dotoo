if exists('g:autoloaded_dotoo_utils')
  finish
endif
let g:autoloaded_dotoo_utils = 1

function! dotoo#utils#set(opt, val)
  if !exists('g:'.a:opt)
    let g:{a:opt} = a:val
  endif
endfunction

function! dotoo#utils#strip(string)
  return matchstr(a:string, '^\s*\zs.\{-}\ze\s*$')
endfunction

function! dotoo#utils#getchar(prompt, accept)
  let old_cmdheight = &cmdheight
  let &cmdheight = len(split(a:prompt, "\n"))
  echon a:prompt
  let char = nr2char(getchar())
  let &cmdheight = old_cmdheight
  redraw!
  if char =~? a:accept | return char | endif
  return ''
endfunction

function! dotoo#utils#flatten(items)
  let flat_list = []
  let items = deepcopy(a:items)
  for item in items
    if type(item) == type([])
      let flat_list += dotoo#utils#flatten(item)
    else
      call add(flat_list, item)
    endif
  endfor
  return flat_list
endfunction

function! dotoo#utils#change_todo_menu()
  let todo_keywords = filter(copy(g:dotoo#parser#todo_keywords), 'v:val !~# "|"')
  let acceptable_input = '[' . join(map(copy(todo_keywords), 'v:val[0]'),'') . ']'
  let todo_keywords = map(todo_keywords, '"(".tolower(v:val[0]).") ".v:val')
  call add(todo_keywords, 'Select todo state: ')
  return dotoo#utils#getchar(join(todo_keywords, "\n"), acceptable_input)
endfunction
