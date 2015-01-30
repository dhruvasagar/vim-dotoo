if exists('g:autoloaded_dotoo_parser_metadata')
  finish
endif
let g:autoloaded_dotoo_parser_metadata = 1

let s:metadata_methods = {}
function! s:metadata_methods.serialize() dict
  if has_key(self, 'deadline')
    return 'DEADLINE: ' . self.lsep . self.deadline.to_string() . self.rsep
  elseif has_key(self, 'scheduled')
    return 'SCHEDULED: ' . self.lsep . self.scheduled.to_string() . self.rsep
  elseif has_key(self, 'closed')
    return 'CLOSED: ' . self.lsep . self.closed.to_string() . self.rsep
  endif
  return ''
endfunction

function! s:metadata_methods.set_future_date() dict
  if has_key(self, 'deadline')
    let self.deadline = self.deadline.next_repeat()
  elseif has_key(self, 'scheduled')
    let self.scheduled = self.scheduled.next_repeat()
  endif
endfunction

function! s:metadata_methods.close() dict
  if has_key(self, 'deadline')
    call remove(self, 'deadline')
  elseif has_key(self, 'scheduled')
    call remove(self, 'scheduled')
  endif
  let self.closed = dotoo#time#new()
endfunction

function! dotoo#parser#metadata#new(...)
  let token = a:0 ? a:1 : 0
  let metadata = {}
  if !empty(token)
    let metadata.lsep = token.content[1]
    let metadata.rsep = token.content[3]
    let metadata[tolower(token.content[0])] = dotoo#time#new(token.content[2])
  endif
  call extend(metadata, s:metadata_methods)
  return metadata
endfunction
