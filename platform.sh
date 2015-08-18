declare -r PLATFORM="$(uname -s)"

if [ "$PLATFORM" != FreeBSD -a "$PLATFORM" != Linux ]; then
    echo "Unsupported platform: $PLATFORM"
    exit 1
fi

# XXX
declare -r SIZEOF_INT=4
declare -r SIZEOF_PTR=8
