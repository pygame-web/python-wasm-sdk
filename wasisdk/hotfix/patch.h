#include <stdio.h> // for FILE
#include <unistd.h> // for uid_t, pid_t

static FILE *
popen(const char *command, const char *type){
    return NULL;
}

static int
pclose(FILE *stream){
    (void)stream;
    return 0;
}

static gid_t
getegid(void) {
	return 99;
}

static uid_t
geteuid(void) {
    return 1000;
}

#include <sys/types.h> // for mode_t
static mode_t
umask(mode_t mask) {
	return 18;
}



#include <errno.h>  // for E*
#include <sys/stat.h> // for stat
#include <string.h> // for strlen

#include <time.h> // for clock_gettime
static char *
__randname(char *tmpl)
{
	int i;
	struct timespec ts;
	unsigned long r;

	clock_gettime(CLOCK_REALTIME, &ts);
	r = ts.tv_nsec*65537 ^ (uintptr_t)&ts / 16 + (uintptr_t)tmpl;
	for (i=0; i<6; i++, r>>=5)
		tmpl[i] = 'A'+(r&15)+(r&16)*2;

	return tmpl;
}


static char *
mktemp(char *tmpl)
{
	size_t l = strlen(tmpl);
	int retries = 100;
	struct stat st;

	if (l < 6 || memcmp(tmpl+l-6, "XXXXXX", 6)) {
		errno = EINVAL;
		*tmpl = 0;
		return tmpl;
	}

	do {
		__randname(tmpl+l-6);
		if (stat(tmpl, &st)) {
			if (errno != ENOENT) *tmpl = 0;
			return tmpl;
		}
	} while (--retries);

	*tmpl = 0;
	errno = EEXIST;
	return tmpl;
}

static int
mkstemp(char *tmpl) {
    FILE *ftemp = fopen(mktemp(tmpl),"w");
    return fileno(ftemp);
}


// errno.h
#define EHOSTDOWN 117		/* Host is down */


// sys/socket.h
#define AF_UNIX 1  // PF_LOCAL



// pwd.h

static int
//getpwuid_r(uid_t uid, struct passwd *pwd, char *buf, size_t buflen, struct passwd **result) {
getpwuid_r(uid_t uid, void *pwd, char *buf, size_t buflen, void **result) {
  return ENOENT;
}


static int
kill(pid_t pid, int sig) {
	puts("nokill");
    return 0;
}


#include <stdlib.h> // for strtol

static pid_t
getppid(void) {
    char *val = getenv("WASIX_PPID");
    char *end = val + strlen(val);
    if (val && val[0] != '\0') {
	return (pid_t)strtol(val, &end, 10);
    }
#ifdef _WASIX_PPID
    return (pid_t)(_WASIX_PPID);
#else
    return 1;
#endif
}






// *********************************************************************************************
// *********************************************************************************************
// *********************************************************************************************
// *********************************************************************************************



#ifndef __wasilibc_use_wasip2
#   define __wasi__p1


#   include <limits.h>
#   include <string.h>
#   include <stdlib.h>
#   include <stdint.h>

#   define P_tmpdir "/tmp"
#   define	LOCK_EX	2
#   define	LOCK_NB	4

    static char *
    tempnam (const char *dir, const char *pfx)
    {
        char buf[FILENAME_MAX];
        int all;
        char *ptr;
        int	dirlen = strlen(dir);
        if (dirlen>=FILENAME_MAX)
        	return NULL;

        memcpy(buf,dir,FILENAME_MAX);
        buf[dirlen] = '/';


        if (pfx) {
            all = dirlen + 1 + strlen(pfx);
            if (all>=FILENAME_MAX)
        	    return NULL;
            memcpy(buf+dirlen+1, pfx, FILENAME_MAX - all);
        } else {
            all = dirlen + 1;
        }

        memcpy(buf+all, "XXXXXX", 6	);
        all += 6 ;
        buf[all]= 0;
        ptr =	(char *)malloc(all);
        memcpy(ptr,	buf, all);
        return mktemp(ptr);
    }


    static int
    lockf(int fd, int cmd, off_t len) {
        return 0;
    }


// override
    static pid_t
    pydk_getpid(void) {
        char *val = getenv("WASIX_PID");
        char *end = val + strlen(val);
        if (val && val[0] != '\0') {
	    return (pid_t)strtol(val, &end, 10);
        }
#   ifdef _WASIX_PID
        return (pid_t)(_WASIX_PID);
#   else
        return 66600;
#   endif
    }
#   define getpid() pydk_getpid()

// setjmp

// override
#   define __wasm_exception_handling__
#   include <setjmp.h>
    static int pydk_sigsetjmp(sigjmp_buf env, int savesigs) {
        return 0;
    }
#   define sigsetjmp(env, savesigs) pydk_sigsetjmp(env, savesigs)





// socket.h
#   define SO_KEEPALIVE    9
#   define SO_REUSEADDR    2

    typedef uint32_t socklen_t;

    static int
    bind(int socket, void *address, socklen_t address_len) {
	    return 0;
    }



#   if defined(PYDK)

        extern ssize_t recvfrom(int socket, void *buffer, size_t length, int flags, void *address, socklen_t *address_len);
        extern int socket(int domain, int type, int protocol);
        extern ssize_t sendto(int socket, const void *message, size_t length, int flags, void *dest_addr, socklen_t dest_len);
        extern int connect(int socket, void *address, socklen_t address_len);


#   else

        static int
        connect(int socket, void *address, socklen_t address_len) {
	        return 0;
        }

        static ssize_t
        sendto(int socket, const void *message, size_t length, int flags, void *dest_addr, socklen_t dest_len) {
	        return 0;
        }
        static int
        fd_sock = 100;

        static ssize_t
        recvfrom(int socket, void *buffer, size_t length, int flags, void *address, socklen_t *address_len) {
	        return 0;
        }

        static int
        socket(int domain, int type, int protocol) {
            return fd_sock++;
        }

#   endif

    static int
    setsockopt(int socket, int level, int option_name, const void *option_value, socklen_t option_len) {
	    return 0;
    }


#   define SOCK_RAW 3
#   define SO_ERROR 0x1007

    static struct servent *
    getservbyname(const char *name, const char *proto) {
        return NULL;
    }

    static struct servent *
    getservbyport(int port, const char *proto) {
        return NULL;
    }

    static struct protoent *
    getprotobyname(const char *name) {
        return NULL;
    }
    static struct hostent *
    gethostbyname(const char *name){
        return NULL;
    }

    static struct hostent *
    gethostbyaddr(const void *addr, socklen_t len, int type) {
        return NULL;
    }

    static struct protoent *
    getprotoent(void) {
        return NULL;
    }

    static const char cc_hstrerror[] = "hstrerror";

    static int * __h_errno_location(void){
        return NULL;
    }

    static const char *
    hstrerror(int ecode)
    {
        return &cc_hstrerror[0];
    }
#else
#   define __wasi__p2
#endif // __wasi__p2
