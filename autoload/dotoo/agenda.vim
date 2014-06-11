if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

let g:dotoo#agenda#files = ['~/org-files/todo_test.org']

let s:agenda_dotoos = []
function! s:load_agenda_files(...)
  let force = a:0 ? a:1 : 0
  if force | let s:agenda_dotoos = [] | endif
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      let dotoos = dotoo#parser#parse(orgfile, force)
      call add(s:agenda_dotoos, dotoos)
    endfor
  endfor
endfunction

let s:tmpfile = tempname()
function! s:Edit(cmd)
  exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl buftype=nofile bufhidden=wipe nobuflisted readonly ft=dotoo_agenda
endfunction

function! s:agenda_view(agendas)
  call s:Edit('pedit')
  nnoremap <buffer> <silent> q :<C-U>bdelete<CR>
  nnoremap <buffer> <silent> R :<C-U>call dotoo#agenda#agenda(1)<CR>
  setl modifiable
  silent call setline(1, a:agendas)
  setl nomodifiable
endfunction

function! dotoo#agenda#agenda(...)
  let force = a:0 ? a:1 : 0
  let start = dotoo#time#start_of('month')
  let end = start.adjust('1m -1d')
  let deadlines = {}

  call s:load_agenda_files(force)

  for dotoos in s:agenda_dotoos
    let _deadlines = dotoos.select('deadline')
    let deadlines[dotoos.key] = filter(_deadlines, 'v:val.next_deadline(force).between(start, end)')
  endfor

  let agendas = []
  for key in keys(deadlines)
    let headlines = deadlines[key]
    for headline in headlines
      let agenda = printf('%10s: %20s:  %-30s%s', key, headline.next_deadline(force).time_ago(), headline.todo_title(), headline.tags)
      call add(agendas, agenda)
    endfor
  endfor

  call s:agenda_view(agendas)
endfunction
