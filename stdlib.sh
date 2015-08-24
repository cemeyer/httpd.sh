function malloc(){
    dlcall -r pointer malloc $size_t:$2
    eval $1=\$DLRETVAL
}

function free(){
    dlcall free $1
}
