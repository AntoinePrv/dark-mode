# Dark Mode
MacOS script to interact with dark mode.

## Features
 - Get current mode
 - Change active mode
 - Listen for theme events and run hook change

## Installation
Either run it directly with
```sh
./dark-mode.swift <command>
```
Or compile it with
```sh
swiftc -o dark-mode dark-mode.swift
```

## Usage
```help
Usage:
dark-mode (help | --help | -h)
Print this message and exit.

dark-mode get
Print the current mode, either "dark" or "light".

dark-mode dark
Set theme to dark.

dark-mode light
Set theme to ligth.

dark-mode toogle
Toogle the theme to the opposite one.

dark-mode listen <script> [<args>...]
Listen for theme changes and run the given script.
The new theme, either "dark" or "light" is passed as the last argument to the script.
```

## Using listen to change terminal theme
Using [chriskempson/base16-shell](https://github.com/chriskempson/base16-shell) to change the terminal theme,
one can write a script `set-theme.sh`:
```sh
if [[ "${1}" == "dark" ]]; then
	bash path/to/base16/scripts/base16-theme-dark.sh
elif [[ "${1}" == "light" ]]; then
	bash path/to/base16/scripts/base16-theme-light.sh
fi
```
And run it with `dark-mode listen bash hook.sh`

## Credit
Heavily inspired by:
 - [sindresorhus/dark-mode](https://github.com/sindresorhus/dark-mode) for changing the active mode
 - [bouk/dark-mode-notify](https://github.com/bouk/dark-mode-notify) for listening to events
 - [Fatih Arslan](https://arslan.io/2021/02/15/automatic-dark-mode-for-terminal-applications/) for inspiration
