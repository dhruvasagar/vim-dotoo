fun! s:is_checkbox(line)
  return a:line =~ '^\s*- \[[ -X]\] '
endf
function! s:is_unchecked_checkbox(line)
  return a:line =~ '^\s*- \[ \] \+'
endfunction
function! s:is_partial(line)
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

fun! s:process_parents(nline, checked)
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
    if s:is_unchecked_checkbox(line)
      call setline(nline, substitute(line, '- \[ \] ', '- [-] ', ''))
    endif
    if s:is_checked_checkbox(line)
      call setline(nline, substitute(line, '- \[X\] ', '- [-] ', ''))
    endif
    if s:test_children(nlast, a:checked)
      if a:checked
        call setline(nlast, substitute(getline(nlast), '- \[-\] ', '- [X] ', ''))
      else
        call setline(nlast, substitute(getline(nlast), '- \[-\] ', '- [ ] ', ''))
      endif
    endif 
  endw
endf

fun! ToggleCheckbox(nline)
  let nline = a:nline
  while nline > 0 && !s:is_checkbox(getline(nline))
    let nline = nline - 1
  endw
  let line = getline(nline)

  if s:is_unchecked_checkbox(line)
    call setline(nline, substitute(line, '- \[ \] ', '- [X] ', ''))
    call s:process_parents(nline, 1)
  endif
  if s:is_checked_checkbox(line)
    call setline(nline, substitute(line, '- \[X\] ', '- [ ] ', ''))
    call s:process_parents(nline, 0)
  endif
endf
