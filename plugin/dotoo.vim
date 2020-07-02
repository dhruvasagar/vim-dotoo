if exists('g:loaded_dotoo')
  finish
endif
let g:loaded_dotoo = 1

function! s:SetGlobalOpts(opt, val)
  if !exists('g:'.a:opt)
    let g:{a:opt} = a:val
  endif
endfunction

call s:SetGlobalOpts('dotoo_heading_highlight_colors', [
      \ 'Title',
      \ 'Constant',
      \ 'Identifier',
      \ 'Statement',
      \ 'PreProc',
      \ 'Type',
      \ 'Special'])
call s:SetGlobalOpts('dotoo_heading_highlight_levels', len(g:dotoo_heading_highlight_colors))
call s:SetGlobalOpts('dotoo_heading_shade_leading_stars', 1)
call s:SetGlobalOpts('dotoo#parser#todo_keywords', [
      \ 'TODO',
      \ 'NEXT',
      \ 'WAITING',
      \ 'HOLD',
      \ 'PHONE',
      \ 'MEETING',
      \ '|',
      \ 'CANCELLED',
      \ 'DONE'
      \ ])
call s:SetGlobalOpts('dotoo_todo_keyword_faces', [
      \ ['TODO', [':foreground 160,#df0000', ':weight bold']],
      \ ['NEXT', [':foreground 27,#005fff', ':weight bold']],
      \ ['DONE', [':foreground 22,#005f00', ':weight bold']],
      \ ['WAITING', [':foreground 202,#ff5f00', ':weight bold']],
      \ ['HOLD', [':foreground 53,#5f005f', ':weight bold']],
      \ ['CANCELLED', [':foreground 22,#005f00', ':weight bold']],
      \ ['MEETING', [':foreground 22,#005f00', ':weight bold']],
      \ ['PHONE', [':foreground 22,#005f00', ':weight bold']]
      \ ])

nnoremap <silent> <Plug>(dotoo-agenda) :<C-U>call dotoo#agenda#agenda()<CR>
if !hasmapto('<Plug>(dotoo-agenda)')
  nmap gA <Plug>(dotoo-agenda)
endif
nnoremap <Plug>(dotoo-capture) :<C-U>call dotoo#capture#capture()<CR>
if !hasmapto('<Plug>(dotoo-capture)')
  nmap gC <Plug>(dotoo-capture)
endif

augroup dotoo
  au!
  autocmd FileType dotoo call dotoo#parser#parsefile({'force': 1})
augroup END

nnoremap <silent> <Plug>DotooIncrementDate  :<C-U>call dotoo#increment_date(v:count1)<CR>
nnoremap <silent> <Plug>DotooDecrementDate  :<C-U>call dotoo#decrement_date(v:count1)<CR>
nnoremap <silent> <Plug>DotooCheckboxToggle :<C-U>call dotoo#checkbox#toggle()<CR>

command! -buffer -nargs=? DotooAdjustDate call dotoo#adjust_date(<q-args>)
