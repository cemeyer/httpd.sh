httpd.sh
========

This is a dumb web server in bash, using the ctypes.sh plugin to access C APIs.
It uses a single-threaded event loop model.  It can serve small files.  It does
limited error-checking and should not be used in the wild.
