let g:doto#agenda#files = ['~/org-files/todo_test.org']

let s:agenda_dotos = []
function! s:load_agenda_files(...)
  let force = a:0 ? a:1 : 0
  if force | let s:agenda_dotos = [] | endif
  for agenda_file in g:doto#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      let dotos = doto#parser#parse(orgfile, force)
      call add(s:agenda_dotos, dotos)
    endfor
  endfor
endfunction

function! s:agenda(...)
  let force = a:0 ? a:1 : 0
  let start = doto#time#start_of('month')
  let end = start.adjust('1m -1d')
  let deadlines = {}

  call s:load_agenda_files(force)

  for dotos in s:agenda_dotos
    let _deadlines = dotos.select('deadline')
    let deadlines[dotos.key] = filter(_deadlines, 'v:val.nearest_deadline(end).between(start, end)')
  endfor

  let agendas = []
  for key in keys(deadlines)
    let headlines = deadlines[key]
    for headline in headlines
      let agenda = printf('%10s: %20s:  %-30s%s', key, headline.nearest_deadline(end).time_ago(), headline.todo.' '.headline.title, empty(headline.tags) ? '' : headline.tags)
      call add(agendas, agenda)
    endfor
  endfor

  call s:Edit('pedit')
  nnoremap <buffer> <silent> q :<C-U>bdelete<CR>
  nnoremap <buffer> <silent> R :<C-U>call <SID>agenda(1)<CR>
  call setline(1, agendas)
endfunction

let s:tmpfile = tempname()
function! s:Edit(cmd)
  exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl buftype=nofile bufhidden=wipe nobuflisted ft=doto_agenda
endfunction
