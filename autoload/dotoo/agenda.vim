if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

let g:dotoo#agenda#warning_days = '30d'
let g:dotoo#agenda#files = ['~/Documents/org-files/*.dotoo']

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
  setf dotooagenda
endfunction

function! s:agenda_view(agendas)
  let old_view = winsaveview()
  call s:Edit('pedit')
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

let s:agenda_deadlines = {}
let s:agenda_headlines = []
function! s:build_agendas(...)
  let force = a:0 ? a:1 : 0
  let agendas = []
  let add_agenda_headlines = force || empty(s:agenda_headlines)
  if force | let s:agenda_headlines = [] | endif
  for key in keys(s:agenda_deadlines)
    let headlines = s:agenda_deadlines[key]
    for headline in headlines
      let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
      let agenda = printf('%s %10s:' . time_pf . '%-70s%s', '',
            \ key,
            \ headline.metadate(s:current_date, force).time_ago(s:current_date),
            \ headline.todo_title(),
            \ headline.tags)
      call add(agendas, agenda)
      if add_agenda_headlines
        call add(s:agenda_headlines, headline)
      endif
    endfor
  endfor
  if empty(agendas)
    call add(agendas, printf('%2s %s', '', 'No pending tasks!'))
  endif
  return agendas
endfunction

function! dotoo#agenda#goto_headline(cmd)
  let headline = s:agenda_headlines[line('.')-2]
  exec a:cmd headline.file
  exec 'normal!' headline.lnum . 'G'
endfunction

function! dotoo#agenda#change_headline_todo()
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
    let &modified = getbufvar(bufnr('#'), '&modified')
    call winrestview(old_view)
  endif
endfunction

function! dotoo#agenda#undo_headline_change()
  let headline = s:agenda_headlines[line('.')-2]
  let old_view = winsaveview()
  call headline.undo_save()
  call dotoo#agenda#agenda(1)
  call winrestview(old_view)
endfunction

let s:current_date = dotoo#time#new()
function! dotoo#agenda#shift_current_date(amount)
  if a:amount ==# '.'
    let s:current_date = dotoo#time#new()
  else
    let s:current_date = s:current_date.adjust(a:amount).start_of('day')
  endif
  call dotoo#agenda#agenda(1)
endfunction

function! dotoo#agenda#save_files()
  let old_view = winsaveview()
  for _file in s:dotoo_files
    exec 'buffer' _file
    write
  endfor
  call dotoo#agenda#agenda()
  call winrestview(old_view)
endfunction

function! dotoo#agenda#agenda(...)
  let force = a:0 ? a:1 : 0
  let warning_limit = s:current_date.adjust(g:dotoo#agenda#warning_days)

  call s:load_agenda_files(force)
  if force || empty(s:agenda_deadlines)
    let s:agenda_deadlines = {}
    for dotoos in s:agenda_dotoos
      let _deadlines = dotoos.filter('!v:val.done() && (has_key(v:val.metadata, "deadline") || has_key(v:val.metadata, "scheduled"))')
      if s:current_date.is_today()
        let s:current_date = dotoo#time#new()
        let s:agenda_deadlines[dotoos.key] = filter(deepcopy(_deadlines), 'v:val.next_deadline(s:current_date, force).before(warning_limit)')
      else
        let s:agenda_deadlines[dotoos.key] = filter(deepcopy(_deadlines), 'v:val.next_deadline(s:current_date, force).eq_date(s:current_date)')
      endif
    endfor
  endif
  let agendas = s:build_agendas(force)
  call s:agenda_view(agendas)
endfunction
