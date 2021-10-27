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
call s:SetGlobalOpts('dotoo_disable_mappings', 0)

nnoremap <silent> <Plug>(dotoo-agenda)
      \ :<C-U>call dotoo#agenda#agenda()<CR>
nnoremap <silent> <Plug>(dotoo-capture)
      \ :<C-U>call dotoo#capture#capture()<CR>

nnoremap <silent> <Plug>(dotoo-link-follow)
      \ :<C-U>call dotoo#link#follow('edit')<CR>

nnoremap <silent> <Plug>(dotoo-link-back)
      \ :<C-U>call dotoo#link#back()<CR>

nnoremap <silent> <Plug>(dotoo-date-increment)
      \ :<C-U>call dotoo#date#increment(v:count1)<CR>
nnoremap <silent> <Plug>(dotoo-date-decrement)
      \ :<C-U>call dotoo#date#decrement(v:count1)<CR>
nnoremap <silent> <Plug>(dotoo-date-normalize)
      \ :<C-U>call dotoo#date#normalize()<CR>

nnoremap <silent> <Plug>(dotoo-checkbox-toggle)
      \ :<C-U>call dotoo#checkbox#toggle()<CR>

nnoremap <silent> <Plug>(dotoo-clock-start)
      \ :<C-U>call dotoo#clock#start()<CR>
nnoremap <silent> <Plug>(dotoo-clock-stop)
      \ :<C-U>call dotoo#clock#stop()<CR>

nnoremap <silent> <Plug>(dotoo-headline-move-menu)
      \ :<C-U>call dotoo#move_headline_menu(dotoo#get_headline())<CR>
nnoremap <silent> <Plug>(dotoo-headline-change-todo)
      \ :<C-U>call dotoo#change_todo()<CR>

nnoremap <silent> <Plug>(dotoo-agenda-refresh)
      \ :<C-U>call dotoo#agenda#refresh_view()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-save-files)
      \ :<C-U>call dotoo#agenda#save_files()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-headline-move)
      \ :<C-U>call dotoo#agenda#move_headline()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-headline-change-todo)
      \ :<C-U>call dotoo#agenda#change_headline_todo()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-headline-undo-change)
      \ :<C-U>call dotoo#agenda#undo_headline_change()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-headline-clock-start)
      \ :<C-U>call dotoo#agenda#start_headline_clock()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-headline-clock-stop)
      \ :<C-U>call dotoo#agenda#stop_headline_clock()<CR>
nnoremap <silent> <Plug>(dotoo-agenda-filter)
      \ :<C-U>call dotoo#agenda#filter_agendas()<CR>

if !g:dotoo_disable_mappings
  if !hasmapto('<Plug>(dotoo-agenda)')
    nmap gA <Plug>(dotoo-agenda)
  endif
  if !hasmapto('<Plug>(dotoo-capture)')
    nmap gC <Plug>(dotoo-capture)
  endif
endif

augroup dotoo
  au!

  autocmd FileType dotoo call dotoo#parser#parsefile({'force': 1})
augroup END

command! -buffer -nargs=? DotooAdjustDate call dotoo#adjust_date(<q-args>)
