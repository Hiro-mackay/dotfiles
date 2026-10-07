# log_window <log file>: pass stdin through until "Activating configuration", then show
# the rest in a few lines that scroll in place, like docker build, and erase them at the
# end. Warnings and errors stay on screen above them. Everything also goes to the log
# file. Off a terminal it only passes through.
log_window() {
    local log=$1 rows=8 shown=0 active=0 line plain width
    local -a tail=()
    : >"$log"
    if [ ! -t 1 ]; then
        tee -a "$log"
        return
    fi
    width=$(($(tput cols 2>/dev/null || echo 80) - 4))
    shopt -s extglob
    while IFS= read -r line || [ -n "$line" ]; do
        printf '%s\n' "$line" >>"$log"
        if [ "$active" = 0 ]; then
            printf '%s\n' "$line"
            case "$line" in *"Activating configuration"*) active=1 ;; esac
            continue
        fi
        plain=${line//$'\e'\[*([0-9;])[A-Za-z]/}
        plain=${plain//$'\r'/}
        case "$plain" in *[Ww]arning* | *[Ee]rror*)
            # Above the window: clear it, print the line, and let it redraw below.
            [ "$shown" = 0 ] || printf '\e[%dA\e[J' "$shown"
            printf '%s\n' "$plain"
            shown=0
            ;;
        esac
        tail+=("${plain:0:width}")
        [ "${#tail[@]}" -le "$rows" ] || tail=("${tail[@]:1}")
        [ "$shown" = 0 ] || printf '\e[%dA' "$shown"
        for plain in "${tail[@]}"; do printf '\e[2K  \e[2m%s\e[0m\n' "$plain"; done
        shown=${#tail[@]}
    done
    if [ "$shown" != 0 ]; then
        printf '\e[%dA' "$shown"
        for ((line = 0; line < shown; line++)); do printf '\e[2K\n'; done
        printf '\e[%dA' "$shown"
    fi
}
