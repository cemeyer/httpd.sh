function memchr() {
    dlcall -g -r pointer memchr $2 int:$3 $size_t:$4
    eval $1=\$DLRETVAL
}

function memcpy() {
    dlcall -g memcpy $1 "$2" $size_t:$3
}

function memset() {
    dlcall -g memset $1 int:$2 $size_t:$3
}

function strncmp() {
    dlcall -g -r int strncmp "$2" "$3" $size_t:$4
    eval $1=\$DLRETVAL
}

function strlen() {
    dlcall -g -r $size_t strlen "$2"
    eval $1=\$DLRETVAL
}
