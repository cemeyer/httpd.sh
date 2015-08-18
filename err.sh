function err() {
    local -i code=$1
    shift
    dlcall -g err int:$code "$@"
}

function errx() {
    local -i code=$1
    shift
    dlcall -g errx int:$code "$@"
}

function warn() {
    dlcall -g warn "$@"
}

function warnx() {
    dlcall -g warnx "$@"
}
