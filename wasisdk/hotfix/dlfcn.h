#ifndef	_DLFCN_H
#define	_DLFCN_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#define RTLD_LAZY   1
#define RTLD_NOW    2
#define RTLD_NOLOAD 4
#define RTLD_NODELETE 4096
#define RTLD_GLOBAL 256
#define RTLD_LOCAL  0

#define RTLD_NEXT    ((void *)-1)
#define RTLD_DEFAULT ((void *)0)

#define RTLD_DI_LINKMAP 2

static int
dlclose(void *) {
    puts("int dlclose(void)");
    return 0;
}

static const char *errormsg = "dlerror";

static char *
dlerror(void) { 
    return (char *)dlerror;    
}

static void *
dlopen(const char *, int) {
    puts("void *dlopen(const char *, int)");
    return NULL;
}

static void *
dlsym(void *__restrict, const char *__restrict) {
    puts("void *dlsym(void *__restrict, const char *__restrict)");
    return NULL;
}


#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
typedef struct {
	const char *dli_fname;
	void *dli_fbase;
	const char *dli_sname;
	void *dli_saddr;
} Dl_info;
int dladdr(const void *, Dl_info *);
int dlinfo(void *, int, void *);
#endif

#if _REDIR_TIME64
__REDIR(dlsym, __dlsym_time64);
#endif

#ifdef __cplusplus
}
#endif

#endif
