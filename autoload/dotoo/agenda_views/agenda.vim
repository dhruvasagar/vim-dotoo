if exists('g:autoloaded_dotoo_agenda_views_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda_views_agenda = 1

function! s:set_agenda_modified(mod)
  let &l:modified = a:mod
endfunction

let s:agenda_deadlines = {}
let s:agenda_headlines = []
function! s:build_agendas(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let warning_limit = s:current_date.adjust(g:dotoo#agenda#warning_days)
  let add_agenda_headlines = force || empty(s:agenda_headlines)
  if force || empty(s:agenda_deadlines)
    let s:agenda_deadlines = {}
    let s:agenda_headlines = []
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
  let time_pf = g:dotoo#time#time_ago_short ? ' %10s: ' : ' %20s: '
  for key in keys(s:agenda_deadlines)
    let headlines = s:agenda_deadlines[key]
    if add_agenda_headlines | call extend(s:agenda_headlines, headlines) | endif
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
  return agendas
endfunction

function! s:agenda_view(agendas)
  let old_view = winsaveview()
  call dotoo#agenda#edit('pedit!')
  setl modifiable
  silent normal! ggdG
  silent call setline(1, s:current_date.to_string('%A %d %B %Y'))
  silent call setline(2, a:agendas)
  setl nomodified nomodifiable
  call winrestview(old_view)
endfunction

function! s:goto_headline(cmd)
  let headline = s:agenda_headlines[line('.')-2]
  if a:cmd ==# 'edit' | quit | split | endif
  exec a:cmd '+'.headline.lnum headline.file
  if empty(&filetype) | edit | endif
  normal! zv
endfunction

function! s:start_headline_clock()
  let old_view = winsaveview()
  call dotoo#agenda_views#agenda#goto_headline('edit')
  call dotoo#clock#start()
  call dotoo#agenda#refresh_view()
  call s:set_agenda_modified(1)
  call winrestview(old_view)
endfunction

function! s:stop_headline_clock()
  let old_view = winsaveview()
  call dotoo#agenda_views#agenda#goto_headline('edit')
  call dotoo#clock#stop()
  call dotoo#agenda#refresh_view()
  call s:set_agenda_modified(1)
  call winrestview(old_view)
endfunction

function! s:change_headline_todo()
  let headline = s:agenda_headlines[line('.')-2]
  let selected = dotoo#utils#change_todo_menu()
  if !empty(selected)
    call headline.change_todo(selected)
    let old_view = winsaveview()
    call headline.save()
    call dotoo#agenda#refresh_view(0)
    call s:set_agenda_modified(getbufvar(bufnr('#'), '&modified'))
    call winrestview(old_view)
  endif
endfunction

function! s:undo_headline_change()
  let headline = s:agenda_headlines[line('.')-2]
  let old_view = winsaveview()
  call headline.undo()
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
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
  nnoremap <buffer> <silent> <nowait> c :<C-U>call <SID>change_headline_todo()<CR>
  nnoremap <buffer> <silent> <nowait> u :<C-U>call <SID>undo_headline_change()<CR>
  nnoremap <buffer> <silent> <nowait> i :<C-U>call <SID>start_headline_clock()<CR>
  nnoremap <buffer> <silent> <nowait> o :<C-U>call <SID>stop_headline_clock()<CR>
  nnoremap <buffer> <silent> <nowait> <CR> :<C-U>call <SID>goto_headline('edit')<CR>
  nnoremap <buffer> <silent> <nowait> <C-S> :<C-U>call <SID>goto_headline('split')<CR>
  nnoremap <buffer> <silent> <nowait> <C-V> :<C-U>call <SID>goto_headline('vsplit')<CR>
  nnoremap <buffer> <silent> <nowait> <C-T> :<C-U>call <SID>goto_headline('tabe')<CR>
  nmap <buffer> <silent> <Tab> <C-V>
endfunction

function! s:agenda_view.unmap() dict
  nunmap <buffer> .
  nunmap <buffer> f
  nunmap <buffer> b
  nunmap <buffer> c
  nunmap <buffer> u
  nunmap <buffer> i
  nunmap <buffer> o
  nunmap <buffer> <CR>
  nunmap <buffer> <C-S>
  nunmap <buffer> <C-V>
  nunmap <buffer> <C-T>
  nunmap <buffer> <Tab>
endfunction

function! s:agenda_view.show(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  call s:agenda_view(s:build_agendas(a:dotoos, force))
  call self.map()
endfunction

function! s:agenda_view.cleanup() dict
  call dotoo#agenda#edit('pedit!')
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
