# VIM Do Too v0.1.0
An awesome task manager & clocker inspired by org-mode written in pure viml.

## Getting Started
1. Document Structure: The docment structure is borrowed from emacs'
   Org Mode, without support for indentation.

   These are the dotoo document mappings :
        `gI`:         clock-in headline under cursor
        `gO`:         clock-out headline under cursor
        `cit`:        change TODO of headline under cursor
        `<C-A>`:      Increment date under cursor by 1 day, can be preceded
                    with a [count]
        `<C-X>`:      Decrement date under cursor by 1 day, can be preceded
                    with a [count]
        `<C-C><C-C>`: Normalize a date (fixes day name if incorrect)

2. Agenda View: You can have a look at the agenda at anytime using the key
   binding `gA`. This opens up a buffer with TODO's that are nearing
   deadline. It provides a variety of mappings to manipulate the TODO
   items from the agenda view itself.

   These are the agenda view mappings :
        `q`:     quit agenda buffer
        `r`:     refresh agenda buffer (force reload / parse agenda files)
        `f`:     go forward by 1 day
        `b`:     go backward by 1 day
        `.`:     go to today's date
        `c`:     change TODO of headline under cursor
        `u`:     undo change in file of headline under the cursor
        `s`:     save all agenda files
        `C`:     trigger capture menu
        `i`:     clock-in for headline under cursor
        `o`:     clock-out for headline under cursor
        `<CR>`:  Open headline under cursor & close agenda
        `<C-S>`: Open headline under cursor in `split`
        `<C-T>`: Open headline under cursor in `tab`
        `<C-V>`: Open headline under cursor in `vsplit`
        `<Tab>`: same as `<C-V>`

3. Capture: This launches the capture menu that you can use to quickly
   capture TODOs, NOTES etc. This can be invoked using the keybinding
   `gC` from anywhere. If you invoke the same from an open dotoo file,
   it will append the captured template into the dotoo file otherwise it
   will append the captured template into the refile file configured by
   g:dotoo#capture#refile
