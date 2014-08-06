if exists('g:autoloaded_dotoo_parser_properties')
  finish
endif
let g:autoloaded_dotoo_parser_properties = 1

let s:properties_methods = {}
function! s:properties_methods.serialize() dict
  let properties = []
  for property in items(self)
    if type(property[1]) != type(function('tr')) " Skip FuncRef
      call add(properties, ':' . property[0] . ': ' . property[1])
    endif
  endfor
  if !empty(properties)
    call insert(properties, ':PROPERTIES:')
    call add(properties, ':END:')
  endif
  return properties
endfunction

function! s:properties_methods.repeat_to_state() dict
  let self['LAST_REPEAT'] = '['.dotoo#time#new().to_string(g:dotoo#time#datetime_format).']'
  let repeat_to_state = get(self, 'REPEAT_TO_STATE', '')
  return empty(repeat_to_state) ? g:dotoo#parser#todo_keywords[0] : repeat_to_state
endfunction

function! s:properties_methods.is_habit() dict
  return has_key(self, 'STYLE') ? self['STYLE'] ==? 'habit' : 0
endfunction

let s:syntax = dotoo#parser#lexer#syntax()
function! dotoo#parser#properties#new(...)
  let tokens = a:0 ? a:1 : []
  let properties = {}
  while len(tokens)
    let token = remove(tokens, 0)
    if token.type == s:syntax.properties.type
      continue " Skip the :PROPERTIES: token
    elseif token.type == s:syntax.properties_content.type
      let properties[token.content[1]] = token.content[2]
    elseif token.type == s:syntax.drawer_end.type
      break " Skip & end
    endif
  endwhile
  call extend(properties, s:properties_methods)
  return properties
endfunction
