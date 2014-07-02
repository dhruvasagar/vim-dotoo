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
  return a:d1.next_deadline().diff(a:d2.next_deadline())
endfunction

let s:dotoo_methods = {}
function! s:dotoo_methods.filter(expr) dict
  let headlines = s:flatten_headlines(self.headlines)
  call filter(headlines, a:expr)
  return sort(headlines, 's:sort_by_deadline')
endfunction

let s:dotoos = {}
let s:syntax = dotoo#parser#lexer#syntax()
let s:parsed_tokens = {}
function! dotoo#parser#parse(file, ...)
  if !filereadable(a:file) | return | endif
  let force = a:0 ? a:1 : 0
  let key = fnamemodify(a:file, ':p:t:r')
  if has_key(s:dotoos, key) && !force
    return s:dotoos[key]
  else
    if force || !has_key(s:dotoos, key)
      let s:dotoos[key] = { 'key': key, 'file': a:file, 'directives': {},
                          \ 'blank_lines': [], 'headlines': [] }
      let s:parsed_tokens[key] = {}
    endif
    let dotoo = s:dotoos[key]
    let tokens = deepcopy(dotoo#parser#lexer#tokenize(a:file))
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
