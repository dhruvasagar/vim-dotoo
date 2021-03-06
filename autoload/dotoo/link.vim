let s:link_regex = '\v\[\[([^\]]*)(\]\[)?([^\]]*)\]\]'

function! s:parse_links()
  let matches = []
  let line = getline('.')
  call substitute(line, s:link_regex, '\=add(matches, submatch(0))', 'g')
  let result = []
  for m in matches
    let idx = stridx(line, m)
    call add(result, { 'link': m, 'start': idx, 'end': idx + len(m) })
  endfor
  return result
endfunction

function! s:goto_headline(headline)
  if empty(a:headline)
    return 0
  endif
  call dotoo#agenda#goto_headline('edit', a:headline)
  return 1
endfunction

function! s:goto_headline_by_title(link)
  return s:goto_headline(dotoo#agenda#find_headline_by_title(a:link))
endfunction

function! s:goto_headline_by_title_pointer(link)
  if a:link[0] !=# '*'
    return 0
  endif
  return s:goto_headline(dotoo#agenda#find_headline_by_title(a:link[1:]))
endfunction

function! s:goto_headline_by_custom_id(link)
  if a:link[0] !=# '#'
    return 0
  endif
  return s:goto_headline(dotoo#agenda#find_headline_by_property('CUSTOM_ID', a:link[1:]))
endfunction


function! s:goto_headline_by_dedicated_target(link)
  let val = '<<\s*'.a:link.'\s*>>'
  return s:goto_headline(dotoo#agenda#find_headline_by_title_or_content(val))
endfunction

function! s:goto_file(link)
  if a:link =~# '^file:'
    let file = substitute(a:link, '^file:', '', '')
    exe 'edit' file
    return 1
  endif

  if filereadable(a:link)
    exe 'edit' a:link
    return 1
  endif

  return 0
endfunction

function! s:goto_url(link)
  if a:link =~? '^https\?:\/\/'
    if !exists('g:loaded_netrwPlugin')
      echohl WarningMsg
      echom 'netrw plugin must be loaded in order to open urls.'
      echohl NONE
      return 0
    endif
    call netrw#BrowseX(a:link, netrw#CheckIfRemote())
    return 1
  endif
  return 0
endfunction

" see:
" https://orgmode.org/manual/Internal-Links.html#Internal-Links
" https://orgmode.org/manual/External-Links.html#External-Links
function! dotoo#link#follow(cmd) abort
  let links = s:parse_links()
  let col = col('.') - 1
  let link_on_cursor = get(filter(links, 'col >= v:val.start && col <= v:val.end'), 0, {})
  if empty(link_on_cursor)
    return
  endif
  let parts = matchlist(link_on_cursor.link, s:link_regex)
  let link = trim(parts[1])
  let follow_options = [
        \ 'goto_headline_by_custom_id',
        \ 'goto_headline_by_title_pointer',
        \ 'goto_url',
        \ 'goto_file',
        \ 'goto_headline_by_dedicated_target',
        \ 'goto_headline_by_title'
        \ ]
  for opt in follow_options
    let result = call('s:'.opt, [link])
    if !empty(result)
      break
    endif
  endfor
endfunction
