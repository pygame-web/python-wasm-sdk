#ifndef _WASIX_SETJMP_H
#define _WASIX_SETJMP_H

typedef void *jmp_buf;

static int 
setjmp(jmp_buf env) {
    return 0;
}
static 
void longjmp(jmp_buf env, int value) {
   (void)env;
   (void)value;
}

#endif
