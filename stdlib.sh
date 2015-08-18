function malloc(){
    dlcall -g -r pointer malloc $size_t:$2
    eval $1=\$DLRETVAL
}

function free(){
    dlcall -g free $1
}
