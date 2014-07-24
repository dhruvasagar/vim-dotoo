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

function! s:view_cleanup(view_name)
  let view = get(s:agenda_views, a:view_name, {})
  if has_key(view, 'cleanup') | call view.cleanup() | endif
endfunction

function! s:show_view(view_name, force)
  let view = get(s:agenda_views, a:view_name, {})
  if has_key(view, 'show')
    call view.show(s:agenda_dotoos, a:force)
  endif
endfunction

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

let s:tmpfile = tempname()
function! dotoo#agenda#edit(cmd)
  silent exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl winheight=20
  setl buftype=acwrite nobuflisted
  setl readonly nomodifiable nofoldenable nolist
  setf dotooagenda
endfunction

let s:current_view = ''
function! dotoo#agenda#agenda()
  let old_view = s:current_view
  let s:current_view = s:agenda_views_menu()
  if old_view !=# s:current_view | call s:view_cleanup(old_view) | endif
  let force = s:add_agenda_file_menu()
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction

function! dotoo#agenda#refresh_view(...)
  let force = a:0 ? a:1 : 1
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction
