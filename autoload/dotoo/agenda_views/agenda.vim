if exists('g:autoloaded_dotoo_agenda_views_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda_views_agenda = 1

function! s:set_agenda_modified(mod)
  let &l:modified = a:mod
endfunction

let s:agenda_deadlines = {}
function! s:build_agendas(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let warning_limit = s:current_date.adjust(g:dotoo#agenda#warning_days)
  if force || empty(s:agenda_deadlines)
    let s:agenda_deadlines = {}
    for dotoos in values(a:dotoos)
      let _deadlines = dotoos.filter('!v:val.done() && !empty(v:val.deadline())',1)
      if s:current_date.is_today()
        let s:current_date = dotoo#time#new()
        let s:agenda_deadlines[dotoos.key] = filter(deepcopy(_deadlines), 'v:val.deadline().before(warning_limit)')
      else
        let s:agenda_deadlines[dotoos.key] = filter(deepcopy(_deadlines), 'v:val.deadline().eq_date(s:current_date)')
      endif
    endfor
  endif
  let agendas = []
  call dotoo#agenda#headlines([])
  let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
  for key in keys(s:agenda_deadlines)
    let headlines = s:agenda_deadlines[key]
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
- call insert(agendas, s:current_date.to_string('%A %d %B %Y'))
  return agendas
endfunction

let s:current_date = dotoo#time#new()
function! s:adjust_current_date(amount)
  if a:amount ==# '.'
    let s:current_date = dotoo#time#new()
  else
    let s:current_date = s:current_date.adjust(a:amount).start_of('day')
  endif
  call dotoo#agenda#refresh_view()
endfunction

" function! s:show_registered_agenda_plugins()
"   for plugin_name in keys(s:agenda_view_plugins)
"     let plugin = s:agenda_view_plugins[plugin_name]
"     if has_key(plugin, 'show')
"       call plugin.show(s:current_date, s:agenda_dotoos)
"     endif
"   endfor
" endfunction

let s:view_name = 'agenda'
let s:agenda_view = {}
function! s:agenda_view.map() dict
  nnoremap <buffer> <silent> <nowait> . :<C-U>call <SID>adjust_current_date('.')<CR>
  nnoremap <buffer> <silent> <nowait> f :<C-U>call <SID>adjust_current_date('+1d')<CR>
  nnoremap <buffer> <silent> <nowait> b :<C-U>call <SID>adjust_current_date('-1d')<CR>
endfunction

function! s:agenda_view.unmap() dict
  nunmap <buffer> .
  nunmap <buffer> f
  nunmap <buffer> b
endfunction

function! s:agenda_view.setup() dict
  call self.map()
endfunction

function! s:agenda_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_agendas(a:dotoos, force)
endfunction

function! s:agenda_view.cleanup() dict
  call self.unmap()
endfunction

" let s:agenda_view_plugins = {}
" function! dotoo#agenda_views#agenda#register_agenda_plugin(name, plugin) abort
"   if type(a:plugin) == type({})
"     let s:agenda_view_plugins[a:name] = a:plugin
"   endif
" endfunction

" function! dotoo#agenda_views#agenda#toggle_agenda_plugin(name) abort
"   if has_key(s:agenda_view_plugins, a:name)
"     let plugin = s:agenda_view_plugins[a:name]
"     call plugin.toggle(s:current_date, s:agenda_dotoos)
"   endif
" endfunction

function! dotoo#agenda_views#agenda#register()
  call dotoo#agenda#register_view(s:view_name, s:agenda_view)
endfunction
