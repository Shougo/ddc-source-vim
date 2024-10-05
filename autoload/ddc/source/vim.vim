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
  const cur_text = a:input->ddc#source#vim#get_cur_text()

  if a:complete_str =~# '^&\%([gl]:\?\)\?'
    " Options.
    const prefix = a:complete_str->matchstr('^&\%([gl]:\?\)\?')
    let list = cur_text->ddc#source#vim#option()->deepcopy()
    for keyword in list
      let keyword.word = prefix .. keyword.word
    endfor
    return list
  elseif cur_text =~# '^\w*map\s'
    " Maps.
    return ddc#source#vim#map()
  elseif cur_text =~# '\<has($\?[''"]\w*$'
    " Features.
    return ddc#source#vim#feature()
  elseif cur_text =~# '\<expand($\?[''"][<>[:alnum:]]*$'
    " Expand.
    return ddc#source#vim#expand()
  elseif cur_text =~# '\$["''].*{\zs[^}]*$'
    " String interpolation.
    return a:complete_str
          \ ->getcompletion('expression')
          \ ->s:make_completion_list()
  elseif a:complete_str =~# '^\$'
    " Environment.
    return ddc#source#vim#environment()
  endif

  return []
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

function ddc#source#vim#map() abort
  if !exists('s:maps')
    let s:maps = s:make_cache_maps() + s:make_cache_keys()
  endif

  return s:maps
endfunction

function ddc#source#vim#feature() abort
  return [
        \   #{
        \     word: 'patch',
        \     menu: '; Included patches Ex: patch123',
        \   },
        \   #{
        \     word: 'patch-',
        \     menu: '; Version and patches Ex: patch-7.4.237',
        \   },
        \ ]
endfunction

function ddc#source#vim#expand() abort
  return [
        \   '<cfile>',
        \   '<afile>',
        \   '<abuf>',
        \   '<amatch>',
        \   '<cexpr>',
        \   '<sfile>',
        \   '<slnum>',
        \   '<sflnum>',
        \   '<SID>',
        \   '<script>',
        \   '<stack>',
        \   '<cword>',
        \   '<cWORD>',
        \   '<client>',
        \   ':p',
        \   ':h',
        \   ':t',
        \   ':r',
        \   ':e',
        \ ]->s:make_completion_list()
endfunction

function ddc#source#vim#environment() abort
  " Make cache.
  if !exists('s:enviroments')
    let s:environments = s:get_envlist()
  endif

  return s:environments
endfunction

function ddc#source#vim#filetype() abort
  if !exists('s:filetypes')
    const globs =
          \ 'syntax/*.vim'->globpath(&runtimepath, v:true, v:true) +
          \ 'indent/*.vim'->globpath(&runtimepath, v:true, v:true) +
          \ 'ftplugin/*.vim'->globpath(&runtimepath, v:true, v:true)

    let s:filetypes =
          \ globs->map({
          \   _, val ->
          \   val->fnamemodify(':t:r')->matchstr('^[[:alnum:]-]*')
          \ })->s:make_completion_list()
  endif

  return s:filetypes
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

  return options
        \ ->filter({ _, val -> val =~# '^\h\w*=\?' })
        \ ->map({
        \   _, val ->
        \   #{ word: val->substitute('=$', '', ''), kind: 'o' }
        \ })
endfunction

function s:make_cache_maps() abort
  const helpfile = 'doc/map.txt'->findfile(&runtimepath)->expand()
  if !helpfile->filereadable()
    return []
  endif

  const lines = helpfile->readfile()
  const start = lines->match('1. Key mapping')
  const end = lines->match('2. Abbreviations')

  return lines[start : end]->map({
        \   _, val -> val->matchstr('\*\%(:map-\)\?\zs\(<\k\+>\)\ze\*')
        \ })->filter({ _, val -> val !=# ''})->s:make_completion_list()
endfunction

function s:make_cache_keys() abort
  const helpfile = 'doc/intro.txt'->findfile(&runtimepath)->expand()
  if !helpfile->filereadable()
    return []
  endif

  const lines = helpfile->readfile()
  const start = lines->match('*key-notation')
  const end = lines->match('*vim-modes-intro*')

  let keys = [
        \   '<LeftMouse>', '<RightMouse>', '<LeftRelease>',
        \ ] + lines[start : end]->map({
        \   _, val -> val->matchstr('<\k\+>')->substitute('-…>', '-', '')
        \ })->filter({ _, val -> val !=# ''})

  return keys->s:make_completion_list()
endfunction

function s:get_envlist() abort
  return 'set'->systemlist()->map({
        \ _, val ->
        \  #{
        \     word: '$' .. val->matchstr('^\h\w*')->toupper(),
        \     kind: 'e',
        \   }
        \ })
endfunction

function s:make_completion_list(list) abort
  return a:list->uniq()->map({
        \ _, val ->
        \   val !=# '' && val[-1:] ==# '/' ?
        \   #{
        \     word: val[:-2],
        \     abbr: val,
        \   } : #{
        \     word: val,
        \   }
        \ })
endfunction
