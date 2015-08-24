function err() {
    local -i code=$1
    shift
    dlcall err int:$code "$@"
}

function errx() {
    local -i code=$1
    shift
    dlcall errx int:$code "$@"
}

function warn() {
    dlcall warn "$@"
}

function warnx() {
    dlcall warnx "$@"
}
