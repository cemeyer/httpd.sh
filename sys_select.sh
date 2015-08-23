declare -ri FD_SETSIZE=1024

declare -a fd_set
{
    for ((_n = 0; _n < FD_SETSIZE / 8; _n++)); do
        fd_set[_n]="uint8:0"
    done
}
declare -ri SIZEOF_FD_SET=$((FD_SETSIZE/8))

function FD_CLR() {
    local -n fdset=$1
    local -i index=${2##*:}
    local -i oval=${fdset[index / 8]##*:}
    fdset[index / 8]=uint8:$((oval & ~(1 << (index % 8))))
}

function FD_SET() {
    local -n fdset=$1
    local -i index=${2##*:}
    local -i oval=${fdset[index / 8]##*:}
    fdset[index / 8]=uint8:$((oval | (1 << (index % 8))))
}

function FD_ISSET() {
    local -n fdset=$1
    local -i index=${2##*:}
    local -i oval=${fdset[index / 8]##*:}
    if ((oval & (1 << (index % 8)))); then
        return 0
    fi
    return 1
}

function FD_ZERO() {
    local -n fdset=$1
    local n
    for ((n = 0; n < FD_SETSIZE / 8; n++)); do
        fdset[n]="uint8:0"
    done
}

function so_select() {
    dlcall -r int select $2 $3 $4 $5 $6
    eval $1=\$DLRETVAL
}
