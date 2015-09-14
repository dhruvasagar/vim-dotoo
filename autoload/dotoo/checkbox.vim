" better names for functions
function! s:is_open_checkbox(line)
  return a:line =~ '^\s*- \[ \] \+'
endfunction
function! s:is_started_checkbox(line)
  return a:line =~ '^\s*- \[-\] \+'
endfunction
fun! s:is_checkbox(line)
  return a:line =~ '^\s*- \[[ -X]\] '
endf
function! s:is_headline(line)
  return a:line =~ '^*\+ \+'
endfunction

" NOTE: nline has to contain a checkbox, else this fails
" TODO: should update, also when unchecked
fun! s:process_parents(nline)
  let nline = a:nline
  let lastn = a:nline
  while nline > 1
    let cind = indent(lastn)
    let nind = indent(nline-1)
    let line = getline(nline-1)
    if s:is_headline(line)
      return
    endif
    if s:is_checkbox(line)
      if cind <= nind
        let nline = nline - 1
        continue
      endif
      let lastn = nline-1
      if s:is_open_checkbox(line)
        call setline(nline-1, substitute(line, '- \[ \] ', '- [-] ', ''))
      endif
      " TODO: separate function
      let pline = lastn
      let do_check = 1
      while pline < 700 " TODO: testen of einde bereikt
        let pline = pline + 1
        if ! s:is_checkbox(getline(pline))
          continue
        endif
        if cind > indent(pline)
          break
        endif
        if getline(pline) !~ '- \[X\] ' " TODO: is_checked_checkbox
          let do_check = 0
          break
        endif
      endw
      if do_check
        call setline(lastn, substitute(getline(lastn), '- \[-\] ', '- [X] ', ''))
      endif 
    endif
    let nline = nline - 1
  endw
endf

fun! CheckCheckbox(nline)
  " TODO: if no checkbox on given line, go to firtst above
  let line = getline(a:nline)
  call setline(a:nline, substitute(line, '- \[ \] ', '- [X] ', ''))
  call s:process_parents(a:nline)
endf
