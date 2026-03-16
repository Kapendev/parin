/// The `p1` module provides functions available in WASI preview 1.
module parin.joka.wasi.p1;

import parin.joka.types;

version (LDC) {
    import ldc = ldc.attributes;
    private alias llvmAttr = ldc.llvmAttr;
} else {
    private struct llvmAttr { DStr a, b; }
}

enum Fd : uint {
    input  = 0,
    output = 1,
    error  = 2,
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

alias Iovec  = ForeignSlice!(ubyte);
alias Ciovec = ForeignSlice!(const(ubyte));

alias toCiovec = toForeignBytes;

enum wasi = llvmAttr("wasm-import-module", "wasi_snapshot_preview1");
@safe nothrow @nogc llvmAttr importName(DStr name) => llvmAttr("wasm-import-name", name);

extern(C) nothrow @nogc @wasi {
    @importName("fd_write")
    Errno fd_write(Fd fd, const(Ciovec)* iovs, Sz iovs_len, Sz* nwritten);

    @importName("fd_read")
    Errno fd_read(Fd fd, const(Ciovec)* iovs, Sz iovs_len, Sz* nread);

    @importName("args_sizes_get")
    Errno args_sizes_get(Sz* argc, Sz* argv_buf_size);

    @importName("args_get")
    Errno args_get(ubyte** argv, ubyte* argv_buf);

    @importName("environ_sizes_get")
    Errno environ_sizes_get(Sz* env_count, Sz* env_buf_size);

    @importName("environ_get")
    Errno environ_get(ubyte** environ, ubyte* environ_buf);

    @importName("clock_time_get")
    Errno clock_time_get(uint clock_id, ulong precision, ulong* time);

    @importName("proc_exit")
    void proc_exit(uint rval);
}
