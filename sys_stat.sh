declare -ri S_IFREG=0x8000

declare -a stat
{
    _n=0
    if [ "$PLATFORM" = "Linux" ]; then
        stat[st_dev     = _n++]="long"
        stat[st_ino     = _n++]="long"
        stat[st_nlink   = _n++]="long"
        stat[st_mode    = _n++]="int"
        stat[st_uid     = _n++]="int"
        stat[st_gid     = _n++]="int"
        stat[             _n++]="int"    # Padding
        stat[st_rdev    = _n++]="long"
        stat[st_size    = _n++]="long"
        stat[st_blksize = _n++]="long"
        stat[st_blocks  = _n++]="long"

        stat[st_atim_sec= _n++]="long"
        stat[st_atim_ns = _n++]="long"
        stat[st_mtim_sec= _n++]="long"
        stat[st_mtim_ns = _n++]="long"
        stat[st_ctim_sec= _n++]="long"
        stat[st_ctim_ns = _n++]="long"
    elif [ "$PLATFORM" = "FreeBSD" ]; then
        stat[st_dev     = _n++]="uint32"
        stat[st_ino     = _n++]="uint32"
        stat[st_mode    = _n++]="uint16"
        stat[st_nlink   = _n++]="uint16"
        stat[st_uid     = _n++]="uint32"
        stat[st_gid     = _n++]="uint32"
        stat[st_rdev    = _n++]="uint32"

        stat[st_atim_sec= _n++]="int64"
        stat[st_atim_ns = _n++]="long"
        # Assuming long is 64-bit, no padding.
        stat[st_mtim_sec= _n++]="int64"
        stat[st_mtim_ns = _n++]="long"
        stat[st_ctim_sec= _n++]="int64"
        stat[st_ctim_ns = _n++]="long"

        stat[st_size    = _n++]="int64"
        stat[st_blocks  = _n++]="int64"
        stat[st_blksize = _n++]="int32"
    fi
}

if [ "$PLATFORM" = "Linux" ]; then
    #declare -ri SIZEOF_STAT=120
    # The documented API only consumes 120 bytes, but xstat must write more --
    # I get heap corruption on free unless this is bumped up higher:
    declare -ri SIZEOF_STAT=512
elif [ "$PLATFORM" = "FreeBSD" ]; then
    declare -ri SIZEOF_STAT=92
fi

function S_ISREG() {
    local -i mode=${1##*:}

    if (((mode & S_IFREG) != 0)); then
        return 0
    fi
    return 1
}

function fstat() {
    dlcall -g -r int fstat int:$2 $3
    eval $1=\$DLRETVAL
}

function lstat() {
    dlcall -g -r int lstat $2 $3
    eval $1=\$DLRETVAL
}

function stat() {
    if [ "$PLATFORM" = "Linux" ]; then
        dlcall -g -r int __xstat 0 $2 $3
    elif [ "$PLATFORM" = "FreeBSD" ]; then
        dlcall -g -r int stat $2 $3
    fi
    eval $1=\$DLRETVAL
}
