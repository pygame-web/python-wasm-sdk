// socket.h 2025-06-26


#define PGS_ILOCK "/tmp/pglite/base/.s.PGSQL.5432.lock.in"
#define PGS_IN    "/tmp/pglite/base/.s.PGSQL.5432.in"
#define PGS_OLOCK "/tmp/pglite/base/.s.PGSQL.5432.lock.out"
#define PGS_OUT   "/tmp/pglite/base/.s.PGSQL.5432.out"


// unix socket via file emulation using sched_yiedl for event pump.
// =================================================================================================

#include <sched.h>
#include <stdbool.h>

/*


        extern ssize_t sendto(int socket, const void *message, size_t length, int flags, void *dest_addr, socklen_t dest_len);
        static ssize_t
        sendto(int socket, const void *message, size_t length, int flags, void *dest_addr, socklen_t dest_len) {
	        return 0;
        }

        extern ssize_t recvfrom(int socket, void *buffer, size_t length, int flags, void *address, socklen_t *address_len);
        static ssize_t
        recvfrom(int socket, void *buffer, size_t length, int flags, void *address, socklen_t *address_len) {
	        return 0;
        }


#   endif
*/

#define SOCK_RAW 3
#define SO_ERROR 0x1007
#define SO_KEEPALIVE    9
#define SO_REUSEADDR    2

typedef uint32_t socklen_t;

static int
bind(int socket, void *address, socklen_t address_len) {
    return 0;
}



SCOPE int
setsockopt(int socket, int level, int option_name, const void *option_value, socklen_t option_len) {
    return 0;
}


SCOPE struct servent *
getservbyname(const char *name, const char *proto) {
    return NULL;
}

SCOPE struct servent *
getservbyport(int port, const char *proto) {
    return NULL;
}

SCOPE struct protoent *
getprotobyname(const char *name) {
    return NULL;
}
SCOPE struct hostent *
gethostbyname(const char *name){
    return NULL;
}

SCOPE struct hostent *
gethostbyaddr(const void *addr, socklen_t len, int type) {
    return NULL;
}

SCOPE struct protoent *
getprotoent(void) {
    return NULL;
}

SCOPE const char cc_hstrerror[] = "hstrerror";

SCOPE int * __h_errno_location(void){
    return NULL;
}

SCOPE const char *
hstrerror(int ecode)
{
    return &cc_hstrerror[0];
}

// =============================================================================



SCOPE int
sdk_getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen) {
    return 0;
}
#define getsockopt(sockfd, level, optname, optval, optlen) sdk_getsockopt(sockfd, level, optname, optval, optlen)


SCOPE int
sdk_getsockname(int sockfd, void *restrict addr, socklen_t *restrict addrlen) {
    return 0;
}
#define getsockname(sockfd, addr, addrlen) sdk_getsockname(sockfd, addr, addrlen)



/*
extern int socket(int domain, int type, int protocol);

    todo : replace socket value by fd_in file descriptor for select to work
    map: fd_in to fd sockets with a struct

*/

extern volatile int fd_sock;
extern volatile FILE *fd_FILE;
extern volatile int fd_out;
extern volatile int fd_queue;


SCOPE volatile int watchdog = 0;


SCOPE volatile int fd_current_pos = 0;
SCOPE volatile int fd_filesize = 0;
SCOPE volatile bool web_warned = false;


SCOPE int
sdk_socket(int domain, int type, int protocol) {

    if (!fd_sock) {
        FILE *select_file = fopen("/tmp/pglite/base/.s.PGSQL.5432","w+");
        fd_sock= fileno(select_file);
    }

    if (!fd_sock) {
        fputs("# 146:" __FILE__ ": single connection only\r\n", stderr);
        abort();
    }

    printf("# 150 : domain =%d type=%d proto=%d\r\n", domain , type, protocol);
    printf("# 151 : socket fd=%d\r\n", fd_sock);

    if (domain|AF_UNIX) {

    } else {
        puts("# 156:" __FILE__ ": only unix domain socket supported\r\n");
        abort();
    }

    return fd_sock;
}
#define socket(domain, type, protocol) sdk_socket(domain, type, protocol)



/*
extern int connect(int socket, void *address, socklen_t address_len);

static int
connect(int socket, void *address, socklen_t address_len) {
    return 0;
}
*/

