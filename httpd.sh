#!/bin/bash

source ctypes.sh

set -o errexit
set -o nounset

source platform.sh

source sys_types.sh
source sys_select.sh
source sys_sendfile.sh
source sys_socket.sh
source sys_stat.sh

source err.sh
source fcntl.sh
source netdb.sh
source stdlib.sh
source string.sh
source sysexits.sh
source unistd.sh

DFLT_BUFSZ=8192

RESP400=$'HTTP/1.0 400 Bad Request\r\n\r\n<html><body><h1>400 Bad Request</h1></body></html>'
RESP404=$'HTTP/1.0 404 File Not Found\r\n\r\n<html><body><h1>404 File Not Found</h1></body></html>'
RESP200=$'HTTP/1.0 200 OK\r\nContent-type'
RESP200A=$' text/plain\r\n\r\n'
RESP400LEN=$( echo -ne "$RESP400" | wc -c )
RESP404LEN=$( echo -ne "$RESP404" | wc -c )
RESP200LEN=$( echo -ne "$RESP200" | wc -c )
RESP200ALEN=$( echo -ne "$RESP200A" | wc -c )

function http::respond_bogus() {
    local -i fd=$1
    local wr
    local rc

    send wr $fd "$RESP400" $RESP400LEN 0
    # XXX ignore wr

    shutdown rc $fd $SHUT_RDWR
    # XXX ignore rc
}

function http::respond_file_not_found() {
    local -i fd=$1
    local wr
    local rc

    send wr $fd "$RESP404" $RESP404LEN 0
    # XXX ignore wr

    shutdown rc $fd $SHUT_RDWR
    # XXX ignore rc
}

