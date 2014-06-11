if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

let g:dotoo#agenda#files = ['~/org-files/*.dotoo']

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
  setl buftype=nofile bufhidden=wipe nobuflisted
  setl readonly nofoldenable nolist
  setf dotoo_agenda
endfunction

function! s:agenda_setup()
  nnoremap <buffer> <silent> q :<C-U>bdelete<CR>
  nnoremap <buffer> <silent> R :<C-U>call dotoo#agenda#agenda(1)<CR>
endfunction

function! s:agenda_view(agendas)
  call s:Edit('pedit')
  call s:agenda_setup()
  setl modifiable
  silent call setline(1, dotoo#time#new().to_string('%A %d %B %Y'))
  silent call setline(2, a:agendas)
  setl nomodifiable
endfunction

let s:agendas = []
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

  if force || empty(s:agendas)
    let s:agendas = []
    for key in keys(deadlines)
      let headlines = deadlines[key]
      for headline in headlines
        let agenda = printf('%s %10s: %20s:  %-30s%s', '', key, headline.next_deadline(force).time_ago(), headline.todo_title(), headline.tags)
        call add(s:agendas, agenda)
      endfor
    endfor
  endif

  call s:agenda_view(s:agendas)
endfunction
