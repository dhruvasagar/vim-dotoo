if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

let g:dotoo#agenda#warning_days = '30d'
let g:dotoo#agenda#files = ['~/org-files/*.dotoo']

let s:dotoo_files = []
let s:agenda_dotoos = []
function! s:load_agenda_files(...)
  let force = a:0 ? a:1 : 0
  if force | let s:dotoo_files = [] | endif
  if force | let s:agenda_dotoos = [] | endif
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      call add(s:dotoo_files, orgfile)
      let dotoos = dotoo#parser#parse(orgfile, force)
      call add(s:agenda_dotoos, dotoos)
    endfor
  endfor
endfunction

let s:tmpfile = tempname()
function! s:Edit(cmd)
  silent exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl winheight=20
  setl buftype=nofile bufhidden=wipe nobuflisted
  setl readonly nofoldenable nolist
  setf dotoo_agenda
endfunction

function! s:agenda_setup()
  nnoremap <buffer> <silent> <nowait> q :<C-U>bdelete<CR>
  nnoremap <buffer> <silent> <nowait> r :<C-U>call dotoo#agenda#agenda(1)<CR>
  nnoremap <buffer> <silent> <nowait> . :<C-U>call <SID>adjust_current_date('.')<CR>
  nnoremap <buffer> <silent> <nowait> f :<C-U>call <SID>adjust_current_date('+1d')<CR>
  nnoremap <buffer> <silent> <nowait> b :<C-U>call <SID>adjust_current_date('-1d')<CR>
  nnoremap <buffer> <silent> <nowait> c :<C-U>call <SID>change_headline_todo()<CR>
  nnoremap <buffer> <silent> <nowait> u :<C-U>call <SID>undo_headline_change()<CR>
  nnoremap <buffer> <silent> <nowait> s :<C-U>call <SID>save_files()<CR>
  nnoremap <buffer> <silent> <CR> :<C-U>call <SID>goto_headline('buffer')<CR>
  nnoremap <buffer> <silent> <C-S> :<C-U>call <SID>goto_headline('split')<CR>
  nnoremap <buffer> <silent> <C-V> :<C-U>call <SID>goto_headline('vsplit')<CR>
  nnoremap <buffer> <silent> <C-T> :<C-U>call <SID>goto_headline('tabe')<CR>
  nmap <buffer> <silent> <Tab> <C-V>
endfunction

function! s:agenda_view(agendas)
  let old_view = winsaveview()
  call s:Edit('pedit')
  call s:agenda_setup()
  setl modifiable
  silent call setline(1, s:current_date.to_string('%A %d %B %Y'))
  silent call setline(2, a:agendas)
  setl nomodifiable
  call winrestview(old_view)
endfunction

function! s:input(prompt, accept)
  echon a:prompt
  let char = nr2char(getchar())
  call feedkeys('<CR>')
  if char =~? a:accept
    return char
  endif
  return ''
endfunction

function! s:goto_headline(cmd)
  let headline = s:agenda_headlines[line('.')-2]
  exec a:cmd headline.file
  exec 'normal!' headline.lnum . 'G'
endfunction

function! s:change_headline_todo()
  let headline = s:agenda_headlines[line('.')-2]
  let todo_keywords = filter(copy(g:dotoo#parser#todo_keywords), 'v:val !~# "|"')
  let acceptable_input = '[' . join(map(copy(todo_keywords), 'v:val[0]'),'') . ']'
  let todo_keywords = map(todo_keywords, '"(".v:val[0].") ".v:val')
  call add(todo_keywords, "\nEnter: ")
  let selected = s:input(join(todo_keywords, ' '), acceptable_input)
  if !empty(selected)
    call headline.change_todo(selected)
    let old_view = winsaveview()
    call headline.save()
    call dotoo#agenda#agenda()
    call winrestview(old_view)
  endif
endfunction

function! s:undo_headline_change()
  let headline = s:agenda_headlines[line('.')-2]
  let old_view = winsaveview()
  call headline.undo_save()
  call dotoo#agenda#agenda(1)
  call winrestview(old_view)
endfunction

let s:current_date = dotoo#time#new()
function! s:adjust_current_date(amount)
  if a:amount ==# '.'
    let s:current_date = dotoo#time#new()
  else
    let s:current_date = s:current_date.adjust(a:amount)
  endif
  call dotoo#agenda#agenda(1)
endfunction

function! s:save_files()
  let old_view = winsaveview()
  for _file in s:dotoo_files
    exec 'buffer' _file
    write
  endfor
  call dotoo#agenda#agenda()
  call winrestview(old_view)
endfunction

let s:agenda_deadlines = {}
let s:agenda_headlines = []
function! s:build_agendas(...)
  let force = a:0 ? a:1 : 0
  let add_agenda_headlines = force || empty(s:agenda_headlines)
  let agendas = []
  if force | let s:agenda_headlines = [] | endif
  for key in keys(s:agenda_deadlines)
    let headlines = s:agenda_deadlines[key]
    for headline in headlines
      let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
      let agenda = printf('%s %10s:' . time_pf . '%-60s%s', '',
            \ key,
            \ headline.next_deadline(force).time_ago(s:current_date),
            \ headline.todo_title(),
            \ headline.tags)
      call add(agendas, agenda)
      if add_agenda_headlines
        call add(s:agenda_headlines, headline)
      endif
    endfor
  endfor
  return agendas
endfunction

function! dotoo#agenda#agenda(...)
  let force = a:0 ? a:1 : 0
  let warning_limit = s:current_date.adjust(g:dotoo#agenda#warning_days)

  call s:load_agenda_files(force)
  if force || empty(s:agenda_deadlines)
    let s:agenda_deadlines = {}
    for dotoos in s:agenda_dotoos
      let _deadlines = dotoos.select(['deadline', 'scheduled'])
      let s:agenda_deadlines[dotoos.key] = filter(_deadlines, 'v:val.next_deadline(force).before(warning_limit)')
    endfor
    if s:current_date.is_today() | let s:current_date = dotoo#time#new() | endif
  endif
  let agendas = s:build_agendas(force)
  call s:agenda_view(agendas)
endfunction
