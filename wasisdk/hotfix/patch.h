#include <stdio.h> // for FILE
#include <unistd.h> // for uid_t, pid_t

#define SCOPE static

SCOPE FILE *
popen(const char *command, const char *type){
    return NULL;
}

SCOPE int
pclose(FILE *stream){
    (void)stream;
    return 0;
}

SCOPE gid_t
getegid(void) {
	return 99;
}

SCOPE uid_t
geteuid(void) {
    return 1000;
}

#include <sys/types.h> // for mode_t
SCOPE mode_t
umask(mode_t mask) {
	return 18;
}


#include <sys/stat.h>

SCOPE int
sdk_chmod(const char * path, int mode_t) {
    return 0;
}
#define chmod(path, mode) sdk_chmod(path, mode)



#include <errno.h>  // for E*
#include <sys/stat.h> // for stat
#include <string.h> // for strlen

#include <time.h> // for clock_gettime
SCOPE char *
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


SCOPE char *
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

SCOPE int
mkstemp(char *tmpl) {
    FILE *ftemp = fopen(mktemp(tmpl),"w");
    return fileno(ftemp);
}


// errno.h
#define EHOSTDOWN 117		/* Host is down */


// sys/socket.h
#define AF_UNIX 1  // PF_LOCAL



// pwd.h

SCOPE int
// getpwuid_r(uid_t uid, struct passwd *pwd, char *buf, size_t buflen, struct passwd **result) {
sdk_getpwuid_r(uid_t uid, void *pwd, char *buf, size_t buflen, void **result) {
  return ENOENT;
}
#define getpwuid_r(uid, pwd, buf, buflen, result) sdk_getpwuid_r(uid, pwd, buf, buflen, result)


SCOPE int
sdk_kill(pid_t pid, int sig) {
	fprintf(stderr, "not killing pid %d with %d\r\n", pid, sig);
    return 0;
}
#define kill(pid, sig) sdk_kill(pid, sig)




#include <stdlib.h> // for strtol

SCOPE pid_t
sdk_getppid(void) {
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

#define getppid() sdk_getppid()


SCOPE FILE *
sdk_tmpfile(void) {
    return fopen(mktemp("/tmp/tmpfile"),"w");
}
#define tmpfile() sdk_tmpfile()







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

    SCOPE char *
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


    SCOPE int
    lockf(int fd, int cmd, off_t len) {
        return 0;
    }



// override
    SCOPE pid_t
    sdk_getpid(void) {
        char *val = getenv("WASIX_PID");
        char *end = val + strlen(val);
        if (val && val[0] != '\0') {
	        return (pid_t)strtol(val, &end, 10);
        }
        return (pid_t)42;
    }
#   define getpid() sdk_getpid()

    SCOPE int
    sdk_getrusage(int who, void *usage) {
        return -1;
    }
#   define getrusage(who, usage) sdk_getrusage(who, usage)


#   include <wasi/api.h>

    SCOPE void sdk_exit(int ec) {
        printf("EXIT(%d)\r\n", ec);
        const char * base = 0 ;
        memset(base, ec, 1);
        // abort();
        // proc_exit(ec);
        __wasi_proc_exit(ec);

    }
#   define exit(ec) sdk_exit(ec)


#   include <stdio.h>
#   include <unistd.h>
#   include <errno.h>

    // defined in ../../src/port/libpgport.a(qsort.o)
    // defined in ../../src/port/libpgport.a(snprintf.o)

    SCOPE long sdk_fdtell(int fd) {
        __wasi_fd_t wasi_fd = (__wasi_fd_t)fd;
        __wasi_filesize_t position = 0;

        // The WASI equivalent of lseek — seek to current position with offset 0
        __wasi_errno_t err = __wasi_fd_seek(
            wasi_fd,
            0,
            __WASI_WHENCE_CUR,
            &position
        );

        if (err != __WASI_ERRNO_SUCCESS) {
            errno = EIO;
            return -1L;
        }

        return (long)position;
    }

    SCOPE long sdk_ftell(FILE *stream) {
        return sdk_fdtell(fileno(stream));
    }
#   define ftell(stream) sdk_ftell(stream)



// setjmp

// override
#   define __wasm_exception_handling__
#   include <setjmp.h>
    SCOPE int sdk_sigsetjmp(sigjmp_buf env, int savesigs) {
        return 0;
    }
#   define sigsetjmp(env, savesigs) sdk_sigsetjmp(env, savesigs)
    SCOPE void sdk_siglongjmp(sigjmp_buf env, int val) {
        puts("# 217:" __FILE__ ": siglongjmp STUB");
    }
#   define siglongjmp(env, val) sdk_siglongjmp(env, val)


#   if defined(PYDK)
#       include "sdk_socket.c"
#   endif




#else
#   define __wasi__p2
#endif // __wasi__p2
