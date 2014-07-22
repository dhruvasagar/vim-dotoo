if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

call dotoo#utils#set('dotoo#agenda#warning_days', '30d')
call dotoo#utils#set('dotoo#agenda#files', ['~/Documents/dotoo-files/*.dotoo'])

" Private API {{{1
let s:dotoo_files = []
let s:agenda_dotoos = {}
function! s:parse_dotoos(file,...)
  let force = a:0 ? a:1 : 0
  if index(s:dotoo_files, a:file) < 0
    call add(s:dotoo_files, a:file)
  endif
  let dotoos = dotoo#parser#parsefile({'file': a:file, 'force': force})
  let s:agenda_dotoos[a:file] = dotoos
endfunction

function! s:load_agenda_files(...)
  let force = a:0 ? a:1 : 0
  if force | let s:dotoo_files = [] | endif
  if force | let s:agenda_dotoos = {} | endif
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      call s:parse_dotoos(orgfile, force)
    endfor
  endfor
endfunction

function! s:agenda_views_menu()
  let views = keys(s:agenda_views)
  let acceptable_input = '['.join(map(copy(views), 'v:val[0]'),'').']'
  call map(views, '"(".tolower(v:val[0]).") ".v:val')
  call add(views, 'Select agenda view: ')
  let selected = dotoo#utils#getchar(join(views, "\n"), acceptable_input)
  let sel = filter(keys(s:agenda_views), "v:val =~# '^'.selected.'.*'")
  return !empty(sel) ? sel[0] : ''
endfunction

function! s:has_agenda_file(...)
  let afile = a:0 ? a:1 : expand('%:p')
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      if orgfile ==# afile | return 1 | endif
    endfor
  endfor
endfunction

function! s:add_agenda_file(...)
  let file = a:0 ? a:1 : expand('%:p')
  call add(g:dotoo#agenda#files, file)
endfunction

function! s:add_agenda_file_menu()
  if expand('%:e') ==# 'dotoo' && !s:has_agenda_file()
    if dotoo#utils#getchar('Do you wish to add the current file in agenda files? (y/n): ', '[yn]') == 'y'
      call s:add_agenda_file()
      return 1
    endif
  endif
  return 0
endfunction

" function! s:show_registered_agenda_plugins()
"   for plugin_name in keys(s:agenda_view_plugins)
"     let plugin = s:agenda_view_plugins[plugin_name]
"     if has_key(plugin, 'show')
"       call plugin.show(s:current_date, s:agenda_dotoos)
"     endif
"   endfor
" endfunction

" Public API {{{1
let s:agenda_views = {}
function! dotoo#agenda#register_view(name, plugin) abort
  if type(a:plugin) == type({})
    let s:agenda_views[a:name] = a:plugin
  endif
endfunction

function! dotoo#agenda#save_files()
  let old_view = winsaveview()
  for _file in s:dotoo_files
    if bufexists(_file)
      exec 'buffer' _file
      write
    endif
  endfor
  setl nomodified
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

" let s:agenda_view_plugins = {}
" function! dotoo#agenda#register_agenda_plugin(name, plugin) abort
"   if type(a:plugin) == type({})
"     let s:agenda_view_plugins[a:name] = a:plugin
"   endif
" endfunction

" function! dotoo#agenda#toggle_agenda_plugin(name) abort
"   if has_key(s:agenda_view_plugins, a:name)
"     let plugin = s:agenda_view_plugins[a:name]
"     call plugin.toggle(s:current_date, s:agenda_dotoos)
"   endif
" endfunction

" function! dotoo#agenda#add_file_to_agenda_menu()
"   if expand('%:e') ==# 'dotoo' && !s:has_agenda_file()
"     if dotoo#utils#getchar('Do you wish to add the current file in agenda files? (y/n): ', '[yn]') == 'y'
"       call s:add_agenda_file()
"       return 1
"     endif
"   endif
"   return 0
" endfunction

let s:tmpfile = tempname()
function! dotoo#agenda#edit(cmd)
  silent exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl winheight=20
  setl buftype=acwrite nobuflisted
  setl readonly nofoldenable nolist
  setf dotooagenda
endfunction

let s:current_view = ''
function! dotoo#agenda#agenda()
  let s:current_view = s:agenda_views_menu()
  let view_plugin = get(s:agenda_views, s:current_view, {})
  if has_key(view_plugin, 'show')
    let force = s:add_agenda_file_menu()
    call s:load_agenda_files(force)
    call view_plugin.show(s:agenda_dotoos, force)
  endif
endfunction

function! dotoo#agenda#refresh_view(...)
  let force = a:0 ? a:1 : 1
  call s:load_agenda_files(force)
  if has_key(s:agenda_views, s:current_view)
    let view_plugin = s:agenda_views[s:current_view]
    if has_key(view_plugin, 'show')
      call view_plugin.show(s:agenda_dotoos, force)
    endif
  endif
endfunction
