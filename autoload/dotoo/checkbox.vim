" better names for functions
fun! s:is_checkbox(line)
  return a:line =~ '^\s*- \[[ -X]\] '
endf
function! s:is_open_checkbox(line)
  return a:line =~ '^\s*- \[ \] \+'
endfunction
function! s:is_started_checkbox(line)
  return a:line =~ '^\s*- \[-\] \+'
endfunction
function! s:is_checked_checkbox(line)
  return a:line =~ '^\s*- \[X\] \+'
endfunction
function! s:is_headline(line)
  return a:line =~ '^*\+ \+'
endfunction

fun! s:test_children(parent, checked)
  let pind = indent(a:parent)
  let nline = a:parent
  while nline < line('$')
    let nline = nline + 1
    let line = getline(nline)
    if s:is_headline(line)
      break
    endif
    if !s:is_checkbox(line)
      continue
    endif
    if pind >= indent(nline)
      break
    endif
    if (a:checked && !s:is_checked_checkbox(line)) || (!a:checked && !s:is_unchecked_checkbox(line))
      return 0
    endif
  endw
  return 1
endf

" NOTE: nline has to contain a checkbox, else this fails
" TODO: should update, also when unchecked
fun! s:process_parents(nline)
  let nline = a:nline
  let nlast = a:nline
  let lind = indent(nlast)
  while nline > 1
    let nline = nline - 1
    let line = getline(nline)
    if s:is_headline(line)
      break
    endif
    if !s:is_checkbox(line)
      continue
    endif
    if lind <= indent(nline)
      continue
    endif
    let nlast = nline
    let lind = indent(nlast)
    if s:is_open_checkbox(line)
      call setline(nline, substitute(line, '- \[ \] ', '- [-] ', ''))
    endif
    if s:test_children(nlast, 1)
      call setline(nlast, substitute(getline(nlast), '- \[-\] ', '- [X] ', ''))
    endif 
  endw
endf

fun! CheckCheckbox(nline)
  " TODO: if no checkbox on given line, go to firtst above
  let line = getline(a:nline)
  call setline(a:nline, substitute(line, '- \[ \] ', '- [X] ', ''))
  call s:process_parents(a:nline)
endf
