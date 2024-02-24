# Add your own custom plugins in the custom/plugins directory. Plugins placed
# here will override ones with the same name in the main plugins directory.
# See: https://github.com/ohmyzsh/ohmyzsh/wiki/Customization#overriding-and-adding-plugins

export DOUP_DEBUG="${DOUP_DEBUG:-0}"

function __doup_find_binary() {
    if [[ $# < 1 ]]; then
        print "Usage: find_binary <bin_name>"
        exit -1
    fi
    bin_name=$1
    default_path=${$2:-""}
    bin_path=$(which "${bin_name}" | cut -d' ' -f1)
    if [[ -x "${bin_path}" ]]; then
        echo "${bin_path}"
    elif [[ -x "${default_path}" ]]; then
        echo "${default_path}"
    else
        echo ""
    fi
}

function __doup_section ()
{
    section_name="$1"
    echo $fg_bold[green] doup: beginning section $fg[cyan] ${section_name} $fg[default]
}

function __doup_end_section ()
{
    section_name="$1"
    echo $fg_bold[green] doup: ending section $fg[cyan] ${section_name} $fg[default]
    echo ""
}

function __doup_dbg ()
{
    func_name=$1
    shift
    if [ "${DOUP_DEBUG:-'1'}" = "1" ]
    then
        echo "$fg_bold[green]" $func_name "$fg[default]" $* "$fg[default]"
    fi
}

function __doup_error ()
{
    func_name=$1
    shift
    if [ "${DOUP_DEBUG:-'1'}" = "1" ]
    then
        echo "$fg_bold[red]" $func_name "$fg[default]" $* "$fg[default]"
    fi
}

function __doup_action ()
{
    if [[ $# < 1 ]]
    then
        __doup_error "__doup_action" "Required parameter missing"
        return -1
    fi

    cmd_executable="$1"
    cmd_flagname="doup_skip_${cmd_executable}"
    shift
    cmd_args="$*"
    skip_flag=${(P)cmd_flagname:-'0'}

    __doup_dbg "__doup_action" "Looking for" "$fg[cyan]" $cmd_executable
    cmd_path="$(which $cmd_executable | cut -d' ' -f1)"
    if [ -x "${cmd_path}" ]; then
        __doup_dbg "__doup_action" "Found " "$fg[cyan]" $cmd_executable \
            "$fg[default]" at "$fg[cyan]" $cmd_path
        if [ "${skip_flag}" = '0' ]; then
            __doup_dbg "__doup_action" "$fg[cyan]" $cmd_flagname "$fg[default]" \
                "not set - running command: " \
                $fg[magenta]${cmd_path} "$fg_bold[yellow]" "${cmd_args}"
            "${cmd_path}" $*
            return $?
        else
            __doup_dbg "__doup_action" "$fg[cyan]" ${cmd_flagname} "$fg[default]" \
                "set - skipping command execution"
            return -1
        fi
    else
        __doup_dbg "__doup_action"  "$fg[cyan]" $cmd_executable "$fg[default]" \
            "not found - skipping command execution"
        return -1
    fi
}

function __doup_start_banner()  {
    echo "$fg_bold[magenta]" \
        "******************************************************************************"
    echo "$fg_bold[magenta]" \
        "*****                  DOUP : Performing System Updates                  *****"
    echo "$fg_bold[magenta]" \
        "******************************************************************************$fg[default]"
    echo ""
}

function __doup_end_banner() { 
    echo "$fg_bold[magenta]" \
        "******************************************************************************"
    echo "$fg_bold[magenta]" \
        "*****                  DOUP : System Update Complete.                   *****"
    echo "$fg_bold[magenta]" \
        "******************************************************************************$fg[default]"
}
function doup() {
    __doup_start_banner

    __doup_section "homebrew"
    if [ -d "/opt/homebrew" -o -d "/usr/local/homebrew" ]; then
        brew update && brew upgrade
    elif [ -d "/opt/linuxbrew" -o -d "/usr/local/linuxbrew" ]; then
        linuxbrew update && linuxbrew upgrade
    fi
    __doup_end_section "homebrew"

    __doup_section "python"
    __doup_action pip3 install --upgrade pip setuptools wheel pipenv poetry
    __doup_action pip-review -a
    __doup_action pip3 cache purge

    if [ -d "${HOME}/.pyenv" -a -d "${HOME}/.pyenv/plugins/pyenv-update" ]; then
        pyenv update
    fi

    __doup_end_section "python"
    
    __doup_section "ruby"
    __doup_action gem install rubygems-update
    __doup_action update_rubygems
    __doup_action gem update --system
    __doup_action gem update
    __doup_end_section "ruby"

    # Update node.js tools
    __doup_section "node.js"
    __doup_action npm -g update
    __doup_end_section "node.js"

    # Update Rust tools
    __doup_section "rust"
    __doup_action rustup self update 
    __doup_action rustup update 
    __doup_end_section "rust"

    # Update Haskell tools
    __doup_section "haskell"
    __doup_action ghcup upgrade
    __doup_end_section "haskell"

    # Update NeoVim tools
    __doup_section "neovim"
    __doup_action nvim -c "MasonUpdate" -c "qall"
    __doup_end_section "neovim"

    __doup_section "emacs"
    __doup_action doom upgrade
    __doup_action doom purge
    __doup_end_section "emacs"

    __doup_end_banner
}

