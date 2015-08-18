function close() {
    dlcall -g -r int close int:$2
    eval $1=\$DLRETVAL
}
