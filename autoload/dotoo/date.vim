function! s:get_date()
  let old_reg_val = @@
  let @@ = '' " clear register
  normal! di[
  let dt = @@
  if empty(dt)
    normal! di<
    let dt = @@
  endif
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

function! dotoo#date#adjust(...) abort
  let amount = a:0 ? a:1 : ''
  if (empty(amount))
    let amount = input('Adjust by amount: ')
  endif
  return call('s:adjust_date', [amount])
endfunction

function! dotoo#date#increment(days) abort
  if !s:adjust_date('+'.a:days.'d') | exe "normal! \<C-A>" | endif
  silent! call repeat#set("\<Plug>(dotoo-date-increment)", a:days)
endfunction

function! dotoo#date#decrement(days) abort
  if !s:adjust_date('-'.a:days.'d') | exe "normal! \<C-X>" | endif
  silent! call repeat#set("\<Plug>(dotoo-date-decrement)", a:days)
endfunction

let s:syntax = dotoo#parser#lexer#syntax()
function! dotoo#date#normalize()
  let dt = s:get_date()
  if !empty(dt)
    call s:set_date(dt)
  elseif s:syntax.logbook_clock.matches(getline('.'))
    let old_view = winsaveview()
    call search('^\*\+', 'b')
    let headline = dotoo#get_headline()
    call headline.save()
    call winrestview(old_view)
  else
    exe "normal! \<C-C>\<C-C>"
  endif
endfunction
