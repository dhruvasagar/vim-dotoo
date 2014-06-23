if exists('g:autoloaded_dotoo_utils')
  finish
endif
let g:autoloaded_dotoo_utils = 1

function! dotoo#utils#set(opt, val)
  if !exists('g:'.a:opt)
    let g:{a:opt} = a:val
  endif
endfunction

function! dotoo#utils#getchar(prompt, accept)
  let old_cmdheight = &cmdheight
  let &cmdheight = len(split(a:prompt, "\n"))
  echon a:prompt
  let char = nr2char(getchar())
  let &cmdheight = old_cmdheight
  redraw!
  if char =~? a:accept | return char | endif
  return ''
endfunction