#include <sys/un.h>
SCOPE int
sdk_connect(int socket, void *address, socklen_t address_len) {
        // Retrieve the socket name
        struct sockaddr_un retrieved_addr;
        socklen_t addrlen = sizeof(struct sockaddr_un);
        if (getsockname(socket, (struct sockaddr *)&retrieved_addr, &addrlen) == -1) {
            puts("getsockname error");
        }
        printf("# 184:" __FILE__ ": unix socket path '%s' struct %p\r\n", retrieved_addr.sun_path, retrieved_addr);
#if 1
    fd_queue = 0;
    fd_FILE = fopen(PGS_ILOCK, "w");
    if (fd_FILE) {
        fd_out = fileno(fd_FILE);
        printf("# 183: AF_UNIX sock=%d (fd_sock write) FILE=%s\n", fd_out, PGS_ILOCK);
    } else {
        printf("# 185: AF_UNIX ERROR OPEN (w/w+) FILE=%s\n", PGS_ILOCK);
        abort();
    }
    printf("# 98: connect fd=%d\r\n", socket);
    return 0;
#else
    puts("# 101: connect EINPROGRESS\r\n");
    errno = EINPROGRESS;
    return -1;
#endif
}
#define connect(socket, address, address_len) sdk_connect(socket, address, address_len)



SCOPE void
sdk_sock_flush() {
    if (fd_queue) {
        printf(" -- 203 sockflush : AIO YIELD, expecting %s filled on return --\r\n", PGS_OUT);
        if (!fd_FILE) {
            if (!web_warned) {
                puts("# 206: WARNING: fd_FILE not set but queue not empty, assuming web and bad FS\r\n");
                web_warned = true;
            }
            abort();
         } else {

            printf("#       213: SENT=%ld/%d fd_out=%d == fno=%d\r\n", sdk_fdtell(fd_out), fd_queue, fd_out, fileno(fd_FILE));
            fclose(fd_FILE);
            rename(PGS_ILOCK, PGS_IN);
            sched_yield();

// freopen does not work on wasi/emscripte
// freopen(PGS_ILOCK, "w", fd_FILE);
            fd_FILE = fopen(PGS_ILOCK, "w");
            fd_out = fileno(fd_FILE);
            printf("#       218: fd_out=%d fno=%d\r\n", fd_out, fileno(fd_FILE));
        }
        fd_queue = 0;
        return;
    }

    printf(" -- 243 sockflush[%d] : NO YIELD --\r\n", watchdog);

    // limit inf loops
    if (watchdog++ > 32) {
        puts("# 231: sdk_sock_flush : busy looping ? exit(238) !\r\n"); exit(__LINE__);
    }
}

SCOPE ssize_t
sdk_recvfrom(int socket, void *buffer, size_t length, int flags, void *address, socklen_t *address_len) {
//    int busy = 0;
    int rcv = -1;
    int last_pos = fd_current_pos;

    /* no flush while reading */
    if (!last_pos) {
        sdk_sock_flush();
    } else {
        /* reset watchdog */
        watchdog = 0;
    }

    FILE *sock_in = fopen(PGS_OUT,"r");
    if (sock_in) {
        if (!fd_filesize) {
            fseek(sock_in, 0L, SEEK_END);
            fd_filesize = ftell(sock_in);
        }
        fseek(sock_in, fd_current_pos, SEEK_SET);

        char *buf = buffer;
        buf[0] = 0;

        // read file into client socket buffer
        rcv = fread(buf, 1, length, sock_in);

        // move sock-in-file read pointer
        fd_current_pos += rcv;

        // was it partial read ?
        if ( fd_current_pos < fd_filesize) {
            // fd_current_pos = ftell(sock_in);
            printf("# 276: sdk_recvfrom(%s read=%d == %d ]%d-%d] / %d MAX %zu\r\n", PGS_OUT, rcv, (fd_current_pos -  last_pos) ,last_pos, fd_current_pos, fd_filesize, length);
            fclose(sock_in);
            return rcv;
        }

        // fully read
        printf("# 282: sdk_recvfrom(%s max=%zu total=%d) read=%d\r\n", PGS_OUT, length, fd_filesize, rcv);
        fd_queue = 0;
        fd_filesize = 0;
        fd_current_pos = 0;
        fclose(sock_in);
        unlink(PGS_OUT);
        /* reset watchdog */
        watchdog = 0;
    } else {
        printf("# 298: sdk_recvfrom(%s max=%zu) ERROR\r\n", PGS_OUT, length);
        errno = EINTR;
    }
    return rcv;

}
#define recvfrom(socket, buffer, length, flags, address, address_len) sdk_recvfrom(socket, buffer, length, flags, address, address_len)


SCOPE ssize_t
sdk_sendto(int sockfd, const void *buf, size_t len, int flags, void *dest_addr, socklen_t addrlen) {
    int sent = write( fd_out, buf, len);
    /* reset watchdog */
    watchdog = 0;

//    printf("# 307: send/sendto(%d ?= %ld )/%zu sockfd=%d fno=%d == fd_out=%d)\r\n", sent, sdk_fdtell(fd_out), len, sockfd, fileno(fd_FILE), fd_out);
    fd_queue += sent;
    return sent;
}
#define sendto(sockfd, buf, len, flags, address, address_len) sdk_sendto(sockfd, buf, len, flags, address, address_len)

