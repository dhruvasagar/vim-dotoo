function! s:TestHeadlines()
  let dotoos = dotoo#parser#parsefile({'file': 't/fixtures/sample.dotoo'})
  call testify#assert#equals(dotoos.file, 't/fixtures/sample.dotoo')
  call testify#assert#equals(len(dotoos.headlines), 19)
endfunction
call testify#it('Should parse headlines', function('s:TestHeadlines'))

function! s:TestDirectives()
  let dotoos = dotoo#parser#parsefile({'file': 't/fixtures/sample.dotoo'})
  call testify#assert#equals(dotoos.directives['TITLE'], 'Dotoo Tasks')
  call testify#assert#equals(dotoos.directives['EMAIL'], 'dhruva.sagar@gmail.com')
  call testify#assert#equals(dotoos.directives['AUTHOR'], 'Dhruva Sagar')
endfunction
call testify#it('Should have right directives', function('s:TestDirectives'))

function! s:TestFilter()
  let dotoos = dotoo#parser#parsefile({'file': 't/fixtures/sample.dotoo'})
  call testify#assert#equals(len(dotoos.filter('v:val.done()')), 7)
  call testify#assert#equals(len(dotoos.filter('v:val.todo ==# "TODO"')), 12)
  call testify#assert#equals(len(dotoos.filter('v:val.todo ==# "CANCELLED"')), 1)
  call testify#assert#equals(len(dotoos.filter('empty(v:val.metadate())')), 8)
  call testify#assert#equals(len(dotoos.filter('!empty(v:val.metadate()) && !v:val.done()')), 4)
endfunction
call testify#it('Should filter dotoos', function('s:TestFilter'))
