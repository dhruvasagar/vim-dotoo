let s:caches = {}

let s:cache_methods = {}
function! s:cache_methods.get(key) dict
  return self.data[a:key]
endfunction

function! s:cache_methods.insert(key, value) dict
  let self.data[a:key] = a:value
endfunction

function! s:cache_methods.remove(key) dict
  call remove(self.data, a:key)
endfunction

function! dotoo#cache#new(name)
  let cache = {'data': {}}
  call extend(cache, s:cache_methods)
  let s:caches[a:name] = cache
  return cache
endfunction

function! dotoo#cache#inspect(...)
  let name = a:0 == 1 ? a:1 : {}
  if empty(name)
    echo string(s:caches)
  else
    echo string(s:s:caches[name])
  endif
endfunction
