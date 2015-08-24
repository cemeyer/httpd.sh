function close() {
    dlcall -r int close int:$2
    eval $1=\$DLRETVAL
}
