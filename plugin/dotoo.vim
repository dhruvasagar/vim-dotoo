if exists('g:loaded_dotoo')
  finish
endif
let g:loaded_dotoo = 1

let g:org_todo_keyword_faces = [['TODO', [':foreground 160', ':weight bold']],
                              \ ['NEXT', [':foreground 27', ':weight bold']],
                              \ ['DONE', [':foreground 22', ':weight bold']],
                              \ ['WAITING', [':foreground 202', ':weight bold']],
                              \ ['HOLD', [':foreground 53', ':weight bold']],
                              \ ['CANCELLED', [':foreground 22', ':weight bold']],
                              \ ['MEETING', [':foreground 22', ':weight bold']],
                              \ ['PHONE', [':foreground 22', ':weight bold']]]

nnoremap <silent> gA :<C-U>call dotoo#agenda#agenda()<CR>
