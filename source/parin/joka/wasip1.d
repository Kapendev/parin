/// The `wasip1` module provides types and functions available in WASI preview 1.
module parin.joka.wasip1;

import parin.joka.types;

version (LDC) {
    import ldc = ldc.attributes;
    private alias llvmAttr = ldc.llvmAttr;
} else {
    private struct llvmAttr { DStr a, b; }
}

enum Errno : ushort {
    success = 0,
    toobig = 1,
    acces = 2,
    addrinuse = 3,
    addrnotavail = 4,
    afnosupport = 5,
    again = 6,
    already = 7,
    badf = 8,
    badmsg = 9,
    busy = 10,
    canceled = 11,
    child = 12,
    connaborted = 13,
    connrefused = 14,
    connreset = 15,
    deadlk = 16,
    destaddrreq = 17,
    dom = 18,
    dquot = 19,
    exist = 20,
    fault = 21,
    fbig = 22,
    hostunreach = 23,
    idrm = 24,
    ilseq = 25,
    inprogress = 26,
    intr = 27,
    inval = 28,
    io = 29,
    isconn = 30,
    isdir = 31,
    loop = 32,
    mfile = 33,
    mlink = 34,
    msgsize = 35,
    multihop = 36,
    nametoolong = 37,
    netdown = 38,
    netreset = 39,
    netunreach = 40,
    nfile = 41,
    nobufs = 42,
    nodev = 43,
    noent = 44,
    noexec = 45,
    nolck = 46,
    nolink = 47,
    nomem = 48,
    nomsg = 49,
    noprotoopt = 50,
    nospc = 51,
    nosys = 52,
    notconn = 53,
    notdir = 54,
    notempty = 55,
    notrecoverable = 56,
    notsock = 57,
    notsup = 58,
    notty = 59,
    nxio = 60,
    overflow = 61,
    ownerdead = 62,
    perm = 63,
    pipe = 64,
    proto = 65,
    protonosupport = 66,
    prototype = 67,
    range = 68,
    rofs = 69,
    spipe = 70,
    srch = 71,
    stale = 72,
    timedout = 73,
    txtbsy = 74,
    xdev = 75,
    notcapable = 76,
}

enum ClockId : uint {
    realtime = 0,
    monotonic = 1,
    processCputimeId = 2,
    threadCputimeId = 3,
}

enum fdStdin  = Fd(0);
enum fdStdout = Fd(1);
enum fdStderr = Fd(2);

alias LookupFlags = uint;
enum LookupFlag : LookupFlags {
    none          = 0x0,
    symlinkFollow = 0x1,
}

alias OFlags = ushort;
enum OFlag : OFlags {
    none      = 0x0,
    creat     = 0x1,
    directory = 0x2,
    excl      = 0x4,
    trunc     = 0x8,
}

alias Rights = ulong;
enum Right : Rights {
    none                 = 0UL,
    fdDatasync           = 1UL << 0,
    fdRead               = 1UL << 1,
    fdSeek               = 1UL << 2,
    fdFdstatSetFlags     = 1UL << 3,
    fdSync               = 1UL << 4,
    fdTell               = 1UL << 5,
    fdWrite              = 1UL << 6,
    fdAdvise             = 1UL << 7,
    fdAllocate           = 1UL << 8,
    pathCreateDirectory  = 1UL << 9,
    pathCreateFile       = 1UL << 10,
    pathLinkSource       = 1UL << 11,
    pathLinkTarget       = 1UL << 12,
    pathOpen             = 1UL << 13,
    fdReaddir            = 1UL << 14,
    pathReadlink         = 1UL << 15,
    pathRenameSource     = 1UL << 16,
    pathRenameTarget     = 1UL << 17,
    pathFilestatGet      = 1UL << 18,
    pathFilestatSetSize  = 1UL << 19,
    pathFilestatSetTimes = 1UL << 20,
    fdFilestatGet        = 1UL << 21,
    fdFilestatSetSize    = 1UL << 22,
    fdFilestatSetTimes   = 1UL << 23,
    pathSymlink          = 1UL << 24,
    pathRemoveDirectory  = 1UL << 25,
    pathUnlinkFile       = 1UL << 26,
    pollFdReadwrite      = 1UL << 27,
    sockShutdown         = 1UL << 28,
    sockAccept           = 1UL << 29,
}

alias FdFlags = ushort;
enum FdFlag : FdFlags {
    none     = 0x00,
    append   = 0x01,
    dsync    = 0x02,
    nonblock = 0x04,
    rsync    = 0x08,
    sync     = 0x10,
}

alias ExitCode    = uint;
alias Fd          = uint;
alias Iovec       = ForeignSlice!(ubyte);
alias toIovec     = toForeignBytesMut;
alias Ciovec      = ForeignSlice!(const(ubyte));
alias toCiovec    = toForeignBytes;

enum wasi = llvmAttr("wasm-import-module", "wasi_snapshot_preview1");
@safe nothrow @nogc llvmAttr importName(DStr name) => llvmAttr("wasm-import-name", name);

extern(C) nothrow @nogc @wasi {
    @importName("fd_write")
    Errno fdWrite(Fd fd, const(Ciovec)* iovs, Sz iovsLen, Sz* nwritten);

    @importName("fd_read")
    Errno fdRead(Fd fd, Iovec* iovs, Sz iovsLen, Sz* nread);

    @importName("args_sizes_get")
    Errno argsSizesGet(Sz* argc, Sz* argvBufSize);

    @importName("args_get")
    Errno argsGet(ubyte** argv, ubyte* argvBuf);

    @importName("environ_sizes_get")
    Errno environSizesGet(Sz* envCount, Sz* envBufSize);

    @importName("environ_get")
    Errno environGet(ubyte** environ, ubyte* environBuf);

    @importName("clock_time_get")
    Errno clockTimeGet(ClockId clockId, ulong precision, ulong* time);

    @importName("proc_exit")
    void procExit(ExitCode rval);

    @importName("random_get")
    Errno randomGet(ubyte* buf, Sz bufLen);

    @importName("path_open")
    Errno pathOpen(
        Fd fd,
        LookupFlags dirflags,
        const(char)* path,
        Sz pathLen,
        OFlags oflags,
        Rights fsRightsBase,
        Rights fsRightsInheriting,
        FdFlags fdflags,
        Fd* openedFd,
    );

    @importName("fd_close")
    Errno fdClose(Fd fd);
}
