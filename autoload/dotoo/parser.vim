if exists('g:autoloaded_dotoo_parser')
  finish
endif
let g:autoloaded_dotoo_parser = 1

let s:dotoo_methods = {}
function! s:dotoo_methods.filter(expr) dict
  return self.root_headline.filter(a:expr)
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
      let root_headline = dotoo#parser#headline#new()
      let s:dotoos[key] = { 'key': key, 'file': a:file, 'directives': {},
                          \ 'blank_lines': [], 'root_headline': root_headline }
      let s:parsed_tokens[key] = {}
    endif
    let dotoo = s:dotoos[key]
    let tree = {}
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
        call insert(tokens, token) " Add current headline for processing
        let headline = dotoo#parser#headline#new(dotoo.file, tokens)
        let parent = headline.level == 1 ? dotoo.root_headline : tree[headline.level - 1]
        let tree[headline.level] = headline
        call add(parent.headlines, headline)
      endif
    endwhile
    call extend(dotoo, s:dotoo_methods)
    return dotoo
  endif
endfunction
