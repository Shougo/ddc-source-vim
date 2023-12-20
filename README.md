# ddc-source-vim

Vim script completion for ddc.vim

This source collects Vim script items.

## Required

### denops.vim

https://github.com/vim-denops/denops.vim

### ddc.vim

https://github.com/Shougo/ddc.vim

### neco-vim

https://github.com/Shougo/neco-vim

## Configuration

```vim
call ddc#custom#patch_filetype('vim', 'sources', ['vim'])

call ddc#custom#patch_global('sourceOptions', #{
      \   vim: #{ mark: 'vim' },
      \ })
```
