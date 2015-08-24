declare -ri AF_INET=2
declare -ri AF_UNSPEC=0

declare -ri SOCK_STREAM=1

declare -ri SHUT_RD=0
declare -ri SHUT_WR=1
declare -ri SHUT_RDWR=2

if [ "$PLATFORM" = FreeBSD ]; then
    declare -ri SOL_SOCKET=0xffff
    declare -ri SO_REUSEADDR=4

    declare -ri SOCK_NONBLOCK=0x20000000
elif [ "$PLATFORM" = Linux ]; then
    declare -ri SOL_SOCKET=1
    declare -ri SO_REUSEADDR=2

    declare -ri SOCK_NONBLOCK=0x800
fi

function accept() {
    dlcall -r int accept int:$2 $3 $4
    eval $1=\$DLRETVAL
}

function listen() {
    dlcall -r int listen int:$2 int:$3
    eval $1=\$DLRETVAL
}

function recv() {
    dlcall -r $ssize_t recv int:$2 $3 $size_t:$4 int:$5
    eval $1=\$DLRETVAL
}

function send() {
    dlcall -r $ssize_t send int:$2 "$3" $size_t:$4 int:$5
    eval $1=\$DLRETVAL
}

function setsockopt() {
    dlcall -r int setsockopt int:$2 int:$3 int:$4 $5 $6
    eval $1=\$DLRETVAL
}

function shutdown() {
    dlcall -r int shutdown int:$2 int:$3
    eval $1=\$DLRETVAL
}

function socket() {
    dlcall -r int socket int:$2 int:$3 int:$4
    eval $1=\$DLRETVAL
}

# Alternative name to work around built-in 'bind'
function so_bind() {
    dlcall -r int bind int:$2 $3 $socklen_t:$4
    eval $1=\$DLRETVAL
}
