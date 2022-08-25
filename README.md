# Dark Mode
MacOS and Linux scripts to interact with dark mode.

## Features
 - Get current mode
 - Change active mode
 - Listen for theme events and run a shell script on change
 - Listen for theme events and change between
   [chriskempson/base16-shell](https://github.com/chriskempson/base16-shell) themes

## Installation
### MacOS
#### Manual
Either run it directly with
```sh
./macos/dark-mode.swift <command>
```
Or compile it with
```sh
swiftc -o dark-mode ./macos/dark-mode.swift
```

#### With [Zinit](https://github.com/zdharma/zinit)
```zsh
zinit ice lucid from='gh' if='[[ "$(uname -s)" == Darwin* ]]' \
	atclone='swiftc -o dark-mode macos/dark-mode.swift' atpull="%atclone" sbin='dark-mode'
zinit light @AntoinePrv/dark-mode
```

### Linux (Gnome)
#### Manual
The script is a standalone bash wrapper around `gsettings`.
```sh
./linux/gnome/dark-mode.sh
```

#### With [Zinit](https://github.com/zdharma/zinit)
```zsh
zinit ice lucid from='gh' if='[[ "$(uname -s)" == Linux* ]]' \
	sbin='linux/gnome/dark-mode.sh -> dark-mode'
zinit light @AntoinePrv/dark-mode
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
Set theme to light

dark-mode toogle
Toogle the theme to the opposite one.

dark-mode listen <script> [<args>...]
Listen for theme changes and run the given script.
The new theme, either "dark" or "light" is passed as the last argument to the script.

dark-mode base16 --root <base16-root> --light <light-theme> --dark <dark-theme>
Listen for theme changes and change to the base16 theme accordingly
```

## Example using listen to change terminal theme
Using [chriskempson/base16-shell](https://github.com/chriskempson/base16-shell) to change the
terminal theme, one can use something like
```sh
dark-mode base16 --root "${HOME}/.local/share/base16" --light "ia-light" --dark "ia-dark"
```
To run the `dark-mode` listener in the background, for instance starting it in `.bashrc`/`.zshrc`,
you can use
```bash
# Only run if using MacOS.
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Don't run withing Tmux or SSH, as it will already be running in the first terminal session.
    if [["${TERM}" != "screen"* &&  ! -n "${TMUX}" ]] && ! [[ -n "${SSH_CLIENT}" || -n "${SSH_TTY}" ]]; then
        (
            # Run dark-mode in the background, removing it from the job list.
            dark-mode base16 --root "${XDG_DATA_HOME}/base16" --light "one-light" --dark "onedark" &
            # Kill dark-mode when the shell exits.
            bash -c "while ps -p $$ 2>&1 1>/dev/null; do sleep 60; done; pkill -P $!" &
        )
    fi
fi

```

## Credit
Heavily inspired by:
 - [sindresorhus/dark-mode](https://github.com/sindresorhus/dark-mode) for changing the active mode
 - [bouk/dark-mode-notify](https://github.com/bouk/dark-mode-notify) for listening to events
 - [Fatih Arslan](https://arslan.io/2021/02/15/automatic-dark-mode-for-terminal-applications/) for inspiration
