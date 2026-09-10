# Keyboard Customization

## Key remapping

I have remapped keys for easier typing.

* Holding `CapsLock` sends `Super`/`Mod4` for **i3**.
* Tapping `CapsLock` sends `Escape`.
* Physical `LeftShift` sends `Control_L`.
* Physical `RightShift` remains `Shift_R`.

Relevant physical keyboard layout (`*` marks remapped keys):

```text
[ Esc ]    [F1] [F2] [F3] [F4]     [F5] [F6] [F7] [F8]     [F9] [F10] [F11] [F12]
[ Tab ] [ Q ] [ W ] [ E ] [ R ] [ T ] [ Y ] [ U ] [ I ] [ O ] [ P ] [[] []] [ \ ]
[ Super|Esc* ] [ A ] [ S ] [ D ] [ F ] [ G ] [ H ] [ J ] [ K ] [ L ] [ ;* ] [ ' ]
[  Ctrl*  ] [ Z ] [ X ] [ C ] [ V ] [ B ] [ N ] [ M ] [ , ] [ . ] [ / ] [ Shift ]
[ Ctrl ] [ Super ] [ Alt ] [                Space              ] [ Alt ] [ Ctrl ]
```

These are important keys:
* `;` as leader key in nvim.

## Commands for Apps

### Terminal Copy/Paste

| Cmd | Remapped Cmd | Action |
|-|-|-|
| `Ctrl+Shift+C` | `LeftShift+RightShift+C` | copy from terminal applications |
| `Ctrl+Shift+V` | `LeftShift+RightShift+V` | paste into terminal applications |

### Alacritty

| Cmd | Remapped Cmd | Action |
|-|-|-|
| `Ctrl+Shift+Space` | `LeftShift+RightShift+Space` | toggle vi mode |

In vi mode:

| Cmd | Action |
|-|-|
| `v`                | start a selection                      |
| `y`                | end & copy the selection               |
| `h/j/k/l`          | for navigation                         |

### Neovim

> Note: `Ctrl+` combos use the remapped physical Left Shift (e.g. `LeftShift+w`), while `;`-prefixed commands are Neovim's leader-key mappings and are internal to Neovim — no key remap applies.

| Cmd | Action |
|-|-|
| `gx`               | open a link in browser                 |
| `;e`               | highlight opened file in neotree       |
| `;bn`              | go to next open tab                    |
| `;bp`              | go to previous open tab                |
| `;bd`              | close tab                              |
| `gd`               | go to definition                       |
| `K`                | view object details in floating window |
| `;d`               | view error details in floating window  |
| `q`                | close floating window                  |
| `;xx`              | diagnostics (workspace)                |
| `;xX`              | diagnostics (buffer only)              |
| `;xr`              | find all usages (LSP references)       |
| `;xs`              | list symbols (functions, classes)      |
| `Ctrl+w h/j/k/l`   | move to left/down/up/right window      |
| `Ctrl+w p`         | move to previous window                |
| `Ctrl+w w`         | move to next window                    |

### Brave

| Cmd | Remapped Cmd | Action |
|-|-|-|
| `Ctrl+Shift+u` | `LeftShift+RightShift+u` | open bitwarden extension |
| `Ctrl+Shift+n` | `LeftShift+RightShift+n` | open private window |

