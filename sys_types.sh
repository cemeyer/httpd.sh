declare -r off_t="long"
declare -r size_t="ulong"
declare -r socklen_t="uint32"
declare -r ssize_t="long"

if [ "$PLATFORM" = "Linux" ]; then
    declare -r mode_t="uint32"
elif [ "$PLATFORM" = "FreeBSD" ]; then
    declare -r mode_t="uint16"
fi
