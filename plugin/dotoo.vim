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
call s:SetGlobalOpts('dotoo_todo_keyword_faces', [])
call s:SetGlobalOpts('dotoo_heading_shade_leading_stars', 1)

let g:dotoo#parser#todo_keywords = [
      \ 'TODO',
      \ 'NEXT',
      \ 'WAITING',
      \ 'HOLD',
      \ 'PHONE',
      \ 'MEETING',
      \ '|',
      \ 'CANCELLED',
      \ 'DONE'
      \ ]
let g:dotoo_todo_keyword_faces = [
      \ ['TODO', [':foreground 160', ':weight bold']],
      \ ['NEXT', [':foreground 27', ':weight bold']],
      \ ['DONE', [':foreground 22', ':weight bold']],
      \ ['WAITING', [':foreground 202', ':weight bold']],
      \ ['HOLD', [':foreground 53', ':weight bold']],
      \ ['CANCELLED', [':foreground 22', ':weight bold']],
      \ ['MEETING', [':foreground 22', ':weight bold']],
      \ ['PHONE', [':foreground 22', ':weight bold']]
      \ ]

nnoremap <silent> gA :<C-U>call dotoo#agenda#agenda()<CR>
nnoremap <silent> gC :<C-U>call dotoo#capture#capture()<CR>

augroup dotoo
  au!

  autocmd BufNewFile,BufRead *.dotoo call dotoo#parser#parsefile({'force': 1})
augroup END

" Register Agenda Views
call dotoo#agenda_views#todos#register()
call dotoo#agenda_views#notes#register()
call dotoo#agenda_views#agenda#register()
call dotoo#agenda_views#refiles#register()

" Register Agenda Plugins
" call dotoo#agenda#todos#register_agenda_plugin()
" call dotoo#agenda#log_summary#register_agenda_plugin()
