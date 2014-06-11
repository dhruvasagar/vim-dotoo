if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

let g:dotoo#agenda#warning_days = '30d'
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
  setl winheight=20
  setl buftype=nofile bufhidden=wipe nobuflisted
  setl readonly nofoldenable nolist
  setf dotoo_agenda
endfunction

function! s:agenda_setup()
  nnoremap <buffer> <silent> q :<C-U>bdelete<CR>
  nnoremap <buffer> <silent> r :<C-U>call dotoo#agenda#agenda(1)<CR>
  nnoremap <buffer> <silent> <nowait> c :<C-U>call <SID>change_headline_todo()<CR>
  nnoremap <buffer> <silent> <CR> :<C-U>call <SID>goto_headline('buffer')<CR>
  nnoremap <buffer> <silent> <C-S> :<C-U>call <SID>goto_headline('split')<CR>
  nnoremap <buffer> <silent> <C-V> :<C-U>call <SID>goto_headline('vsplit')<CR>
  nnoremap <buffer> <silent> <C-T> :<C-U>call <SID>goto_headline('tabe')<CR>
  nmap <buffer> <silent> <Tab> <C-V>
endfunction

function! s:agenda_view(agendas)
  call s:Edit('pedit')
  call s:agenda_setup()
  setl modifiable
  silent call setline(1, dotoo#time#new().to_string('%A %d %B %Y'))
  silent call setline(2, a:agendas)
  setl nomodifiable
endfunction

function! s:goto_headline(cmd)
  let headline = s:agenda_headlines[line('.')-2]
  exec a:cmd headline.file
  exec 'normal!' headline.lnum . 'G'
endfunction

function! s:change_headline_todo()
  let headline = s:agenda_headlines[line('.')-2]
  let todo_keywords = filter(copy(g:dotoo#parser#todo_keywords), 'v:val !~# "|"')
  let todo_keywords = map(todo_keywords, '"[" . v:val[0] . "]" . v:val')
  let selected = input("Enter a char to change todo state: \n" . join(todo_keywords, ' ') . "\n:")
  if !empty(selected)
    call headline.change_todo(selected)
  end
endfunction

let s:agendas = []
let s:agenda_headlines = []
function! dotoo#agenda#agenda(...)
  let force = a:0 ? a:1 : 0
  let deadlines = {}
  let warning_limit = dotoo#time#new().adjust(g:dotoo#agenda#warning_days)

  call s:load_agenda_files(force)

  for dotoos in s:agenda_dotoos
    let _deadlines = dotoos.select(['deadline', 'scheduled'])
    let deadlines[dotoos.key] = filter(_deadlines, 'v:val.next_deadline(force).before(warning_limit)')
  endfor

  if force || empty(s:agendas)
    let s:agendas = []
    for key in keys(deadlines)
      let headlines = deadlines[key]
      for headline in headlines
        let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
        let agenda = printf('%s %10s:' . time_pf . '%-60s%s', '', key, headline.next_deadline(force).time_ago(), headline.todo_title(), headline.tags)
        call add(s:agendas, agenda)
        call add(s:agenda_headlines, headline)
      endfor
    endfor
  endif

  call s:agenda_view(s:agendas)
endfunction
