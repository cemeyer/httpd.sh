declare -ri AF_INET=2
declare -ri AF_UNSPEC=0

declare -ri SOCK_STREAM=1

declare -ri SHUT_RD=0
declare -ri SHUT_WR=1
declare -ri SHUT_RDWR=2

if [ "$PLATFORM" = FreeBSD ]; then
    declare -ri SOL_SOCKET=0xffff
    declare -ri SO_REUSEADDR=4
elif [ "$PLATFORM" = Linux ]; then
    declare -ri SOL_SOCKET=1
    declare -ri SO_REUSEADDR=2
fi

function accept() {
    dlcall -g -r int accept int:$2 $3 $4
    eval $1=\$DLRETVAL
}

function listen() {
    dlcall -g -r int listen int:$2 int:$3
    eval $1=\$DLRETVAL
}

function recv() {
    dlcall -g -r $ssize_t recv int:$2 $3 $size_t:$4 int:$5
    eval $1=\$DLRETVAL
}

function send() {
    dlcall -g -r $ssize_t send int:$2 "$3" $size_t:$4 int:$5
    eval $1=\$DLRETVAL
}

function setsockopt() {
    dlcall -g -r int setsockopt int:$2 int:$3 int:$4 $5 $6
    eval $1=\$DLRETVAL
}

function shutdown() {
    dlcall -g -r int shutdown int:$2 int:$3
    eval $1=\$DLRETVAL
}

function socket() {
    dlcall -g -r int socket int:$2 int:$3 int:$4
    eval $1=\$DLRETVAL
}

# Alternative name to work around built-in 'bind'
function so_bind() {
    dlcall -g -r int bind int:$2 $3 $socklen_t:$4
    eval $1=\$DLRETVAL
}
