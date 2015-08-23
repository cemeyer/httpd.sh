if [ "$PLATFORM" = "Linux" ]; then
    function linux_sendfile() {
        dlcall -r $ssize_t sendfile int:$2 int:$3 $4 $size_t:$5
        eval $1=\$DLRETVAL
    }
elif [ "$PLATFORM" = "FreeBSD" ]; then
    function freebsd_sendfile() {
        dlcall -r int sendfile int:$2 int:$3 $off_t:$4 $size_t:$5 $6 $7 int:$8
        eval $1=\$DLRETVAL
    }
fi