function http::respond_file() {
    local -i fd=$1
    local file=${2##*:}
    local wr
    local sb
    local rc
    local fl
    local readfd

    local -a stunp

    file=$(printf "%#x" $((file + 1)))

    sb=$NULL
    malloc sb $SIZEOF_STAT
    if [ $sb = $NULL ]; then
        err $EX_OSERR malloc
    fi

    fl=0
    strlen fl pointer:$file

    if [ ${fl##*:} -eq 0 ]; then
        stat rc "." $sb
    else
        stat rc pointer:$file $sb
    fi
    if [ ${rc##*:} -lt 0 ]; then
        warn "stat"
        http::respond_file_not_found $fd
        free $sb
        return
    fi

    stunp=( "${stat[@]}" )
    unpack $sb stunp

    if S_ISREG ${stunp[st_mode]}; then
        open readfd pointer:$file $O_RDONLY
        readfd=${readfd##*:}
        if [ $readfd -lt 0 ]; then
            warn "open '%s'" pointer:$file
            http::respond_bogus $fd
            free $sb
            return
        fi

        send wr $fd "$RESP200" $RESP200LEN 0
        # XXX ignore wr
        send wr $fd "string::" 1 0
        # XXX ignore wr
        send wr $fd "$RESP200A" $RESP200ALEN 0
        # XXX ignore wr

        if [ "$PLATFORM" = "Linux" ]; then
            linux_sendfile rc $fd $readfd $NULL ${stunp[st_size]##*:}
            # XXX ignore rc
        elif [ "$PLATFORM" = "FreeBSD" ]; then
            errx $EX_OSERR "todo"
        fi
        close rc $readfd
        # XXX ignore rc
    else
        dlcall -g printf $'(404) \'%s\' is not a file\n' pointer:$file
        http::respond_file_not_found $fd
        free $sb
        return
    fi

    free $sb

    shutdown rc $fd $SHUT_RDWR
    # XXX ignore rc
}

function http::parse_and_respond() {
    local -i fd=$1
    local buf=$2
    local buflen=$3

    local rc
    local sp
    local path
    local pathlen

    if [ $buflen -lt 15 ]; then
        return
    fi

    strncmp rc pointer:$buf "GET " 4
    if [ $rc != int:0 ]; then
        http::respond_bogus $fd
        return
    fi

    buf=$(printf "%#x" $((buf + 4)))
    buflen=$((buflen-4))

    memchr sp pointer:$buf 32 $buflen
    if [ $rc = $NULL ]; then
        # Incomplete (or bogus) request; let more input accrue
        return
    fi
    sp=${sp##*:}

    path=$NULL
    pathlen=$((sp - buf))
    malloc path $((pathlen + 1))
    if [ $path = $NULL ]; then
        err $EX_OSERR malloc
    fi

    memset $path 0 $((pathlen + 1))
    memcpy $path pointer:$buf $pathlen

    #dlcall -g printf $'Got request for \'%s\'\n' $path
    http::respond_file $fd $path

    free $path
}

function connection::new() {
    local -n conns=$1
    local -i fd=$2
    local buf

    #echo "XXX Got conn $fd"

    buf=$NULL
    malloc buf $DFLT_BUFSZ
    if [ $buf = $NULL ]; then
        err $EX_OSERR "malloc"
    fi

    conns[$fd,fd]=$fd
    conns[$fd,buf]=$buf
    conns[$fd,buf_pos]=0
    conns[$fd,buf_len]=$DFLT_BUFSZ
}

function connection::more() {
    local -n conns=$1
    local -i fd=$2
    local -i room
    local rd
    local buf

    #echo "More on $fd"

    room=$((conns[$fd,buf_len] - conns[$fd,buf_pos]))
    buf=${conns[$fd,buf]##*:}
    rdpos=$(printf "%#x" $((buf + conns[$fd,buf_pos])))

    if [ $room -eq 0 ]; then
        echo "XXX dropping overlarge request on $fd"
        connection::close conns $fd
        return
    fi

    rd=0
    recv rd $fd pointer:$rdpos $room 0
    rd=${rd##*:}
    if [ $rd -lt 0 ]; then
        echo "XXX error on $fd, closing"
        connection::close conns $fd
        return
    elif [ $rd -eq 0 ]; then
        #echo "EOF on $fd, closing"
        connection::close conns $fd
        return
    fi

    conns[$fd,buf_pos]=$((conns[$fd,buf_pos] + rd))
    http::parse_and_respond $fd $buf ${conns[$fd,buf_pos]}
}

function connection::close() {
    local -n c_conns=$1
    local -i fd=$2
    local rc

    free c_conns[$fd,buf]
    close rc $fd
    # XXX ignored rc

    unset c_conns[$fd,fd]
    unset c_conns[$fd,buf]
    unset c_conns[$fd,buf_pos]
    unset c_conns[$fd,buf_len]
}

function main_loop() {
    local lfd=$1
    local fds_rd
    local key
    local rc
    local cfd

    local -a fds_unpacked

    local -A connections

    fds_rd=$NULL
    malloc fds_rd $SIZEOF_FD_SET
    if [ $fds_rd = $NULL ]; then
        err $EX_OSERR malloc
    fi

    fds_unpacked=( "${fd_set[@]}" )

    while true; do
        memset $fds_rd 0 $SIZEOF_FD_SET
        unpack $fds_rd fds_unpacked

        #echo "XXX selecting $lfd"
        FD_SET fds_unpacked $lfd

        for key in "${!connections[@]}"; do
            case "$key" in *,fd)
                #echo "XXX selecting ${connections[$key]}"
                FD_SET fds_unpacked "${connections[$key]}"
            esac
        done

        pack $fds_rd fds_unpacked
        so_select rc int:$FD_SETSIZE $fds_rd $NULL $NULL $NULL
        if [ ${rc##*:} -lt 0 ]; then
            err $EX_OSERR "select"
        fi

        unpack $fds_rd fds_unpacked
        if FD_ISSET fds_unpacked $lfd; then
            accept rc $lfd $NULL $NULL
            if [ ${rc##*:} -lt 0 ]; then
                err $EX_OSERR "accept"
            fi

            connection::new connections ${rc##*:}
        fi

        for key in "${!connections[@]}"; do
            case "$key" in *,fd)
                cfd=${connections[$key]}
                if FD_ISSET fds_unpacked $cfd; then
                    connection::more connections $cfd
                fi
            esac
        done
    done
}

function select_ai() {
    local ai
    local -a ai_s

    ai=$2

    while [ $ai != $NULL ]; do
        ai_s=( "${addrinfo[@]}" )

        unpack $ai ai_s
        if [ "${ai_s[ai_family]}" = int:$AF_INET ]; then
            eval $1=\$ai
            return
        fi

        ai=${ai_s[ai_next]}
    done

    errx $EX_OSERR "No AF_INET addrinfo"
}

function bind_port() {
    local -a a_one
    local -a bind_addr_info
    local -a a_ai_hints

    local lfd
    local rc
    local onp
    local addr_info
    local ai_hints

    rc=0
    a_one=( int:1 )

    a_ai_hints=( "${addrinfo[@]}" )
    malloc ai_hints $SIZEOF_ADDRINFO
    if [ $ai_hints = $NULL ]; then
        err $EX_OSERR "malloc"
    fi
    memset $ai_hints 0 $SIZEOF_ADDRINFO
    unpack $ai_hints a_ai_hints

    a_ai_hints[ai_flags]=int:$AI_PASSIVE
    a_ai_hints[ai_family]=int:$AF_INET
    a_ai_hints[ai_socktype]=int:$SOCK_STREAM
    pack $ai_hints a_ai_hints

    getaddrinfo rc $NULL "string:$2" $ai_hints addr_info
    if [ ${rc##*:} -ne 0 ]; then
        local serr
        gai_strerror serr $rc
        err $EX_OSERR "getaddrinfo: %s(%d)" $serr $rc
    fi

    free $ai_hints

    bind_addr_info=( "${addrinfo[@]}" )
    select_ai ai_hints $addr_info
    unpack $ai_hints bind_addr_info

    socket lfd ${bind_addr_info[ai_family]##*:} ${bind_addr_info[ai_socktype]##*:} ${bind_addr_info[ai_protocol]##*:}
    lfd=${lfd##*:}
    if [ $lfd -lt 0 ]; then
        err $EX_OSERR "socket(2) $lfd"
    fi

    malloc onp $SIZEOF_INT
    if [ $onp = $NULL ]; then
        err $EX_OSERR "malloc"
    fi
    pack $onp a_one

    setsockopt rc $lfd $SOL_SOCKET $SO_REUSEADDR $onp $SIZEOF_INT
    if [ ${rc##*:} -lt 0 ]; then
        err $EX_OSERR "setsockopt"
    fi

    free $onp

    so_bind rc $lfd ${bind_addr_info[ai_addr]} ${bind_addr_info[ai_addrlen]##*:}
    if [ ${rc##*:} -lt 0 ]; then
        err $EX_OSERR "bind"
    fi

    listen rc $lfd 16
    if [ ${rc##*:} -lt 0 ]; then
        err $EX_OSERR "listen"
    fi

    echo "$0: Listening on :$2..."

    freeaddrinfo $addr_info

    eval $1=\$lfd
}

function main() {
    local port
    local main_lfd

    port=80
    if [ $# -gt 0 ]; then
        port="$1"
    fi

    main_lfd=0
    bind_port main_lfd $port

    main_loop $main_lfd
    exit 0
}

main "$@"
