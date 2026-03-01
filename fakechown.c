#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stddef.h>

/* Fake chown/chmod on /dev/pts/* so dropbear can set up PTYs in PRoot.
   Also fake SO_PEERCRED so tmux client/server uid check passes despite
   PRoot faking getuid() differently from the real kernel uid.
   Also fix tmux socket permissions: PRoot ignores umask for AF_UNIX sockets,
   producing mode 0660 instead of 0600; chmod to 0600 after bind(). */

static int path_is_pts(const char *path) {
    return path && strncmp(path, "/dev/pts/", 9) == 0;
}

int chown(const char *path, uid_t uid, gid_t gid) {
    if (path_is_pts(path)) return 0;
    static int (*real)(const char *, uid_t, gid_t) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "chown");
    return real(path, uid, gid);
}

int fchown(int fd, uid_t uid, gid_t gid) {
    static int (*real)(int, uid_t, gid_t) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "fchown");
    int r = real(fd, uid, gid);
    return (r < 0) ? 0 : r;
}

int chmod(const char *path, mode_t mode) {
    if (path_is_pts(path)) return 0;
    static int (*real)(const char *, mode_t) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "chmod");
    return real(path, mode);
}

int bind(int fd, const struct sockaddr *addr, socklen_t addrlen) {
    static int (*real)(int, const struct sockaddr *, socklen_t) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "bind");
    int r = real(fd, addr, addrlen);
    if (r == 0 && addr && addr->sa_family == AF_UNIX) {
        const struct sockaddr_un *un = (const struct sockaddr_un *)addr;
        /* Fix tmux socket permissions: PRoot ignores umask for AF_UNIX sockets */
        if (un->sun_path[0] && strncmp(un->sun_path, "/tmp/tmux-", 10) == 0) {
            static int (*real_chmod)(const char *, mode_t) = NULL;
            if (!real_chmod) real_chmod = dlsym(RTLD_NEXT, "chmod");
            real_chmod(un->sun_path, 0600);
        }
    }
    return r;
}

int getsockopt(int fd, int level, int optname, void *optval, socklen_t *optlen) {
    static int (*real)(int, int, int, void *, socklen_t *) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "getsockopt");
    int r = real(fd, level, optname, optval, optlen);
    if (r == 0 && level == SOL_SOCKET && optname == SO_PEERCRED && optval) {
        struct ucred *cred = (struct ucred *)optval;
        cred->uid = getuid();
        cred->gid = getgid();
    }
    return r;
}