SCOPE ssize_t
sdk_send(int sockfd, const void *buf, size_t len, int flags) {
    return sdk_sendto(sockfd, buf, len, flags, NULL, 0);
}
#define send(sockfd, buf, len, flags) sdk_send(sockfd, buf, len, flags)




SCOPE ssize_t
sdk_recv(int sockfd, void *buf, size_t len, int flags) {
    return sdk_recvfrom(sockfd, buf, len, flags, NULL, NULL);
}
#define recv(sockfd, buf, len, flags) sdk_recv(sockfd, buf, len, flags)



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>

/*
SCOPE struct addrinfo *
create_result(int family, int socktype, int protocol, struct sockaddr *addr, socklen_t addrlen) {
    struct addrinfo *res = malloc(sizeof(struct addrinfo));
    if (!res) return NULL;

    res->ai_family = family;
    res->ai_socktype = socktype;
    res->ai_protocol = protocol;
    res->ai_addrlen = addrlen;

    res->ai_addr = malloc(addrlen);
    if (!res->ai_addr) {
        free(res);
        return NULL;
    }
    memcpy(res->ai_addr, addr, addrlen);
    res->ai_canonname = NULL;
    res->ai_next = NULL;

    return res;
}


SCOPE int
sdk_getaddrinfo(const char *restrict node, const char *restrict service,
                       const struct addrinfo *restrict hints,
                       struct addrinfo **restrict res) {
    if (!node && !service) return EAI_NONAME;

    int port = 0;
    if (service) port = atoi(service); // Simple decimal port parsing

    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);

    if (node) {
        if (inet_pton(AF_INET, node, &addr4.sin_addr) <= 0) {
            return EAI_FAIL; // Not a numeric IPv4 address
        }
    } else {
        addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    }

    *res = create_result(AF_INET, SOCK_STREAM, IPPROTO_TCP,
                         (struct sockaddr *)&addr4, sizeof(addr4));
    if (!*res) return EAI_MEMORY;

    return 0;
}
*/

SCOPE int
sdk_getaddrinfo(const char *hostname, const char *service,
               const struct addrinfo *hints, struct addrinfo **res) {
    struct addrinfo *result = malloc(sizeof(struct addrinfo));
    if (!result) return EAI_MEMORY;

    memset(result, 0, sizeof(struct addrinfo));
    result->ai_family = AF_INET;
    result->ai_socktype = SOCK_STREAM;
    result->ai_protocol = IPPROTO_TCP;

    struct sockaddr_in *addr = malloc(sizeof(struct sockaddr_in));
    if (!addr) {
        free(result);
        return EAI_MEMORY;
    }

    addr->sin_family = AF_INET;
    addr->sin_port = htons(atoi(service));
    if (inet_pton(AF_INET, hostname, &(addr->sin_addr)) <= 0) {
        free(result);
        free(addr);
        return EAI_FAIL;
    }

    result->ai_addr = (struct sockaddr *)addr;
    result->ai_addrlen = sizeof(struct sockaddr_in);
    result->ai_next = NULL;

    *res = result;
    return 0;
}
#define getaddrinfo(node, service, hints, res) sdk_getaddrinfo(node, service, hints, res)

SCOPE void
sdk_freeaddrinfo(struct addrinfo *res) {
    while (res) {
        struct addrinfo *next = res->ai_next;
        if (res->ai_addr) {
            free(res->ai_addr);
        }
        if (res->ai_canonname) {
            free(res->ai_canonname);
        }
        free(res);
        res = next;
    }
}
#define freeaddrinfo(res) sdk_freeaddrinfo(res)





SCOPE const char *
sdk_gai_strerror(int errcode) {
    switch (errcode) {
        case EAI_AGAIN:     return "Temporary failure in name resolution";
        case EAI_BADFLAGS:  return "Invalid value for ai_flags";
        case EAI_FAIL:      return "Non-recoverable failure in name resolution";
        case EAI_FAMILY:    return "ai_family not supported";
        case EAI_MEMORY:    return "Memory allocation failure";
        case EAI_NONAME:    return "Name or service not known";
        case EAI_SERVICE:   return "Service not supported for socket type";
        case EAI_SOCKTYPE:  return "Socket type not supported";
        case EAI_SYSTEM:    return "System error returned in errno";
        case EAI_OVERFLOW:  return "Argument buffer overflow";
        default:            return "Unknown error";
    }
}
#define gai_strerror(errcode) sdk_gai_strerror(errcode)














//
