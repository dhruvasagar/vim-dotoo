if exists('g:autoloaded_dotoo_agenda_views_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda_views_agenda = 1

call dotoo#utils#set('dotoo#agenda_views#agenda#hide_empty', 0)
call dotoo#utils#set('dotoo#agenda_views#agenda#start_of', 'span')

function! s:build_day_agendas(dotoos, date) abort
  let warning_limit = a:date.adjust(g:dotoo#agenda#warning_days)
  let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '

  let agendas = []
  for dotoo in values(a:dotoos)
    let headlines = dotoo.filter('!v:val.done() && !empty(v:val.deadline())', 1)
    if a:date.is_today()
      let headlines = filter(headlines, 'v:val.deadline().before(warning_limit)')
    else
      let headlines = filter(headlines, 'v:val.deadline().next_repeat().eq_date(a:date)')
    endif
    call dotoo#agenda#apply_filters(headlines)

    for headline in headlines
      let agenda = printf('%s %10.10s:' . time_pf . '%-50.70s %s', '',
            \ headline.key,
            \ headline.metadate().time_ago(a:date),
            \ headline.todo_title(),
            \ headline.tags)
      call add(agendas, agenda)
    endfor
  endfor

  if empty(agendas) && g:dotoo#agenda_views#agenda#hide_empty
    return agendas
  endif

  let header = 'Date: ' . a:date.to_string('%A %d %B %Y')
  if a:date.is_today()
    let header = header . ' (Today)'
  endif
  call insert(agendas, header)
  return agendas
endfunction

function! s:span_dates() abort
  let dates = []
  let date = s:current_date
  let edate = s:current_date

  if g:dotoo#agenda_views#agenda#start_of ==# 'span'
    let date = date.start_of(s:current_span)
    let edate = date.end_of(s:current_span)
  elseif g:dotoo#agenda_views#agenda#start_of ==# 'today'
    let edate = date.adjust('+1' . s:current_span[0])
  endif

  while !date.eq(edate)
    call add(dates, date)
    let date = date.adjust('+1d')
  endwhile
  return dates
endfunction

let s:agendas = {}
function! s:build_agendas(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()

  let agendas = []
  for date in s:span_dates()
    call extend(agendas, s:build_day_agendas(a:dotoos, date))
  endfor

  if empty(agendas)
    call add(agendas, printf('%2s %s', '', 'No pending tasks!'))
  endif
  for plugin in values(s:agenda_view_plugins)
    if has_key(plugin, 'content')
      call extend(agendas, plugin.content(s:current_date, s:current_span, a:dotoos))
    endif
  endfor
  let header = []
  call add(header, 'Span: ' . s:current_span)
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(agendas, join(header, ', '))
  return agendas
endfunction

let s:current_date = dotoo#time#new()
function! s:adjust_current_date(amount)
  if a:amount ==# '.'
    let s:current_date = dotoo#time#new()
  else
    let s:current_date = s:current_date.adjust(a:amount . s:current_span[0])
  endif
  call dotoo#agenda#refresh_view()
endfunction

let s:current_span = 'day'
function! s:change_span()
  let span = dotoo#utils#getchar(join([
        \ '(d) day',
        \ '(w) week',
        \ '(m) month',
        \ 'Select span: '], "\n"), '[dwm]')
  if span =~# '^d'
    let s:current_span = 'day'
  elseif span =~# '^w'
    let s:current_span = 'week'
  elseif span =~# '^m'
    let s:current_span = 'month'
  endif
  " let s:current_date = dotoo#time#new().start_of(s:current_span)
  call dotoo#agenda#refresh_view()
endfunction

let s:agenda_view = {
      \ 'key': 'a',
      \ 'name': 'Agenda',
      \}
function! s:agenda_view.map() dict
  nnoremap <buffer> <silent> <nowait> . :<C-U>call <SID>adjust_current_date('.')<CR>
  nnoremap <buffer> <silent> <nowait> f :<C-U>call <SID>adjust_current_date('+1')<CR>
  nnoremap <buffer> <silent> <nowait> b :<C-U>call <SID>adjust_current_date('-1')<CR>
  nnoremap <buffer> <silent> <nowait> S :<C-U>call <SID>change_span()<CR>
endfunction

function! s:agenda_view.unmap() dict
  nunmap <buffer> .
  nunmap <buffer> f
  nunmap <buffer> b
  nunmap <buffer> S
endfunction

function! s:agenda_view.setup() dict
  call self.map()
  for plugin in values(s:agenda_view_plugins)
    if has_key(plugin, 'setup') | call plugin.setup() | endif
  endfor
endfunction

function! s:agenda_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_agendas(a:dotoos, force)
endfunction

function! s:agenda_view.short_key() dict
  return "a"
endfunction

function! s:agenda_view.cleanup() dict
  call self.unmap()
  for plugin in values(s:agenda_view_plugins)
    if has_key(plugin, 'cleanup') | call plugin.cleanup() | endif
  endfor
endfunction

let s:agenda_view_plugins = {}
function! dotoo#agenda_views#agenda#register_plugin(name, plugin) abort
  if type(a:plugin) == type({})
    let s:agenda_view_plugins[a:name] = a:plugin
  endif
endfunction

function! dotoo#agenda_views#agenda#toggle_plugin(name)
  if has_key(s:agenda_view_plugins, a:name)
    let plugin = s:agenda_view_plugins[a:name]
    if has_key(plugin, 'showing')
      let plugin.showing = !plugin.showing
    endif
    call dotoo#agenda#refresh_view()
  endif
endfunction

function! dotoo#agenda_views#agenda#register()
  call dotoo#agenda#register_view(s:agenda_view)
endfunction
