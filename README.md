# VIM Do Too v0.8.4
An awesome task manager & clocker inspired by org-mode written in pure viml.

## Getting Started
1. Document Structure: The docment structure is borrowed from emacs'
   Org Mode.

   These are the dotoo document mappings :
   * <kbd>gI</kbd>:      clock-in headline under cursor
   * <kbd>gO</kbd>:      clock-out headline under cursor
   * <kbd>gM</kbd>:      move headline under cursor to selected target
   * <kbd>cit</kbd>:     change TODO of headline under cursor
   * <kbd>cic</kbd>:     toggle checkbox under cursor
   * <kbd>\<C-A\></kbd>:   Increment date under cursor by 1 day, can be preceded with a [count]
   * <kbd>\<C-X\></kbd>:   Decrement date under cursor by 1 day, can be preceded with a [count]
   * <kbd>\<C-C\>\<C-C\></kbd>: Normalize a date (fixes day name if incorrect)

   A few helpful `:iabbrev` :
   * `:date:` Enters the current date
   * `:time:` Enters the current date & time

2. Agenda Views: You can have a look at the agenda views at anytime using the key
   binding <kbd>gA</kbd>, this displays the list of currently registered
   agenda views available, selecting one of them then opens up the view. The
   agenda views pulls information from agenda files, this can be configured by
   setting `g:dotoo#agenda#files` which is a list of file names / file blobs.

   These are the agenda view mappings common to all :
   * <kbd>q</kbd>:     quit agenda buffer
   * <kbd>r</kbd>:     refresh agenda buffer (force reload / parse agenda files)
   * <kbd>c</kbd>:     change TODO of headline under cursor
   * <kbd>u</kbd>:     undo change in file of headline under the cursor
   * <kbd>s</kbd>:     save all agenda files
   * <kbd>C</kbd>:     trigger capture menu
   * <kbd>i</kbd>:     clock-in for headline under cursor
   * <kbd>o</kbd>:     clock-out for headline under cursor
   * <kbd>m</kbd>:     Move headline to selected target
   * <kbd>/</kbd>:     Filter by file, tags or todos
   * <kbd>\<CR\></kbd>:  Open headline under cursor & close agenda
   * <kbd>\<C-S\></kbd>: Open headline under cursor in `split`
   * <kbd>\<C-T\></kbd>: Open headline under cursor in `tab`
   * <kbd>\<C-V\></kbd>: Open headline under cursor in `vsplit`
   * <kbd>\<Tab\></kbd>: same as <kbd>\<C-V\></kbd>

   There are 4 views available currently :

   1. Agenda View : This displays all TODOs that are nearing deadline.
      deadline. It provides a variety of mappings to manipulate the TODO items
      from the agenda view itself.

      These are mappings specific to agenda view:
      * <kbd>f</kbd>:     go forward by 1 day
      * <kbd>b</kbd>:     go backward by 1 day
      * <kbd>.</kbd>:     go to today's date
      * <kbd>S</kbd>:     Change agenda span to day, week or month
      * <kbd>R</kbd>:     Report of clocking summary for the current span

   2. TODOs View : This displays all unscheduled TODO items from your agenda
      files.

   3. Refiles : This displays all headlines in the refile file that you should
      then move to an appropriate target file / project / headline.

   4. Notes : This displays all the notes from all the agenda files.


3. Capture: This launches the capture menu that you can use to quickly
   capture TODOs, NOTES etc. This can be invoked using the keybinding
   <kbd>gC</kbd> from anywhere. The capture launches with a split window in
   select mode, you can just start typing to edit the capture. On saving the
   capture is then moved to the refile file, this can be configured using
   `g:dotoo#capture#refile`. You can always look at your refiles in the
   refiles view and move them to the desired target file / headline from
   there. Capture also clocks the tasks so you can log how much time was spent
   doing them by default, you can disable this behavior by setting
   `let g:dotoo#capture#clock = 0`.

## Screenshots

1. Agenda Menu - <img src="http://i.imgur.com/17doNZn.png"/>
2. Agenda View - <img src="http://i.imgur.com/Jstc961.png"/>
4. Agenda View with Log Summary - <img src="http://i.imgur.com/7sSV5dm.png"/>
5. Todos View - <img src="http://i.imgur.com/0Jg0Ezs.png"/>
6. Refile View - <img src="http://i.imgur.com/HoSJkEu.png"/>
7. Notes View - <img src="http://i.imgur.com/TyEeNWa.png"/>

## Credits

This plugin was inspired by the original emacs org-mode and the workflow
described by Bernt Hansen at http://doc.norang.ca/org-mode.html.

I have taken bits of the syntax definitions & ideas from
[vim-orgmode](https://github.com/jceb/vim-orgmode)

I will also like to shout out for bairui http://of-vim-and-vigor.blogspot.in/
who helped me a lot in building this.
