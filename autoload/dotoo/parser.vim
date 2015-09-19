if exists('g:autoloaded_dotoo_parser')
  finish
endif
let g:autoloaded_dotoo_parser = 1

function! s:readfile(file)
  if !bufloaded(a:file)
    let old_view = winsaveview()
    silent exe 'noauto split' a:file
    quit
    call winrestview(old_view)
  endif
  return getbufline(a:file, 1, '$')
endfunction

function! s:flatten_headlines(headlines)
  let flat_list = []
  let headlines = deepcopy(a:headlines)
  for headline in headlines
    call add(flat_list, headline)
    let flat_list += s:flatten_headlines(headline.headlines)
  endfor
  return flat_list
endfunction

function! s:sort_by_deadline(d1, d2)
  return a:d1.deadline().diff(a:d2.deadline())
endfunction

let s:dotoo_methods = {}
function! s:dotoo_methods.filter(expr,...) dict
  let sort = a:0 ? a:1 : 0
  let headlines = s:flatten_headlines(self.headlines)
  call filter(headlines, a:expr)
  if sort | call sort(headlines, 's:sort_by_deadline') | endif
  return headlines
endif
endfunction

function! s:dotoo_methods.log_summary(time, span) dict
  let headlines = s:flatten_headlines(self.headlines)
  call filter(headlines, '!empty(v:val.log_summary(a:time, a:span))')
  return map(headlines, '[v:val.todo_title(), v:val.log_summary(a:time, a:span)]')
endfunction

let s:dotoos = {}
let s:syntax = dotoo#parser#lexer#syntax()
let s:parsed_tokens = {}
function! dotoo#parser#parse(options) abort
  let opts = extend({'file': expand('%:p'), 'force': 0, 'lines': []}, a:options)
  if has_key(s:dotoos, opts.file) && !opts.force
    return s:dotoos[opts.file]
  else
    if opts.force || !has_key(s:dotoos, opts.file)
      let s:dotoos[opts.file] = {'file': opts.file, 'directives': {},
                          \ 'blank_lines': [], 'headlines': [] }
      let s:parsed_tokens[opts.file] = {}
    endif
    let dotoo = s:dotoos[opts.file]
    let tokens = deepcopy(dotoo#parser#lexer#tokenize(opts.lines))
    while len(tokens)
      let token = remove(tokens, 0)
      if has_key(s:parsed_tokens[opts.file], token.lnum) && s:parsed_tokens[opts.file][token.lnum] == token
        continue
      else
        let s:parsed_tokens[opts.file][token.lnum] = token
      endif
      if token.type ==# s:syntax.directive.type
        call extend(dotoo.directives, dotoo#parser#directive#new(token))
      elseif token.type ==# s:syntax.blank.type
        call add(dotoo.blank_lines, token.lnum)
      elseif token.type ==# s:syntax.headline.type
        call insert(tokens, token) " Re-add token for processing headline
        call add(dotoo.headlines, dotoo#parser#headline#new(dotoo.file, tokens))
      endif
    endwhile
    call extend(dotoo, s:dotoo_methods)
    return dotoo
  endif
endfunction

function! dotoo#parser#parsefile(options) abort
  let opts = extend({'file': expand('%:p'), 'force': 0}, a:options)
  let lines = []
  if expand('%:p') ==# fnamemodify(opts.file, ':p') && &filetype ==# 'dotoo'
    let lines = getline(1,'$')
  elseif filereadable(opts.file) && fnamemodify(opts.file, ':e') =~# '\v^(dotoo|org)$'
    let lines = s:readfile(opts.file)
  else
    return
  endif
  return dotoo#parser#parse({
        \ 'file': opts.file,
        \ 'force': opts.force,
        \ 'lines': lines})
endfunction
