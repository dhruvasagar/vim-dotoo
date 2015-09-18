if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl foldexpr=DotooFoldExpr()
setl foldmethod=expr
setl foldtext=getline(v:foldstart)

let s:syntax = dotoo#parser#lexer#syntax()
function! DotooFoldExpr()
  let line = getline(v:lnum)
  if s:syntax.directive.matches(line)
    return 0
  elseif s:syntax.headline.matches(line)
    let level = len(s:syntax.headline.matchlist(line)[0])
    return '>'.level
  elseif s:syntax.properties.matches(line)
    return 'a1'
  elseif s:syntax.logbook.matches(line)
    return 'a1'
  elseif s:syntax.drawer_end.matches(line)
    return 's1'
  else
    return '='
  endif
endfunction

" autocmd! TextChanged,TextChangedI <buffer> call dotoo#parser#parsefile({})
autocmd! BufWritePost <buffer> call dotoo#parser#parsefile({'force': 1})

iabbrev <expr> <buffer> <silent> :date: '['.strftime(g:dotoo#time#date_day_format).']'
iabbrev <expr> <buffer> <silent> :time: '['.strftime(g:dotoo#time#datetime_format).']'

nnoremap <buffer> <silent> gI :<C-U>call dotoo#clock#start()<CR>
nnoremap <buffer> <silent> gO :<C-U>call dotoo#clock#stop()<CR>
nnoremap <buffer> <silent> gM :<C-U>call dotoo#move_headline(dotoo#get_headline())<CR>
nnoremap <buffer> <silent> cit :<C-U>call dotoo#change_todo()<CR>
nnoremap <buffer> <silent> cic :<C-U>call dotoo#checkbox#toggle()<CR>
nnoremap <buffer> <silent> <C-A> :<C-U>call dotoo#increment_date()<CR>
nnoremap <buffer> <silent> <C-X> :<C-U>call dotoo#decrement_date()<CR>
nnoremap <buffer> <silent> <C-C><C-C> :<C-U>call dotoo#normalize()<CR>
