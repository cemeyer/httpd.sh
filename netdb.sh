declare -ri AI_PASSIVE=1

declare -a addrinfo
{
    _n=0
    addrinfo[ai_flags    = _n++]=int
    addrinfo[ai_family   = _n++]=int
    addrinfo[ai_socktype = _n++]=int
    addrinfo[ai_protocol = _n++]=int
    addrinfo[ai_addrlen  = _n++]=$socklen_t

    if [ $SIZEOF_PTR -gt 4 -a $socklen_t = uint32 ]; then
        addrinfo[_ai_padding  = _n++]=uint32   # padding
    fi

    if [ "$PLATFORM" = FreeBSD ]; then
        addrinfo[ai_canonname = _n++]=pointer
        addrinfo[ai_addr      = _n++]=pointer
    elif [ "$PLATFORM" = Linux ]; then
        addrinfo[ai_addr      = _n++]=pointer
        addrinfo[ai_canonname = _n++]=pointer
    fi

    addrinfo[ai_next     = _n++]=pointer
}
declare -ri SIZEOF_ADDRINFO=48

function getaddrinfo() {
    local tmp_ptr
    local rc
    local -a ptr_ptr=(pointer)

    dlcall -r pointer malloc $SIZEOF_PTR
    tmp_ptr=$DLRETVAL
    
    dlcall -r int getaddrinfo $2 $3 $4 $tmp_ptr
    rc=$DLRETVAL
    if [ $rc = "int:0" ]; then
        unpack $tmp_ptr ptr_ptr
        eval $5=\$ptr_ptr
    fi

    dlcall free $tmp_ptr
    eval $1=\$rc
}

function freeaddrinfo() {
    dlcall freeaddrinfo "$1"
}

function gai_strerror() {
    dlcall -r pointer gai_strerror "$2"
    eval $1=\$DLRETVAL
}
