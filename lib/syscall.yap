
use "lib/uapi.yap"
use "lib/bool.yap"
use "lib/debug.yap"

seq SYSCALL
{
    READ, 
    WRITE,
    OPEN, 
    CLOSE,
    STAT,
    FSTAT,
    
    POLL  = 7,
    LSEEK = 8,

    BRK = 12,

    NANOSLEEP = 35,

    SOCKET  = 41,
    CONNECT = 42,
    ACCEPT  = 43,
    SENDTO  = 44,

    SHUTDOWN = 48,
    BIND     = 49,
    LISTEN   = 50,

    SETSOCKOPT = 54,

    EXECVE = 59,
    EXIT   = 60,

    GETDENTS = 78,

    UNLINK = 87,

    CLOCK_GETTIME   = 228,
    CLOCK_NANOSLEEP = 230,
}



fn Sys::TryCall(caller, code, a1, a2, a3, a4, a5)
{
    put retval = syscall(code, a1, a2, a3, a4, a5);

    jump skip ~ Bool::Not(Sys::Error(retval));
        print("[%s] %s\n", [caller, Sys::ErrorMsg(retval)]);
    lab skip;


    return retval;
}



fn Sys::Error(retval)
{
    return retval > (0 - 4095);
}

fn Sys::ErrorMsg(retval)
{
    put code = 0 - retval;

	jump skip_EPERM	            ~ code != Sys::Errno::EPERM;            return "Operation not permitted";                           lab skip_EPERM;
	jump skip_ENOENT	        ~ code != Sys::Errno::ENOENT;           return "No such file or directory";                         lab skip_ENOENT;
	jump skip_ESRCH	            ~ code != Sys::Errno::ESRCH;            return "No such process";                                   lab skip_ESRCH;
	jump skip_EINTR	            ~ code != Sys::Errno::EINTR;            return "Interrupted system call";                           lab skip_EINTR;
	jump skip_EIO	            ~ code != Sys::Errno::EIO;              return "I/O error";                                         lab skip_EIO;
	jump skip_ENXIO	            ~ code != Sys::Errno::ENXIO;            return "No such device or address";                         lab skip_ENXIO;
	jump skip_E2BIG	            ~ code != Sys::Errno::E2BIG;            return "Argument list too long";                            lab skip_E2BIG;
	jump skip_ENOEXEC	        ~ code != Sys::Errno::ENOEXEC;          return "Exec format error";                                 lab skip_ENOEXEC;
	jump skip_EBADF	            ~ code != Sys::Errno::EBADF;            return "Bad file number";                                   lab skip_EBADF;
	jump skip_ECHILD	        ~ code != Sys::Errno::ECHILD;           return "No child processes";                                lab skip_ECHILD;
	jump skip_EAGAIN	        ~ code != Sys::Errno::EAGAIN;           return "Try again";                                         lab skip_EAGAIN;
	jump skip_ENOMEM	        ~ code != Sys::Errno::ENOMEM;           return "Out of memory";                                     lab skip_ENOMEM;
	jump skip_EACCES	        ~ code != Sys::Errno::EACCES;           return "Permission denied";                                 lab skip_EACCES;
	jump skip_EFAULT	        ~ code != Sys::Errno::EFAULT;           return "Bad address";                                       lab skip_EFAULT;
	jump skip_ENOTBLK	        ~ code != Sys::Errno::ENOTBLK;          return "Block device required";                             lab skip_ENOTBLK;
	jump skip_EBUSY	            ~ code != Sys::Errno::EBUSY;            return "Device or resource busy";                           lab skip_EBUSY;
	jump skip_EEXIST	        ~ code != Sys::Errno::EEXIST;           return "File exists";                                       lab skip_EEXIST;
	jump skip_EXDEV	            ~ code != Sys::Errno::EXDEV;            return "Cross-device link";                                 lab skip_EXDEV;
	jump skip_ENODEV	        ~ code != Sys::Errno::ENODEV;           return "No such device";                                    lab skip_ENODEV;
	jump skip_ENOTDIR	        ~ code != Sys::Errno::ENOTDIR;          return "Not a directory";                                   lab skip_ENOTDIR;
	jump skip_EISDIR	        ~ code != Sys::Errno::EISDIR;           return "Is a directory";                                    lab skip_EISDIR;
	jump skip_EINVAL	        ~ code != Sys::Errno::EINVAL;           return "Invalid argument";                                  lab skip_EINVAL;
	jump skip_ENFILE	        ~ code != Sys::Errno::ENFILE;           return "File table overflow";                               lab skip_ENFILE;
	jump skip_EMFILE	        ~ code != Sys::Errno::EMFILE;           return "Too many open files";                               lab skip_EMFILE;
	jump skip_ENOTTY	        ~ code != Sys::Errno::ENOTTY;           return "Not a typewriter";                                  lab skip_ENOTTY;
	jump skip_ETXTBSY	        ~ code != Sys::Errno::ETXTBSY;          return "Text file busy";                                    lab skip_ETXTBSY;
	jump skip_EFBIG	            ~ code != Sys::Errno::EFBIG;            return "File too large";                                    lab skip_EFBIG;
	jump skip_ENOSPC	        ~ code != Sys::Errno::ENOSPC;           return "No space left on device";                           lab skip_ENOSPC;
	jump skip_ESPIPE	        ~ code != Sys::Errno::ESPIPE;           return "Illegal seek";                                      lab skip_ESPIPE;
	jump skip_EROFS	            ~ code != Sys::Errno::EROFS;            return "Read-only file system";                             lab skip_EROFS;
	jump skip_EMLINK	        ~ code != Sys::Errno::EMLINK;           return "Too many links";                                    lab skip_EMLINK;
	jump skip_EPIPE	            ~ code != Sys::Errno::EPIPE;            return "Broken pipe";                                       lab skip_EPIPE;
	jump skip_EDOM	            ~ code != Sys::Errno::EDOM;             return "Math argument out of domain of func";               lab skip_EDOM;
	jump skip_ERANGE	        ~ code != Sys::Errno::ERANGE;           return "Math result not representable";                     lab skip_ERANGE;
	jump skip_EDEADLK	        ~ code != Sys::Errno::EDEADLK;          return "Resource deadlock would occur";                     lab skip_EDEADLK;
	jump skip_ENAMETOOLONG	    ~ code != Sys::Errno::ENAMETOOLONG;     return "File name too long";                                lab skip_ENAMETOOLONG;
	jump skip_ENOLCK	        ~ code != Sys::Errno::ENOLCK;           return "No record locks available";                         lab skip_ENOLCK;
	jump skip_ENOSYS	        ~ code != Sys::Errno::ENOSYS;           return "Function not implemented";                          lab skip_ENOSYS;
	jump skip_ENOTEMPTY	        ~ code != Sys::Errno::ENOTEMPTY;        return "Directory not empty";                               lab skip_ENOTEMPTY;
	jump skip_ELOOP	            ~ code != Sys::Errno::ELOOP;            return "Too many symbolic links encountered";               lab skip_ELOOP;
	jump skip_ENOMSG	        ~ code != Sys::Errno::ENOMSG;           return "No message of desired type";                        lab skip_ENOMSG;
	jump skip_EIDRM	            ~ code != Sys::Errno::EIDRM;            return "Identifier removed";                                lab skip_EIDRM;
	jump skip_ECHRNG	        ~ code != Sys::Errno::ECHRNG;           return "Channel number out of range";                       lab skip_ECHRNG;
	jump skip_EL2NSYNC	        ~ code != Sys::Errno::EL2NSYNC;         return "Level 2 not synchronized";                          lab skip_EL2NSYNC;
	jump skip_EL3HLT	        ~ code != Sys::Errno::EL3HLT;           return "Level 3 halted";                                    lab skip_EL3HLT;
	jump skip_EL3RST	        ~ code != Sys::Errno::EL3RST;           return "Level 3 reset";                                     lab skip_EL3RST;
	jump skip_ELNRNG	        ~ code != Sys::Errno::ELNRNG;           return "Link number out of range";                          lab skip_ELNRNG;
	jump skip_EUNATCH	        ~ code != Sys::Errno::EUNATCH;          return "Protocol driver not attached";                      lab skip_EUNATCH;
	jump skip_ENOCSI	        ~ code != Sys::Errno::ENOCSI;           return "No CSI structure available";                        lab skip_ENOCSI;
	jump skip_EL2HLT	        ~ code != Sys::Errno::EL2HLT;           return "Level 2 halted";                                    lab skip_EL2HLT;
	jump skip_EBADE	            ~ code != Sys::Errno::EBADE;            return "Invalid exchange";                                  lab skip_EBADE;
	jump skip_EBADR	            ~ code != Sys::Errno::EBADR;            return "Invalid request descriptor";                        lab skip_EBADR;
	jump skip_EXFULL	        ~ code != Sys::Errno::EXFULL;           return "Exchange full";                                     lab skip_EXFULL;
	jump skip_ENOANO	        ~ code != Sys::Errno::ENOANO;           return "No anode";                                          lab skip_ENOANO;
	jump skip_EBADRQC	        ~ code != Sys::Errno::EBADRQC;          return "Invalid request code";                              lab skip_EBADRQC;
	jump skip_EBADSLT	        ~ code != Sys::Errno::EBADSLT;          return "Invalid slot";                                      lab skip_EBADSLT;
	jump skip_EBFONT	        ~ code != Sys::Errno::EBFONT;           return "Bad font file format";                              lab skip_EBFONT;
	jump skip_ENOSTR	        ~ code != Sys::Errno::ENOSTR;           return "Device not a stream";                               lab skip_ENOSTR;
	jump skip_ENODATA	        ~ code != Sys::Errno::ENODATA;          return "No data available";                                 lab skip_ENODATA;
	jump skip_ETIME	            ~ code != Sys::Errno::ETIME;            return "Timer expired";                                     lab skip_ETIME;
	jump skip_ENOSR	            ~ code != Sys::Errno::ENOSR;            return "Out of streams resources";                          lab skip_ENOSR;
	jump skip_ENONET	        ~ code != Sys::Errno::ENONET;           return "Machine is not on the network";                     lab skip_ENONET;
	jump skip_ENOPKG	        ~ code != Sys::Errno::ENOPKG;           return "Package not installed";                             lab skip_ENOPKG;
	jump skip_EREMOTE	        ~ code != Sys::Errno::EREMOTE;          return "Object is remote";                                  lab skip_EREMOTE;
	jump skip_ENOLINK	        ~ code != Sys::Errno::ENOLINK;          return "Link has been severed";                             lab skip_ENOLINK;
	jump skip_EADV	            ~ code != Sys::Errno::EADV;             return "Advertise error";                                   lab skip_EADV;
	jump skip_ESRMNT	        ~ code != Sys::Errno::ESRMNT;           return "Srmount error";                                     lab skip_ESRMNT;
	jump skip_ECOMM	            ~ code != Sys::Errno::ECOMM;            return "Communication error on send";                       lab skip_ECOMM;
	jump skip_EPROTO	        ~ code != Sys::Errno::EPROTO;           return "Protocol error";                                    lab skip_EPROTO;
	jump skip_EMULTIHOP	        ~ code != Sys::Errno::EMULTIHOP;        return "Multihop attempted";                                lab skip_EMULTIHOP;
	jump skip_EDOTDOT	        ~ code != Sys::Errno::EDOTDOT;          return "RFS specific error";                                lab skip_EDOTDOT;
	jump skip_EBADMSG	        ~ code != Sys::Errno::EBADMSG;          return "Not a data message";                                lab skip_EBADMSG;
	jump skip_EOVERFLOW	        ~ code != Sys::Errno::EOVERFLOW;        return "Value too large for defined data type";             lab skip_EOVERFLOW;
	jump skip_ENOTUNIQ	        ~ code != Sys::Errno::ENOTUNIQ;         return "Name not unique on network";                        lab skip_ENOTUNIQ;
	jump skip_EBADFD	        ~ code != Sys::Errno::EBADFD;           return "File descriptor in bad state";                      lab skip_EBADFD;
	jump skip_EREMCHG	        ~ code != Sys::Errno::EREMCHG;          return "Remote address changed";                            lab skip_EREMCHG;
	jump skip_ELIBACC	        ~ code != Sys::Errno::ELIBACC;          return "Can not access a needed shared library";            lab skip_ELIBACC;
	jump skip_ELIBBAD	        ~ code != Sys::Errno::ELIBBAD;          return "Accessing a corrupted shared library";              lab skip_ELIBBAD;
	jump skip_ELIBSCN	        ~ code != Sys::Errno::ELIBSCN;          return "lib section in a.out corrupted";                    lab skip_ELIBSCN;
	jump skip_ELIBMAX	        ~ code != Sys::Errno::ELIBMAX;          return "Attempting to link in too many shared libraries";   lab skip_ELIBMAX;
	jump skip_ELIBEXEC	        ~ code != Sys::Errno::ELIBEXEC;         return "Cannot exec a shared library directly";             lab skip_ELIBEXEC;
	jump skip_EILSEQ	        ~ code != Sys::Errno::EILSEQ;           return "Illegal byte sequence";                             lab skip_EILSEQ;
	jump skip_ERESTART	        ~ code != Sys::Errno::ERESTART;         return "Interrupted system call should be restarted";       lab skip_ERESTART;
	jump skip_ESTRPIPE	        ~ code != Sys::Errno::ESTRPIPE;         return "Streams pipe error";                                lab skip_ESTRPIPE;
	jump skip_EUSERS	        ~ code != Sys::Errno::EUSERS;           return "Too many users";                                    lab skip_EUSERS;
	jump skip_ENOTSOCK	        ~ code != Sys::Errno::ENOTSOCK;         return "Socket operation on non-socket";                    lab skip_ENOTSOCK;
	jump skip_EDESTADDRREQ	    ~ code != Sys::Errno::EDESTADDRREQ;     return "Destination address required";                      lab skip_EDESTADDRREQ;
	jump skip_EMSGSIZE	        ~ code != Sys::Errno::EMSGSIZE;         return "Message too long";                                  lab skip_EMSGSIZE;
	jump skip_EPROTOTYPE	    ~ code != Sys::Errno::EPROTOTYPE;       return "Protocol wrong type for socket";                    lab skip_EPROTOTYPE;
	jump skip_ENOPROTOOPT	    ~ code != Sys::Errno::ENOPROTOOPT;      return "Protocol not available";                            lab skip_ENOPROTOOPT;
	jump skip_EPROTONOSUPPORT	~ code != Sys::Errno::EPROTONOSUPPORT;  return "Protocol not supported";                            lab skip_EPROTONOSUPPORT;
	jump skip_ESOCKTNOSUPPORT	~ code != Sys::Errno::ESOCKTNOSUPPORT;  return "Socket type not supported";                         lab skip_ESOCKTNOSUPPORT;
	jump skip_EOPNOTSUPP	    ~ code != Sys::Errno::EOPNOTSUPP;       return "Operation not supported on transport endpoint";     lab skip_EOPNOTSUPP;
	jump skip_EPFNOSUPPORT	    ~ code != Sys::Errno::EPFNOSUPPORT;     return "Protocol family not supported";                     lab skip_EPFNOSUPPORT;
	jump skip_EAFNOSUPPORT	    ~ code != Sys::Errno::EAFNOSUPPORT;     return "Address family not supported by protocol";          lab skip_EAFNOSUPPORT;
	jump skip_EADDRINUSE	    ~ code != Sys::Errno::EADDRINUSE;       return "Address already in use";                            lab skip_EADDRINUSE;
	jump skip_EADDRNOTAVAIL	    ~ code != Sys::Errno::EADDRNOTAVAIL;    return "Cannot assign requested address";                   lab skip_EADDRNOTAVAIL;
	jump skip_ENETDOWN	        ~ code != Sys::Errno::ENETDOWN;         return "Network is down";                                   lab skip_ENETDOWN;
	jump skip_ENETUNREACH	    ~ code != Sys::Errno::ENETUNREACH;      return "Network is unreachable";                            lab skip_ENETUNREACH;
	jump skip_ENETRESET	        ~ code != Sys::Errno::ENETRESET;        return "Network dropped connection because of reset";       lab skip_ENETRESET;
	jump skip_ECONNABORTED	    ~ code != Sys::Errno::ECONNABORTED;     return "Software caused connection abort";                  lab skip_ECONNABORTED;
	jump skip_ECONNRESET	    ~ code != Sys::Errno::ECONNRESET;       return "Connection reset by peer";                          lab skip_ECONNRESET;
	jump skip_ENOBUFS	        ~ code != Sys::Errno::ENOBUFS;          return "No buffer space available";                         lab skip_ENOBUFS;
	jump skip_EISCONN	        ~ code != Sys::Errno::EISCONN;          return "Transport endpoint is already connected";           lab skip_EISCONN;
	jump skip_ENOTCONN	        ~ code != Sys::Errno::ENOTCONN;         return "Transport endpoint is not connected";               lab skip_ENOTCONN;
	jump skip_ESHUTDOWN	        ~ code != Sys::Errno::ESHUTDOWN;        return "Cannot send after transport endpoint shutdown";     lab skip_ESHUTDOWN;
	jump skip_ETOOMANYREFS	    ~ code != Sys::Errno::ETOOMANYREFS;     return "Too many references: cannot splice";                lab skip_ETOOMANYREFS;
	jump skip_ETIMEDOUT	        ~ code != Sys::Errno::ETIMEDOUT;        return "Connection timed out";                              lab skip_ETIMEDOUT;
	jump skip_ECONNREFUSED	    ~ code != Sys::Errno::ECONNREFUSED;     return "Connection refused";                                lab skip_ECONNREFUSED;
	jump skip_EHOSTDOWN	        ~ code != Sys::Errno::EHOSTDOWN;        return "Host is down";                                      lab skip_EHOSTDOWN;
	jump skip_EHOSTUNREACH	    ~ code != Sys::Errno::EHOSTUNREACH;     return "No route to host";                                  lab skip_EHOSTUNREACH;
	jump skip_EALREADY	        ~ code != Sys::Errno::EALREADY;         return "Operation already in progress";                     lab skip_EALREADY;
	jump skip_EINPROGRESS	    ~ code != Sys::Errno::EINPROGRESS;      return "Operation now in progress";                         lab skip_EINPROGRESS;
	jump skip_ESTALE	        ~ code != Sys::Errno::ESTALE;           return "Stale NFS file handle";                             lab skip_ESTALE;
	jump skip_EUCLEAN	        ~ code != Sys::Errno::EUCLEAN;          return "Structure needs cleaning";                          lab skip_EUCLEAN;
	jump skip_ENOTNAM	        ~ code != Sys::Errno::ENOTNAM;          return "Not a XENIX named type file";                       lab skip_ENOTNAM;
	jump skip_ENAVAIL	        ~ code != Sys::Errno::ENAVAIL;          return "No XENIX semaphores available";                     lab skip_ENAVAIL;
	jump skip_EISNAM	        ~ code != Sys::Errno::EISNAM;           return "Is a named type file";                              lab skip_EISNAM;
	jump skip_EREMOTEIO	        ~ code != Sys::Errno::EREMOTEIO;        return "Remote I/O error";                                  lab skip_EREMOTEIO;
	jump skip_EDQUOT	        ~ code != Sys::Errno::EDQUOT;           return "Quota exceeded";                                    lab skip_EDQUOT;
	jump skip_ENOMEDIUM	        ~ code != Sys::Errno::ENOMEDIUM;        return "No medium found";                                   lab skip_ENOMEDIUM;
	jump skip_EMEDIUMTYPE	    ~ code != Sys::Errno::EMEDIUMTYPE;      return "Wrong medium type";                                 lab skip_EMEDIUMTYPE;
	jump skip_ECANCELED	        ~ code != Sys::Errno::ECANCELED;        return "Operation Canceled";                                lab skip_ECANCELED;
	jump skip_ENOKEY	        ~ code != Sys::Errno::ENOKEY;           return "Required key not available";                        lab skip_ENOKEY;
	jump skip_EKEYEXPIRED	    ~ code != Sys::Errno::EKEYEXPIRED;      return "Key has expired";                                   lab skip_EKEYEXPIRED;
	jump skip_EKEYREVOKED	    ~ code != Sys::Errno::EKEYREVOKED;      return "Key has been revoked";                              lab skip_EKEYREVOKED;
	jump skip_EKEYREJECTED	    ~ code != Sys::Errno::EKEYREJECTED;     return "Key was rejected by service";                       lab skip_EKEYREJECTED;
	jump skip_EOWNERDEAD	    ~ code != Sys::Errno::EOWNERDEAD;       return "Owner died";                                        lab skip_EOWNERDEAD;
	jump skip_ENOTRECOVERABLE	~ code != Sys::Errno::ENOTRECOVERABLE;  return "State not recoverable";                             lab skip_ENOTRECOVERABLE;

}


