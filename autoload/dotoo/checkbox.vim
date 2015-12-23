function! dotoo#checkbox#is_checkbox(line)
  return a:line =~ '^\s*[-+*] \[[ -X]\]\(\s\|$\)' && !dotoo#checkbox#is_headline(a:line)
endfunction
function! dotoo#checkbox#is_unchecked_checkbox(line)
  return a:line =~ '^\s*[-+*] \[ \]\(\s\|$\)' && !dotoo#checkbox#is_headline(a:line)
endfunction
function! dotoo#checkbox#is_partial_checkbox(line)
  return a:line =~ '^\s*[-+*] \[-\]\(\s\|$\)' && !dotoo#checkbox#is_headline(a:line)
endfunction
function! dotoo#checkbox#is_checked_checkbox(line)
  return a:line =~ '^\s*[-+*] \[X\]\(\s\|$\)' && !dotoo#checkbox#is_headline(a:line)
endfunction
function dotoo#checkbox#is_list_item(line)
  return a:line =~ '^\s*[-+*]\(\s\|$\)' && !dotoo#checkbox#is_headline(a:line)
endfunction
function! dotoo#checkbox#is_headline(line)
  return a:line =~ '^\*\+ '
endfunction

function! s:count_children(parent)
  let pind = indent(a:parent)
  let nline = a:parent
  let childs_unchecked = 0
  let childs_partial = 0
  let childs_checked = 0
  while nline < line('$')
    let nline = nline + 1
    let line = getline(nline)
    if dotoo#checkbox#is_headline(line)
      break
    endif
    if pind >= indent(nline) && dotoo#checkbox#is_list_item(line)
      break
    endif
    if !dotoo#checkbox#is_checkbox(line)
      continue
    endif
    if indent(nline) - pind > 6
      continue
    endif
    if dotoo#checkbox#is_unchecked_checkbox(line)
      let childs_unchecked = childs_unchecked + 1
    elseif dotoo#checkbox#is_partial_checkbox(line)
      let childs_partial = childs_partial + 1
    elseif dotoo#checkbox#is_checked_checkbox(line)
      let childs_checked = childs_checked + 1
    endif
  endwhile
  return [childs_unchecked, childs_partial, childs_checked]
endfunction

function s:update_progress(nline, counts)
    call setline(a:nline, substitute(getline(a:nline), '\[\([0-9]*\/[0-9]*\|%\)\]$', '[' . a:counts[2] . '/' . (a:counts[0] + a:counts[1] + a:counts[2]) . ']', ''))
endfunction

function! s:process_parents(nline)
  let nline = a:nline
  let nlast = a:nline
  let lind = indent(nlast)
  while nline > 1
    let nline = nline - 1
    let line = getline(nline)
    if dotoo#checkbox#is_headline(line)
      let counts = s:count_children(nline)
      call s:update_progress(nline, counts)
      break
    endif
    if lind <= indent(nline) && dotoo#checkbox#is_list_item(line)
      continue
    endif
    if !dotoo#checkbox#is_checkbox(line)
      continue
    endif
    let nlast = nline
    let lind = indent(nlast)
    if dotoo#checkbox#is_unchecked_checkbox(line)
      call setline(nline, substitute(line, '\([-+*]\) \[ \]\(\s\|$\)', '\1 [-]\2', ''))
    endif
    if dotoo#checkbox#is_checked_checkbox(line)
      call setline(nline, substitute(line, '\([-+*]\) \[X\]\(\s\|$\)', '\1 [-]\2', ''))
    endif
    let counts = s:count_children(nlast)
    if counts[0] + counts[1] == 0
      call setline(nlast, substitute(getline(nlast), '\([-+*]\) \[-\]\(\s\|$\)', '\1 [X]\2', ''))
    elseif counts[1] + counts[2] == 0
      call setline(nlast, substitute(getline(nlast), '\([-+*]\) \[-\]\(\s\|$\)', '\1 [ ]\2', ''))
    endif
    call s:update_progress(nlast, counts)
  endwhile
endfunction

function! dotoo#checkbox#toggle()
  let pos = getcurpos()
  let nline = pos[1]
  while nline > 0 && !dotoo#checkbox#is_checkbox(getline(nline))
    let nline = nline - 1
  endwhile
  let line = getline(nline)

  if dotoo#checkbox#is_unchecked_checkbox(line)
    call setline(nline, substitute(line, '\([-+*]\) \[ \]\(\s\|$\)', '\1 [X]\2', ''))
    call s:process_parents(nline)
  elseif dotoo#checkbox#is_checked_checkbox(line)
    call setline(nline, substitute(line, '\([-+*]\) \[X\]\(\s\|$\)', '\1 [ ]\2', ''))
    call s:process_parents(nline)
  endif
  call setpos('.', pos)
endfunction
