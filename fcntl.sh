declare -ri FD_CLOEXEC=1

declare -ri O_RDONLY=0

function open() {
    if [ $# -eq 3 ]; then
        dlcall -g -r int open "$2" int:$3
    else
        dlcall -g -r int open "$2" int:$3 $mode_t:$4
    fi
    eval $1=\$DLRETVAL
}
