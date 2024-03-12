function ddc#source#vim#get_cur_text(input) abort
  let cur_text = a:input

  let line = '.'->line()
  let cnt = 0
  while cur_text =~# '^\s*\\' && line > 1 && cnt < 5
    let cur_text =
          \ (line - 1)->getline() .. cur_text->substitute('^\s*\\', '', '')
    let line -= 1
    let cnt += 1
  endwhile

  return cur_text->split('\s\+|\s\+\|<bar>', 1)[-1]
endfunction

function! ddc#source#vim#gather(input, complete_str) abort
  const cur_text = ddc#source#vim#get_cur_text(a:input)

  if a:complete_str =~# '^&\%([gl]:\?\)\?'
    " Options.
    const prefix = a:complete_str->matchstr('^&\%([gl]:\?\)\?')
    let list = ddc#source#vim#option(cur_text)->deepcopy()
    for keyword in list
      let keyword.word = prefix .. keyword.word
    endfor
    return list
  elseif cur_text =~# '\<has($\?[''"]\w*$'
    " Features.
    return ddc#source#vim#feature()
  elseif cur_text =~# '\<expand($\?[''"][<>[:alnum:]]*$'
    " Expand.
    return ddc#source#vim#expand()
  elseif a:complete_str =~# '^\$'
    " Environment.
    return ddc#source#vim#environment()
  endif

  return []
endfunction

function ddc#source#vim#environment() abort
  " Make cache.
  if !exists('s:enviroments')
    let s:environments = s:get_envlist()
  endif

  return s:environments
endfunction

function ddc#source#vim#expand() abort
  return s:make_completion_list([
        \ '<cfile>', '<afile>', '<abuf>', '<amatch>',
        \ '<sfile>', '<cword>', '<cWORD>', '<client>'
        \ ])
endfunction

function ddc#source#vim#feature() abort
  if !exists('s:features')
    let s:features = s:make_cache_features()
  endif

  return s:features
endfunction

function ddc#source#vim#filetype() abort
  if !exists('s:filetypes')
    const globs =
          \ 'syntax/*.vim'->globpath(&runtimepath, v:true, v:true) +
          \ 'indent/*.vim'->globpath(&runtimepath, v:true, v:true) +
          \ 'ftplugin/*.vim'->globpath(&runtimepath, v:true, v:true)

    let s:filetypes =
          \ s:make_completion_list(globs->map({
          \   _, val ->
          \   val->fnamemodify(':t:r')->matchstr('^[[:alnum:]-]*')
          \ }))
  endif

  return s:filetypes
endfunction

function ddc#source#vim#option(cur_text) abort
  if a:cur_text =~# '\<set\%[local]\s\+\%(filetype\|ft\)='
    return ddc#source#vim#filetype()
  endif

  if !exists('s:options')
    let s:options = s:make_cache_options()
  endif

  return s:options
endfunction

function! s:make_cache_options() abort
  let options =
        \ 'set all'->execute()->split('\s\{2,}\|\n')[1:]
        \ ->filter({ _, val -> !val->empty() && val =~# '^\h\w*=\?' })
        \ ->map({ _, val -> val->substitute('^no\|=\zs.*$', '', '') })

  for option in options->copy()
    if option[-1:] !=# '='
      call add(options, 'no' .. option)
    endif
  endfor

  return options->filter({ _, val -> val =~# '^\h\w*=\?' })->map({ _, val ->
        \   #{ word: val->substitute('=$', '', ''), kind: 'o' }
        \ })
endfunction

function s:make_cache_features() abort
  const helpfile = 'doc/eval.txt'->findfile(&runtimepath)->expand()
  if !helpfile->filereadable()
    return []
  endif

  let features = []
  const lines = helpfile->readfile()
  const start = lines->match('acl')
  const end = lines->match(has('nvim') ? '^wsl' : '^x11')
  for l in lines[start : end]
    let _ = l->matchlist('^\(\k\+\)\t\+\(.\+\)$')
    if !_->empty()
      call add(features, #{ word : _[1], info : _[2] })
    endif
  endfor

  call add(features, #{
        \   word: 'patch',
        \   menu: '; Included patches Ex: patch123',
        \ })
  call add(features, #{
        \   word: 'patch-',
        \   menu: '; Version and patches Ex: patch-7.4.237',
        \ })

  return features
endfunction

function s:get_envlist() abort
  let keyword_list = []
  for line in 'set'->systemlist()
    let word = '$' .. line->matchstr('^\h\w*')->toupper()
    call add(keyword_list, #{ word : word, kind : 'e' })
  endfor
  return keyword_list
endfunction

function s:make_completion_list(list) abort
  return a:list->copy()->map({ _, val ->
        \   val !=# '' && val[-1:] ==# '/' ?
        \   #{ word: val[:-2], abbr: val } : #{ word: val }
        \ })
endfunction
