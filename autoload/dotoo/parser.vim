if exists('g:autoloaded_dotoo_parser')
  finish
endif
let g:autoloaded_dotoo_parser = 1

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
function! s:dotoo_methods.filter(expr) dict
  let headlines = s:flatten_headlines(self.headlines)
  call filter(headlines, a:expr)
  return sort(headlines, 's:sort_by_deadline')
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
  let opts = extend({'key': '', 'file': expand('%:p'), 'force': 0, 'lines': []}, a:options)
  let key = opts.key
  if has_key(s:dotoos, key) && !opts.force
    return s:dotoos[key]
  else
    if opts.force || !has_key(s:dotoos, key)
      let s:dotoos[key] = { 'key': key, 'file': opts.file, 'directives': {},
                          \ 'blank_lines': [], 'headlines': [] }
      let s:parsed_tokens[key] = {}
    endif
    let dotoo = s:dotoos[key]
    let tokens = deepcopy(dotoo#parser#lexer#tokenize(opts.lines))
    while len(tokens)
      let token = remove(tokens, 0)
      if has_key(s:parsed_tokens[key], token.lnum) && s:parsed_tokens[key][token.lnum] == token
        continue
      else
        let s:parsed_tokens[key][token.lnum] = token
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
  if !filereadable(opts.file) || fnamemodify(opts.file, ':e') !=? 'dotoo' | return | endif
  let key = fnamemodify(opts.file, ':p:t:r')
  return dotoo#parser#parse({
        \ 'key': key,
        \ 'file': opts.file,
        \ 'force': opts.force,
        \ 'lines': readfile(opts.file)})
endfunction
