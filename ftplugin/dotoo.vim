if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl foldexpr=DotooFoldExpr()
setl foldmethod=expr

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

autocmd! BufRead,TextChanged,TextChangedI <buffer> call dotoo#parser#parse(expand('%:p'),1)
