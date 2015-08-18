httpd.sh
========

This is a dumb web server in bash, using the ctypes.sh plugin to access C APIs.
It uses a single-threaded event loop model.  It can serve small files.  It does
limited error-checking and should not be used in the wild.

Usage
=====

```bash
$ cd /var/www
$ bash path/to/httpd.sh 8888
httpd.sh: Listening on :8888...

```

(It serves files accessible from the current working directory.  Note that it
is trivial to escape the document root unless you run it in a jail or chroot.)
