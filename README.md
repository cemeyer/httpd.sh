httpd.sh
========

Httpd.sh is a dumb web server written in Bash.  It uses the
[ctypes.sh plugin](https://github.com/taviso/ctypes.sh/) to access C socket
and file APIs.  It uses a single-threaded event loop model.  It can serve
small files.  It does limited error-checking and should not be used in the
wild.

Usage
=====

```bash
$ cd /var/www
$ bash path/to/httpd.sh 8888
httpd.sh: Listening on :8888...

```

Httpd.sh serves files accessible from the directory it was started in.  Note
that it is trivial to escape the document root unless you run it in a jail or
chroot.

Platforms
=========

Httpd.sh runs on Linux and FreeBSD using mostly POSIX-standard C APIs (sendfile
excepted).  It may work on other Unix / near-POSIX platforms with little
adaptation.
