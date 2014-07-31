if exists('g:autoloaded_dotoo_agenda_views_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda_views_agenda = 1

let s:agendas = {}
function! s:build_agendas(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let warning_limit = s:current_date.adjust(g:dotoo#agenda#warning_days)
  if force || empty(s:agendas)
    let s:agendas = {}
    for key in keys(a:dotoos)
      if has_key(s:filters, 'file') && s:filters['file'] !=# fnamemodify(key, ':p:t:r')
        continue
      endif
      let dotoo = a:dotoos[key]
      let _deadlines = dotoo.filter('!v:val.done() && !empty(v:val.deadline())',1)
      if s:current_span ==# 'day' && s:current_date.is_today()
        let s:current_date = dotoo#time#new()
        let _deadlines = filter(_deadlines, 'v:val.deadline().before(warning_limit)')
      else
        let _deadlines = filter(_deadlines,
              \ 'v:val.deadline().between(s:current_date.start_of(s:current_span), s:current_date.end_of(s:current_span))')
      endif
      if has_key(s:filters, 'tag')
        let _deadlines = filter(_deadlines, "v:val.tags =~? '" . s:filters['tag'] . "'")
      endif
      let s:agendas[dotoo.key] = _deadlines
    endfor
  endif
  let agendas = []
  call dotoo#agenda#headlines([])
  let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
  for key in keys(s:agendas)
    let headlines = s:agendas[key]
    call dotoo#agenda#headlines(headlines, 1)
    for headline in headlines
      let agenda = printf('%s %10s:' . time_pf . '%-70s %s', '',
            \ key,
            \ headline.metadate().time_ago(s:current_date),
            \ headline.todo_title(),
            \ headline.tags)
      call add(agendas, agenda)
    endfor
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
  call add(header, 'Date: ' . s:current_date.to_string('%A %d %B %Y'))
  call add(header, 'Span: ' . s:current_span)
  if !empty(s:filters)
    call add(header, 'Filters: ' . join(map(items(s:filters), "v:val[0].'='.v:val[1]"), ', '))
  endif
  call insert(agendas, join(header, ', '))
  return agendas
endfunction

let s:current_date = dotoo#time#new()
function! s:adjust_current_date(amount)
  if a:amount ==# '.'
    let s:current_date = dotoo#time#new().start_of(s:current_span)
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
  let s:current_date = dotoo#time#new().start_of(s:current_span)
  call dotoo#agenda#refresh_view()
endfunction

let s:filters = {}
function! s:filter_agendas()
  let type = input('Filter by: ', '', 'customlist,dotoo#agenda_views#agenda#filter_complete')
  if empty(type)
    let s:filters = {}
  else
    let filter_by = input('Select '.type.': ', '', 'customlist,dotoo#agenda_views#agenda#filter_'.type.'_complete')
    if !empty(filter_by)
      let s:filters[type] = filter_by
    elseif has_key(s:filters, type)
      call remove(s:filters, type)
    endif
  endif
  redraw!
  call dotoo#agenda#refresh_view()
endfunction

let s:view_name = 'agenda'
let s:agenda_view = {}
function! s:agenda_view.map() dict
  nnoremap <buffer> <silent> <nowait> . :<C-U>call <SID>adjust_current_date('.')<CR>
  nnoremap <buffer> <silent> <nowait> f :<C-U>call <SID>adjust_current_date('+1')<CR>
  nnoremap <buffer> <silent> <nowait> b :<C-U>call <SID>adjust_current_date('-1')<CR>
  nnoremap <buffer> <silent> <nowait> S :<C-U>call <SID>change_span()<CR>
  nnoremap <buffer> <silent> <nowait> / :<C-U>call <SID>filter_agendas()<CR>
endfunction

function! s:agenda_view.unmap() dict
  nunmap <buffer> .
  nunmap <buffer> f
  nunmap <buffer> b
  nunmap <buffer> S
  nunmap <buffer> /
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

function! s:agenda_view.cleanup() dict
  call self.unmap()
  for plugin in values(s:agenda_view_plugins)
    if has_key(plugin, 'cleanup') | call plugin.cleanup() | endif
  endfor
endfunction

function! dotoo#agenda_views#agenda#filter_file_complete(A,L,P)
  return filter(keys(s:agendas), 'v:val =~? a:A')
endfunction

function! dotoo#agenda_views#agenda#filter_tag_complete(A,L,P)
  let tags = []
  for key in keys(s:agendas)
    let headlines = s:agendas[key]
    let htags = map(headlines, 'v:val.tags')
    let htags = map(htags, "substitute(v:val, ' ', '', 'g')")
    let htags = map(htags, "join(split(v:val,':'),'')")
    let htags = filter(htags, '!empty(v:val)')
    call extend(tags, htags)
  endfor
  return uniq(sort(tags))
endfunction

function! dotoo#agenda_views#agenda#filter_complete(A,L,P)
  let ops = ['file', 'tag']
  return filter(ops, 'v:val =~? a:A')
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
  call dotoo#agenda#register_view(s:view_name, s:agenda_view)
endfunction
