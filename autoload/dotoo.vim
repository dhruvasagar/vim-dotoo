if exists('g:autoloaded_dotoo')
  finish
endif
let g:autoloaded_dotoo = 1

" Helper Functions
function! dotoo#get_headline(...)
  return call('dotoo#parser#headline#get', a:000)
endfunction

function! dotoo#get_headline_by_title(title)
  let headlines = dotoo#parser#headline#filter("v:val.title =~# '" . a:title . "'")
  if !empty(headlines) | return headlines[0] | endif
endfunction

function! dotoo#move_headline(headline, parent_headline)
  if has_key(a:headline, 'parent')
    let parent = a:headline.parent
    call parent.remove_headline(a:headline)
    call parent.save()
  else
    let splitted = a:headline.open()
    call a:headline.delete()
    call a:headline.close(splitted)
  endif
  call a:parent_headline.add_headline(a:headline)
  call a:parent_headline.save()
  call dotoo#agenda#save_files()
endfunction

function! dotoo#change_todo(...)
  let headline = a:0 ? a:1 : dotoo#get_headline()
  let selection = dotoo#utils#change_todo_menu()
  if !empty(selection)
    call headline.change_todo(selection)
    call headline.save()
  endif
endfunction

function! s:get_date()
  let old_reg_val = @@
  let @@ = '' " clear register
  normal! di[
  let dt = @@
  if empty(dt)
    return ''
  else
    return dotoo#time#new(dt)
  endif
  let @@ = old_reg_val
endfunction

function! s:set_date(date)
  let old_reg_val = @@
  let @@ = a:date.to_string()
  normal! P
  let @@ = old_reg_val
endfunction

function! s:adjust_date(amount)
  let dt = s:get_date()
  if !empty(dt)
    call s:set_date(dt.adjust(a:amount))
    return 1
  else
    return 0
  endif
endfunction

function! dotoo#increment_date()
  if !s:adjust_date('+'.v:count1.'d') | exe "normal! \<C-A>" | endif
endfunction

function! dotoo#decrement_date()
  if !s:adjust_date('-'.v:count1.'d') | exe "normal! \<C-X>" | endif
endfunction

function! dotoo#normalize_date()
  let dt = s:get_date()
  if !empty(dt)
    call s:set_date(dt)
  else
    exe "normal! \<C-C>\<C-C>"
  endif
endfunction
