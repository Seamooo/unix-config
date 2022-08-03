#!/bin/bash
# shellcheck disable=SC2034
set -e

# This script is meant as an easy setup for a new device such that it has
# neovim, sublime text, and 

SCRIPT_NAME="setup.sh"
WORKDIR_PATH="/tmp/seamooo/unix-config/cache"
REPO_NAME="unix-config"
REPO_URL="https://github.com/Seamooo/$REPO_NAME"
REPO_PATH="${WORKDIR_PATH}/${REPO_NAME}"

fatal_err() {
	echo "${SCRIPT_NAME}: $1" >&2
	exit "$2"
}

setup_err() {
	fatal_err "$*" 1
}

cli_err() {
    fatal_err "$*" 2
}

script_err() {
	fatal_err "script error - $*" 255
}

log_stderr() {
	echo "$*" >&2
}

usage() {
    cat -e << EOF
Usage: $SCRIPT_NAME [OPTIONS]
performs setup for a fresh debian install
      --headless             excludes desktop-reliant packages from setup
  -h, --help                 displays this message
EOF
    exit "$1"
}


is_set() {
    [ -n "${!1+x}" ]
}

check_root() {
	if [ "$EUID" -ne 0 ]; then
		setup_err "script must be run as root. Try sudo !!"
	fi
}

req_arg() {
    [ -z "$OPTARG" ] && cli_err "arg missing for --$OPT option"
}

parse_args() {
	# prevent eevironment polluting flags
	unset HEADLESS
	# parsing getopts from https://stackoverflow.com/a/28466267/519360
	while getopts cghs-: OPT; do
		if [ "$OPT" = "-" ]; then
			# required argument opt expects format --opt=val
			OPT="${OPTARG%%=*}"
			OPTARG="${OPTARG#"$OPT"}"
			OPTARG="${OPTARG#=}"
		fi
		case "$OPT" in
			headless)
				HEADLESS=0
				;;
			h | help)
				usage 0
				;;
			??*)
				cli_err "illegal option --$OPT"
				;;
			?)
				script_err "unreachable statement reached"
				;;
		esac
	done
}

add_vscode_pkg_internal() {
	# WARNING any function suffixed with _internal must not be called
	# outside of the function that prefixes it
	CURR_DIR="$1"
	TARGET_DIR="$2"
	[ -e "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"
	mkdir -p "$TARGET_DIR"
	cd "$TARGET_DIR"
	curl -sSLOJ 'https://go.microsoft.com/fwlink/?LinkID=760868'
	apt-get install -y ./*.deb
	cd "$1"
}

add_vscode_pkg() {
	VSCODE_WORKDIR="tmp_vscode"
	# stash current dir
	add_vscode_pkg_internal "$(pwd)" "$VSCODE_WORKDIR"
}

add_subl_ppa() {
	curl -sS https://download.sublimetext.com/sublimehq-pub.gpg \
		| gpg --dearmor > /usr/share/keyrings/sublimehq.gpg
	echo 'deb [signed-by=/usr/share/keyrings/sublimehq.gpg] https://download.sublimetext.com/ apt/stable/' \
		> /etc/apt/sources.list.d/sublime-text.list
}

add_chrome_pkg_internal() {
	# WARNING any function suffixed with _internal must not be called
	# outside of the function that prefixes it
	CURR_DIR="$1"
	TARGET_DIR="$2"
	[ -e "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"
	mkdir -p "$TARGET_DIR"
	cd "$TARGET_DIR"
	curl -sSLOJ 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
	apt-get install -y ./*.deb
	cd "$1"
}

add_chrome_pkg() {
	CHROME_WORKDIR="tmp_chrome"
	# stash current dir
	add_chrome_pkg_internal "$(pwd)" "$CHROME_WORKDIR"
}

add_ppas_headless() {
	add-apt-repository ppa:neovim-ppa/stable
}

add_ppas_desktop() {
	add_subl_ppa
}

install_nvm() {
	# as we can't source .bashrc in a non-interactive environment,
	# eval each line that's expected to be added
	nvm_output=$(curl -sS \
		https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh \
		| bash | tail -n 3)
	IFS=$'\n'
	nvm_eval_lines=("$nvm_output")
	unset IFS
	for line in "${nvm_eval_lines[@]}"; do
		eval "$line"
	done
	nvm install node
}

install_packages_headless() {
	apt-get update && apt-get install -y \
		vim \
		neovim \
		tmux
	install_nvm
}

install_packages_desktop() {
	apt-get update && apt-get install -y \
		sublime-text
	add_vscode_pkg
	add_chrome_pkg
}

install_packages_setup() {
	apt-get update && apt-get install -y \
		curl \
		gpg \
		apt-transport-https \
		software-properties-common \
		git
}

configure_coc() {
	coc_extensions=(
		coc-html
		coc-tsserver
		coc-rls
		coc-python
		coc-pyright
		coc-markdown
		coc-json
		coc-java
		coc-flutter
		coc-css
		coc-clangd
	)
	log_stderr "Installing coc extensions"
	for extension in "${coc_extensions[@]}"; do
		nvim +"CocInstall $extension" +qa
	done
}

configure_neovim() {
	curl -sSfLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
       "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	mkdir -p "${HOME}/.config/nvim"
	cp -r "$REPO_PATH"/config/nvim/* "${HOME}/.config/nvim/"
	nvim +"PlugInstall" +qa
	configure_coc
}

configure() {
	configure_neovim
}

init() {
	# cleanup any fragments from a previous setup attempt
	[ -e "$WORKDIR_PATH" ] && rm -rf "$WORKDIR_PATH"
	mkdir -p "$WORKDIR_PATH"
	cd "$WORKDIR_PATH"
	log_stderr 'installing setup packages'
	install_packages_setup
	log_stderr cloning repo
	git clone --depth=1 "$REPO_URL"
}

setup_headless() {
	init
	log_stderr 'installing headless packages'
	add_ppas_headless
	install_packages_headless
	log_stderr 'configuring'
	configure
}

setup_desktop() {
	setup_headless
	log_stderr 'installing desktop packages'
	add_ppas_desktop
	install_packages_desktop
}

main() {
	check_root
	parse_args
	if is_set "HEADLESS"; then
		setup_headless
	else
		setup_desktop
	fi
}

main
