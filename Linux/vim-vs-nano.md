# Useful Commands and Operations of Vim and Nano
Here are the useful commands and operations of Vim and Nano, two different terminal-based text editors in Unix.

## Vim
Vim has three main modes:
- Normal (navigation) mode which can be reached by presing `ESC` or `Ctrl + c`.
- Command (opertation) mode which can be reached by presing `:`.
- Insert (modification) mode which can be reached by presing `i`.

## Vim vs. Nano
### Basic Commands & Operations
| Command | Nano | Vim | Description |
| :------ | :--: | :-: | :---------- |
| Open | ` ` | `:e FILE_NAME` |  |
| Save | `Ctrl + o` | `:w` |  |
| Save As | `Ctrl + o` | `:w FILE_NAME` |  |
| Save & Exit | `Ctrl + x` | `:wq` or `:x` |  |
| Select | `Alt + a` | `v` | Use arrow keys to add/remove characters. |
| Select Line | ` ` | `V` |  |
| Copy | `Alt + 6` | `y` |  |
| Copy Line | ` ` | `yy` |  |
| Copy Word | ` ` | `yw` |  |
| Paste | `Ctrl + u` | `p` |  |
| Delete Selected Text | `Ctrl + k` | `d` | In both, _cut_ and _delete_ are the same. |
| Delete a Word | ` ` | on a word type `dw` |  |
| Delete a Line | ` ` | on a line type `dd` |  |
| Cut | `Ctrl + k` | `d` or `dd` or `dw` |  |
| Undo | `Alt + u` | `u` |  |
| Redo | `Alt + e` | `Ctrl + r` |  |
| Quit | `Ctrl + x` | `:q` |  |
| Quit (no change) | `Ctrl + x` | `:q!` |  |
| Find & Replace | `Ctrl + \` | `:%s/TERM/NEW_TERM/g` |  |
| Search | `Ctrl + w` | `/TERM` |  |
| Search Backward | `Ctrl + w` | `?TERM` |  |
| Walk Through Search Results | `Alt + w` | `n` and `N` |  |
| Go to Line & Column | `Ctrl + -` | `:LINE_NUMBER` | In `nano` use `,` to differ the line and column numbers |
| Show Cursor Position | `Ctrl + c` | `b` or `Ctrl + ←` |  |

### Multiple Files Handeling
| Operation | Nano | Vim | Description |
| :-------- | :--: | :-: | :---------- |
| Open a New File | ` ` | `:sp` or `:vsp` | `v` to split the window vertically |
| List Open Files | ` ` | `:ls` |  |
| Close a Buffer | ` ` | `:bd` or `:clo[se]` | A _buffer_ might be a file, terminal, or etc. |
| Switch to next Buffer | ` ` | `:bn` |  |
| Switch to Previous Buffer | ` ` | `:bp` |  |
| Split Window Horizontally | ` ` | `Ctrl + ws` |  |
| Split Window Vertically | ` ` | `Ctrl + wv` |  |
| Switch between Windows | ` ` | `Ctrl + ww` |  |
| Open Terminal | ` ` | `:ter[minal]` |  |
| Close Terminal | ` ` | in terminal `Ctrl + d` |  |
