function! s:TestCacheNew()
  let cache = dotoo#cache#new('test')
  call testify#assert#equals(type(cache), v:t_dict)
  call testify#assert#equals(sort(keys(cache)), sort(['get', 'insert', 'remove', 'data']))
endfunction
call testify#it('Should initialize a new cache', function('s:TestCacheNew'))

function! s:TestCacheInsert()
  let cache = dotoo#cache#new('test')
  call cache.insert('testkey', 'testval')
  call testify#assert#equals(cache.data, {'testkey': 'testval'})
endfunction
call testify#it('Should insert a key, value in cache successfully', function('s:TestCacheInsert'))

function! s:TestCacheGet()
  let cache = dotoo#cache#new('test')
  call cache.insert('testkey', 'testval')
  call testify#assert#equals(cache.get('testkey'), 'testval')
endfunction
call testify#it('Should get the value of a given key successfully', function('s:TestCacheGet'))

function! s:TestCacheRemove()
  let cache = dotoo#cache#new('test')
  call cache.insert('testkey', 'testval')
  call cache.remove('testkey')
  call testify#assert#equals(cache.data, {})
endfunction
call testify#it('Should remove the key, value from cache successfully', function('s:TestCacheRemove'))
