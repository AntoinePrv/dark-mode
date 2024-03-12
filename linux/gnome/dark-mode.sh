#!/usr/bin/env bash

readonly setting_name=("org.gnome.desktop.interface" "color-scheme")

function dark_mode_get() {
	case "$(gsettings get "${setting_name[@]}")" in
		*default*)
			echo "light";;
		*light*)
			echo "light";;
		*dark*)
			echo "dark";;
	esac
}

function dark_mode_dark() {
	gsettings set "${setting_name[@]}" "prefer-dark"
}

function dark_mode_light() {
	gsettings set "${setting_name[@]}" "prefer-light"
}

function dark_mode_toogle() {
	case "$(dark_mode_get)" in
		*dark*)
			dark_mode_light;;
		*light*)
			dark_mode_dark;;
	esac
}

function dark_mode_listen() {
	# Execute a first time to set the theme
	"$@" "$(dark_mode_get)"
	gsettings monitor "${setting_name[@]}" | while read line; do
			case "${line}" in
				*dark*)
					"$@" "dark";;
				*light* | *default*)
					"$@" "light";;
			esac
		done
}

function dark_mode_base16_set() {
	case "${1}" in
		*dark*)
			bash "${root}/scripts/base16-${dark}.sh";;
		*light*)
			bash "${root}/scripts/base16-${light}.sh";;
	esac
}


function dark_mode_base16() {
	local args=()
	local root="${BASE16_DIR:-}"
	local light="${BASE16_LIGHT_THEME:-one-light}"
	local dark="${BASE16_DARK_THEME:-onedark}"
	while [[ $# -gt 0 ]]; do
		case "${1}" in
			--root)
				root="${2}"
				shift 2;;
			--light)
				light="${2}"
				shift 2;;
			--dark)
				dark="${2}"
				shift 2;;
			*)
				args+=("${1}")
				shift;;
		esac
	done
	dark_mode_listen dark_mode_base16_set
}

function dark_mode_main() {
	local -r args=("$@")
	"dark_mode_${1}" "${args[@]:1}"
}

# Run the main when script is not being sourced
if [[ "${BASH_SOURCE[0]}" = "${0}" ]] ; then

	# Fail fast
	set -o errexit
	set -o pipefail
	set -o nounset

	dark_mode_main "$@"

fi
