if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl commentstring=#\ %s
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

if !g:dotoo_disable_mappings
  if !hasmapto('<Plug>(dotoo-clock-start)')
    nmap <buffer> gI <Plug>(dotoo-clock-start)
  endif
  if !hasmapto('<Plug>(dotoo-clock-stop)')
    nmap <buffer> gO <Plug>(dotoo-clock-stop)
  endif
  if !hasmapto('<Plug>(dotoo-headline-move-menu)')
    nmap <buffer> gM <Plug>(dotoo-headline-move-menu)
  endif
  if !hasmapto('<Plug>(dotoo-headline-change-todo)')
    nmap <buffer> cit <Plug>(dotoo-headline-change-todo)
  endif
  if !hasmapto('<Plug>(dotoo-checkbox-toggle)')
    nmap <buffer> cic <Plug>(dotoo-checkbox-toggle)
  endif
  if !hasmapto('<Plug>(dotoo-date-increment)')
    nmap <buffer> <C-A> <Plug>(dotoo-date-increment)
  endif
  if !hasmapto('<Plug>(dotoo-date-decrement)')
    nmap <buffer> <C-X> <Plug>(dotoo-date-decrement)
  endif
  if !hasmapto('<Plug>(dotoo-date-normalize)')
    nmap <buffer> <C-C><C-C> <Plug>(dotoo-date-normalize)
  endif
endif

command! -buffer -nargs=? DotooAdjustDate call dotoo#date#adjust(<q-args>)
