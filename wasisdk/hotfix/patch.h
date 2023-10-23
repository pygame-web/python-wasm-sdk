#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/stat.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

#define P_tmpdir "/tmp"
#define	LOCK_EX	2
#define	LOCK_NB	4

static FILE *
popen(const char *command, const char *type){
    return NULL;
}

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
tempnam(const char *dir, const char *pfx)
{
	char s[PATH_MAX];
	size_t l, dl, pl;

	if (!dir) dir = P_tmpdir;
	if (!pfx) pfx = "temp";

	dl = strlen(dir);
	pl = strlen(pfx);
	l = dl + 1 + pl + 1 + 6;

	if (l >= PATH_MAX) {
		errno = ENAMETOOLONG;
		return 0;
	}

	memcpy(s, dir, dl);
	s[dl] = '/';
	memcpy(s+dl+1, pfx, pl);
	s[dl+1+pl] = '_';
	s[l] = 0;

	__randname(s+l-6);
    return strdup(s);
}

static int
lockf(int fd, int cmd, off_t len) {
    return 0;
}

