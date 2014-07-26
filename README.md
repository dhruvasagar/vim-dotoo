# VIM Do Too v0.5.0
An awesome task manager & clocker inspired by org-mode written in pure viml.

## Getting Started
1. Document Structure: The docment structure is borrowed from emacs'
   Org Mode, without support for indentation.

   These are the dotoo document mappings :
   * <kbd>gI</kbd>:      clock-in headline under cursor
   * <kbd>gO</kbd>:      clock-out headline under cursor
   * <kbd>cit</kbd>:     change TODO of headline under cursor
   * <kbd>\<C-A\></kbd>:   Increment date under cursor by 1 day, can be preceded with a [count]
   * <kbd>\<C-X\></kbd>:   Decrement date under cursor by 1 day, can be preceded with a [count]
   * <kbd>\<C-C\>\<C-C\></kbd>: Normalize a date (fixes day name if incorrect)

   A few helpful `:iabbrev` :
   * `:date:` Enters the current date
   * `:time:` Enters the current date & time

2. Agenda View: You can have a look at the agenda at anytime using the key
   binding <kbd>gA</kbd>. This opens up a buffer with TODO's that are nearing
   deadline. It provides a variety of mappings to manipulate the TODO
   items from the agenda view itself.

   These are the agenda view mappings :
   * <kbd>q</kbd>:     quit agenda buffer
   * <kbd>r</kbd>:     refresh agenda buffer (force reload / parse agenda files)
   * <kbd>f</kbd>:     go forward by 1 day
   * <kbd>b</kbd>:     go backward by 1 day
   * <kbd>.</kbd>:     go to today's date
   * <kbd>c</kbd>:     change TODO of headline under cursor
   * <kbd>u</kbd>:     undo change in file of headline under the cursor
   * <kbd>s</kbd>:     save all agenda files
   * <kbd>C</kbd>:     trigger capture menu
   * <kbd>i</kbd>:     clock-in for headline under cursor
   * <kbd>o</kbd>:     clock-out for headline under cursor
   * <kbd>R</kbd>:     Report of clocking summary for the day
   * <kbd>T</kbd>:     List unscheduled TODO items
   * <kbd>\<CR\></kbd>:  Open headline under cursor & close agenda
   * <kbd>\<C-S\></kbd>: Open headline under cursor in `split`
   * <kbd>\<C-T\></kbd>: Open headline under cursor in `tab`
   * <kbd>\<C-V\></kbd>: Open headline under cursor in `vsplit`
   * <kbd>\<Tab\></kbd>: same as <kbd>\<C-V\></kbd>

3. Capture: This launches the capture menu that you can use to quickly
   capture TODOs, NOTES etc. This can be invoked using the keybinding
   <kbd>gC</kbd> from anywhere. If you invoke the same from an open dotoo file,
   it will append the captured template into the dotoo file otherwise it
   will append the captured template into the refile file configured by
   g:dotoo#capture#refile

## Credits

This plugin was inspired by the original emacs org-mode and the workflow
described by Bernt Hansen at http://doc.norang.ca/org-mode.html.

I have taken bits of the syntax definitions & ideas from
[vim-orgmode](https://github.com/jceb/vim-orgmode)

I will also like to shout out for bairui http://of-vim-and-vigor.blogspot.in/
who helped me a lot in building this.
