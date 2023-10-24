# VIM Do Too v0.14.3.2 [![Build](https://github.com/dhruvasagar/vim-dotoo/actions/workflows/ci.yml/badge.svg)](https://github.com/dhruvasagar/vim-dotoo/actions/workflows/ci.yml)

An awesome task manager & clocker inspired by org-mode written in pure viml.

## Pre-requisites

It is recommended that you enable the vim setting `'hidden'` which allows us
to keep dotoo files hidden in the background for the purpose of showing
accurate agenda information and also for faster updates to these files.

## Getting Started

1. Document Structure: The document structure is borrowed from emacs'
   Org Mode.

   > NOTE : Check out the file `dotoo.dotoo` in this repo as an example

   These are the dotoo document mappings :

   - <kbd>gI</kbd>: clock-in headline under cursor
   - <kbd>gO</kbd>: clock-out headline under cursor
   - <kbd>gM</kbd>: move headline under cursor to selected target
   - <kbd>cit</kbd>: change TODO of headline under cursor
   - <kbd>cic</kbd>: toggle checkbox under cursor
   - <kbd>\<C-A\></kbd>: Increment date under cursor by 1 day, can be preceded with a [count]
   - <kbd>\<C-X\></kbd>: Decrement date under cursor by 1 day, can be preceded with a [count]
   - <kbd>\<C-C\>\<C-C\></kbd>: Normalize a date (fixes day name if incorrect)
   - <kbd>\<Tab></kbd>: Cycle headline visibility similar to Org mode
   - <kbd>\<CR></kbd>: Follow link under cursor
   - <kbd>\<BS></kbd>: Go back to previous document after following a link

   The <kbd>\<C-X\></kbd>, <kbd>\<C-A\></kbd>, and <kbd>cic</kbd> commands all work with <kbd>.</kbd>
   if you have [repeat.vim](http://github.com/tpope/vim-repeat) installed

   A few helpful `:iabbrev`:

   - `:date:` Enters the current date
   - `:time:` Enters the current time
   - `:datetime:` Enters the current date & time

2. Agenda Views: You can have a look at the agenda views at anytime using the key
   binding <kbd>gA</kbd>, this displays the list of currently registered
   agenda views available, selecting one of them then opens up the view. The
   agenda views pulls information from agenda files, this can be configured by
   setting `g:dotoo#agenda#files` which is a list of file names / file blobs.

   These are the agenda view mappings common to all :

   - <kbd>gq</kbd>: quit agenda buffer
   - <kbd>r</kbd>: refresh agenda buffer (force reload / parse agenda files)
   - <kbd>c</kbd>: change TODO of headline under cursor
   - <kbd>u</kbd>: undo change in file of headline under the cursor
   - <kbd>s</kbd>: save all agenda files
   - <kbd>C</kbd>: trigger capture menu
   - <kbd>i</kbd>: clock-in for headline under cursor
   - <kbd>o</kbd>: clock-out for headline under cursor
   - <kbd>m</kbd>: Move headline to selected target
   - <kbd>/</kbd>: Filter by file, tags or todos
   - <kbd>\<CR\></kbd>: Open headline under cursor & close agenda
   - <kbd>\<C-S\></kbd>: Open headline under cursor in `split`
   - <kbd>\<C-T\></kbd>: Open headline under cursor in `tab`
   - <kbd>\<C-V\></kbd>: Open headline under cursor in `vsplit`
   - <kbd>\<Tab\></kbd>: same as <kbd>\<C-V\></kbd>

   1. Agenda View : This displays all TODOs that are nearing deadline.
      It provides a variety of mappings to manipulate the TODO items
      from the agenda view itself.

      These are mappings specific to agenda view:

      - <kbd>f</kbd>: go forward by 1 day
      - <kbd>b</kbd>: go backward by 1 day
      - <kbd>.</kbd>: go to today's date
      - <kbd>S</kbd>: Change agenda span to day, week or month
      - <kbd>R</kbd>: Report of clocking summary for the current span

   2. TODOs View : This displays all unscheduled TODO items from your agenda
      files.

   3. Refiles : This displays all headlines in the refile file that you should
      then move to an appropriate target file / project / headline.

   4. Notes : This displays all the notes from all the agenda files.

   5. Tagged : This lists all headlines that have tags.

   6. Search : This lists all headlines that match an input search
      term.

   7. Wiki : This lists all headlines that have `notes` in the path, assuming
      you manage notes in a notes folder that is under the agenda files path.
      This is better than Notes view since it does not require the presence of
      `:NOTE:` tag. If you just want to see everything in your knowledge base
      at a quick glance this is useful.

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
3. Agenda View with Log Summary - <img src="http://i.imgur.com/7sSV5dm.png"/>
4. Todos View - <img src="http://i.imgur.com/0Jg0Ezs.png"/>
5. Refile View - <img src="http://i.imgur.com/HoSJkEu.png"/>
6. Notes View - <img src="http://i.imgur.com/TyEeNWa.png"/>

## Screencast

https://www.youtube.com/watch?v=nsv33iOnH34

## Credits

This plugin was inspired by the original emacs org-mode and the workflow
described by Bernt Hansen at http://doc.norang.ca/org-mode.html.

I have taken bits of the syntax definitions & ideas from
[vim-orgmode](https://github.com/jceb/vim-orgmode)

I will also like to shout out for bairui http://of-vim-and-vigor.blogspot.in/
who helped me a lot in building this.

## Contributors

### Code Contributors

This project exists thanks to all the people who contribute. [[Contribute](https://opencollective.com/vim-dotoo/contribute)].
<a href="https://github.com/dhruvasagar/vim-dotoo/graphs/contributors"><img src="https://opencollective.com/vim-dotoo/contributors.svg?width=890&button=false" /></a>

### Financial Contributors

Become a financial contributor and help us sustain our community. [[Contribute](https://opencollective.com/vim-dotoo/contribute)]

#### Individuals

<a href="https://opencollective.com/vim-dotoo"><img src="https://opencollective.com/vim-dotoo/individuals.svg?width=890"></a>

#### Organizations

Support this project with your organization. Your logo will show up here with a link to your website. [[Contribute](https://opencollective.com/vim-dotoo/contribute)]

<a href="https://opencollective.com/vim-dotoo/organization/0/website"><img src="https://opencollective.com/vim-dotoo/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/1/website"><img src="https://opencollective.com/vim-dotoo/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/2/website"><img src="https://opencollective.com/vim-dotoo/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/3/website"><img src="https://opencollective.com/vim-dotoo/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/4/website"><img src="https://opencollective.com/vim-dotoo/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/5/website"><img src="https://opencollective.com/vim-dotoo/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/6/website"><img src="https://opencollective.com/vim-dotoo/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/7/website"><img src="https://opencollective.com/vim-dotoo/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/8/website"><img src="https://opencollective.com/vim-dotoo/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/vim-dotoo/organization/9/website"><img src="https://opencollective.com/vim-dotoo/organization/9/avatar.svg"></a>
