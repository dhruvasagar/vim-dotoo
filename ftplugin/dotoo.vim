if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if !exists('g:dotoo_use_default_mappings')
  let g:dotoo_use_default_mappings = 1
endif

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

nnoremap <buffer> <silent> <Plug>DotooClockIn       :<C-U>call dotoo#clock#start()<CR>
nnoremap <buffer> <silent> <Plug>DotooClockOut      :<C-U>call dotoo#clock#stop()<CR>
nnoremap <buffer> <silent> <Plug>DotooMoveHeadline  :<C-U>call dotoo#move_headline_menu(dotoo#get_headline())<CR>
nnoremap <buffer> <silent> <Plug>DotooChangeTodo    :<C-U>call dotoo#change_todo()<CR>
nnoremap <buffer> <silent> <Plug>DotooNormalizeDate :<C-U>call dotoo#normalize()<CR>

if g:dotoo_use_default_mappings
  nmap <buffer> gI          <Plug>DotooClockIn
  nmap <buffer> gO          <Plug>DotooClockOut
  nmap <buffer> gM          <Plug>DotooMoveHeadline
  nmap <buffer> cit         <Plug>DotooChangeTodo
  nmap <buffer> <C-C><C-C>  <Plug>DotooNormalizeDate
  nmap <buffer> cic         <Plug>DotooCheckboxToggle
  nmap <buffer> <C-A>       <Plug>DotooIncrementDate
  nmap <buffer> <C-X>       <Plug>DotooDecrementDate
endif

command! -buffer -nargs=? DotooAdjustDate call dotoo#adjust_date(<q-args>)
