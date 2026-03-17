/// The `wasip1` module provides types and functions available in WASI preview 1.
module parin.joka.wasip1;

import parin.joka.types;

version (LDC) {
    import ldc = ldc.attributes;
    private alias llvmAttr = ldc.llvmAttr;
} else {
    private struct llvmAttr { DStr a, b; }
}

/// Error codes returned by functions.
/// Not all of these error codes are returned by the functions provided by this API;
/// some are used in higher-level library layers, and others are provided merely for alignment with POSIX.
enum Errno : ushort {
    success = 0,      /// No error occurred. System call completed successfully.
    toobig = 1,       /// Argument list too long.
    acces = 2,        /// Permission denied.
    addrinuse = 3,    /// Address in use.
    addrnotavail = 4, /// Address not available.
    afnosupport = 5,  /// Address family not supported.
    again = 6,        /// Resource unavailable, or operation would block.
    already = 7,      /// Connection already in progress.
    badf = 8,         /// Bad file descriptor.
    badmsg = 9,       /// Bad message.
    busy = 10,        /// Device or resource busy.
    canceled = 11,    /// Operation canceled.
    child = 12,       /// No child processes.
    connaborted = 13, /// Connection aborted.
    connrefused = 14, /// Connection refused.
    connreset = 15,   /// Connection reset.
    deadlk = 16,      /// Resource deadlock would occur.
    destaddrreq = 17, /// Destination address required.
    dom = 18,         /// Mathematics argument out of domain of function.
    dquot = 19,       /// Reserved.
    exist = 20,       /// File exists.
    fault = 21,       /// Bad address.
    fbig = 22,        /// File too large.
    hostunreach = 23, /// Host is unreachable.
    idrm = 24,        /// Identifier removed.
    ilseq = 25,       /// Illegal byte sequence.
    inprogress = 26,  /// Operation in progress.
    intr = 27,        /// Interrupted function.
    inval = 28,       /// Invalid argument.
    io = 29,          /// I/O error.
    isconn = 30,      /// Socket is connected.
    isdir = 31,       /// Is a directory.
    loop = 32,        /// Too many levels of symbolic links.
    mfile = 33,       /// File descriptor value too large.
    mlink = 34,       /// Too many links.
    msgsize = 35,     /// Message too large.
    multihop = 36,    /// Reserved.
    nametoolong = 37, /// Filename too long.
    netdown = 38,     /// Network is down.
    netreset = 39,    /// Connection aborted by network.
    netunreach = 40,  /// Network unreachable.
    nfile = 41,       /// Too many files open in system.
    nobufs = 42,      /// No buffer space available.
    nodev = 43,       /// No such device.
    noent = 44,       /// No such file or directory.
    noexec = 45,      /// Executable file format error.
    nolck = 46,       /// No locks available.
    nolink = 47,      /// Reserved.
    nomem = 48,       /// Not enough space.
    nomsg = 49,       /// No message of the desired type.
    noprotoopt = 50,  /// Protocol not available.
    nospc = 51,       /// No space left on device.
    nosys = 52,       /// Function not supported.
    notconn = 53,     /// The socket is not connected.
    notdir = 54,      /// Not a directory or a symbolic link to a directory.
    notempty = 55,    /// Directory not empty.
    notrecoverable = 56, /// State not recoverable.
    notsock = 57,     /// Not a socket.
    notsup = 58,      /// Not supported, or operation not supported on socket.
    notty = 59,       /// Inappropriate I/O control operation.
    nxio = 60,        /// No such device or address.
    overflow = 61,    /// Value too large to be stored in data type.
    ownerdead = 62,   /// Previous owner died.
    perm = 63,        /// Operation not permitted.
    pipe = 64,        /// Broken pipe.
    proto = 65,       /// Protocol error.
    protonosupport = 66, /// Protocol not supported.
    prototype = 67,   /// Protocol wrong type for socket.
    range = 68,       /// Result too large.
    rofs = 69,        /// Read-only file system.
    spipe = 70,       /// Invalid seek.
    srch = 71,        /// No such process.
    stale = 72,       /// Reserved.
    timedout = 73,    /// Connection timed out.
    txtbsy = 74,      /// Text file busy.
    xdev = 75,        /// Cross-device link.
    notcapable = 76,  /// Extension: Capabilities insufficient.
}

/// Identifiers for clocks.
enum ClockId : uint {
    realtime = 0,       /// The clock measuring real time. Time value zero corresponds with 1970-01-01T00:00:00Z.
    monotonic = 1,      /// The store-wide monotonic clock, which is defined as a clock measuring real time, whose value cannot be adjusted and which cannot have negative clock jumps. The epoch of this clock is undefined. The absolute time value of this clock therefore has no meaning.
    processCpuTime = 2, /// The CPU-time clock associated with the current process.
    threadCpuTime = 3,  /// The CPU-time clock associated with the current thread.
}

/// Type of a subscription to an event or its occurrence.
enum EventType : ubyte {
    clock,  /// The time value of clock subscription_clock::id has reached timestamp subscription_clock::timeout.
    fdRead, /// File descriptor subscription_fd_readwrite::file_descriptor has data available for reading. This event always triggers for regular files.
    fdWrite /// File descriptor subscription_fd_readwrite::file_descriptor has capacity available for writing. This event always triggers for regular files.
}

/// The "standard error" descriptor number.
enum stdin  = Fd(0);
/// The "standard input" descriptor number.
enum stdout = Fd(1);
/// The "standard output" descriptor number.
enum stderr = Fd(2);

/// Flags determining the method of how paths are resolved.
alias LookupFlags = uint;
/// Flags determining the method of how paths are resolved.
enum LookupFlag : LookupFlags {
    none          = 0x0, /// None.
    symlinkFollow = 0x1, /// As long as the resolved path corresponds to a symbolic link, it is expanded.
}

/// Open flags used by path_open.
alias OFlags = ushort;
/// Open flags used by path_open.
enum OFlag : OFlags {
    none      = 0x0, /// None.
    creat     = 0x1, /// Create file if it does not exist.
    directory = 0x2, /// Fail if not a directory.
    excl      = 0x4, /// Fail if file already exists.
    trunc     = 0x8, /// Truncate file to size 0.
}

/// File descriptor rights, determining which actions may be performed.
alias Rights = ulong;
/// File descriptor rights, determining which actions may be performed.
enum Right : Rights {
    none                 = 0UL,       /// None.
    fdDataSync           = 1UL << 0,  /// The right to invoke fd_datasync. If path_open is set, includes the right to invoke path_open with FdFlags.dsync.
    fdRead               = 1UL << 1,  /// The right to invoke fdRead and sock_recv. If Rights.fdSeek is set, includes the right to invoke fd_pread.
    fdSeek               = 1UL << 2,  /// The right to invoke fd_seek. This flag implies Rights.fdTell.
    fdFdStatSetFlags     = 1UL << 3,  /// The right to invoke fd_fdstat_set_flags.
    fdSync               = 1UL << 4,  /// The right to invoke fd_sync. If path_open is set, includes the right to invoke path_open with FdFlags.rsync and FdFlags.dsync.
    fdTell               = 1UL << 5,  /// The right to invoke fd_seek in such a way that the file offset remains unaltered (i.e., Whence.cur with offset zero), or to invoke fd_tell.
    fdWrite              = 1UL << 6,  /// The right to invoke fdWrite and sock_send. If Rights.fdSeek is set, includes the right to invoke fd_pwrite.
    fdAdvise             = 1UL << 7,  /// The right to invoke fd_advise.
    fdAllocate           = 1UL << 8,  /// The right to invoke fd_allocate.
    pathCreateDirectory  = 1UL << 9,  /// The right to invoke path_create_directory.
    pathCreateFile       = 1UL << 10, /// If path_open is set, the right to invoke path_open with OFlags.creat.
    pathLinkSource       = 1UL << 11, /// The right to invoke path_link with the file descriptor as the source directory.
    pathLinkTarget       = 1UL << 12, /// The right to invoke path_link with the file descriptor as the target directory.
    pathOpen             = 1UL << 13, /// The right to invoke path_open.
    fdReadDir            = 1UL << 14, /// The right to invoke fdReadDir.
    pathReadLink         = 1UL << 15, /// The right to invoke path_readlink.
    pathRenameSource     = 1UL << 16, /// The right to invoke path_rename with the file descriptor as the source directory.
    pathRenameTarget     = 1UL << 17, /// The right to invoke path_rename with the file descriptor as the target directory.
    pathFileStatGet      = 1UL << 18, /// The right to invoke path_filestat_get.
    pathFileStatSetSize  = 1UL << 19, /// The right to change a file's size. If path_open is set, includes the right to invoke path_open with OFlags.trunc. Note: there is no function named path_filestat_set_size. This follows POSIX design, which only has ftruncate and does not provide ftruncateat. While such function would be desirable from the API design perspective, there are virtually no use cases for it since no code written for POSIX systems would use it.
    pathFileStatSetTimes = 1UL << 20, /// The right to invoke path_filestat_set_times.
    fdFileStatGet        = 1UL << 21, /// The right to invoke fd_filestat_get.
    fdFileStatSetSize    = 1UL << 22, /// The right to invoke fd_filestat_set_size.
    fdFileStatSetTimes   = 1UL << 23, /// The right to invoke fd_filestat_set_times.
    pathSymlink          = 1UL << 24, /// The right to invoke path_symlink.
    pathRemoveDirectory  = 1UL << 25, /// The right to invoke path_remove_directory.
    pathUnlinkFile       = 1UL << 26, /// The right to invoke path_unlink_file.
    pollFdReadwrite      = 1UL << 27, /// If Rights.fdRead is set, includes the right to invoke poll_oneoff to subscribe to EventType.fdRead. If Rights.fdWrite is set, includes the right to invoke poll_oneoff to subscribe to EventType.fdWrite.
    sockShutdown         = 1UL << 28, /// The right to invoke sock_shutdown.
    sockAccept           = 1UL << 29, /// The right to invoke sock_accept.
}

/// File descriptor flags.
alias FdFlags = ushort;
/// File descriptor flags.
enum FdFlag : FdFlags {
    none     = 0x00, /// None.
    append   = 0x01, /// Append mode: Data written to the file is always appended to the file's end.
    dsync    = 0x02, /// Write according to synchronized I/O data integrity completion. Only the data stored in the file is synchronized. This feature is not available on all platforms and therefore path_open and other such functions which accept fdflags may return errno.notsup in the case that this flag is set.
    nonblock = 0x04, /// Non-blocking mode.
    rsync    = 0x08, /// Synchronized read I/O operations. This feature is not available on all platforms and therefore path_open and other such functions which accept fdflags may return errno.notsup in the case that this flag is set.
    sync     = 0x10, /// Write according to synchronized I/O file integrity completion. In addition to synchronizing the data stored in the file, the implementation may also synchronously update the file's metadata. This feature is not available on all platforms and therefore path_open and other such functions which accept fdflags may return errno.notsup in the case that this flag is set.
}

/// Which file time attributes to adjust.
alias FstFlags = ushort;
/// Which file time attributes to adjust.
enum FstFlag : FstFlags {
    none     = 0x0, /// None.
    atime    = 0x1, /// Adjust the last data access timestamp to the value stored in FileStat.atime.
    atimeNow = 0x2, /// Adjust the last data access timestamp to the time of clock clockid::realtime.
    mtime    = 0x4, /// Adjust the last data modification timestamp to the value stored in FileStat.mtime.
    mtimeNow = 0x8, /// Adjust the last data modification timestamp to the time of clock clockid::realtime.
}

/// File or memory access pattern advisory information.
enum Advice : ubyte {
    normal     = 0, /// The application has no advice to give on its behavior with respect to the specified data.
    sequential = 1, /// The application expects to access the specified data sequentially from lower offsets to higher offsets.
    random     = 2, /// The application expects to access the specified data in a random order.
    willneed   = 3, /// The application expects to access the specified data in the near future.
    dontneed   = 4, /// The application expects that it will not access the specified data in the near future.
    noreuse    = 5, /// The application expects to access the specified data once and then not reuse it thereafter.
}

/// The type of a file descriptor or file.
enum FileType : ubyte {
    unknown         = 0, /// The type of the file descriptor or file is unknown or is different from any of the other types specified.
    blockDevice     = 1, /// The file descriptor or file refers to a block device inode.
    characterDevice = 2, /// The file descriptor or file refers to a character device inode.
    directory       = 3, /// The file descriptor or file refers to a directory inode.
    regularFile     = 4, /// The file descriptor or file refers to a regular file inode.
    socketDgram     = 5, /// The file descriptor or file refers to a datagram socket.
    socketStream    = 6, /// The file descriptor or file refers to a byte-stream socket.
    symbolicLink    = 7, /// The file refers to a symbolic link inode.
}

/// The position relative to which to set the offset of the file descriptor.
enum Whence : ubyte {
    set = 0, /// Seek relative to start-of-file.
    cur = 1, /// Seek relative to current position.
    end = 2, /// Seek relative to end-of-file.
}

/// The contents of a $prestat when type is preopentype::dir.
struct PrestatDir {
    Size nameLen; /// The length of the directory name for use with fdPrestatDirName.
}

/// Information about a pre-opened capability.
alias Prestat = Union!(PrestatDir);
static if ((void*).sizeof == 4) {
    static assert(Prestat.sizeof == 8 && Prestat.alignof == 4);
}

/// File descriptor attributes.
struct FdStat {
    FileType type;           /// File type.
    FdFlags flags;           /// File descriptor flags.
    Rights rightsBase;       /// Rights that apply to this file descriptor.
    Rights rightsInheriting; /// Maximum set of rights that may be installed on new file descriptors that are created through this file descriptor, e.g., through path_open.
}

/// File attributes.
struct FileStat {
    Device dev;      /// Device ID of device containing the file.
    Inode ino;       /// File serial number.
    FileType type;   /// File type.
    LinkCount nlink; /// Number of hard links to the file.
    FileSize size;   /// For regular files, the file size in bytes. For symbolic links, the length in bytes of the pathname contained in the symbolic link.
    TimeStamp atime; /// Last data access timestamp.
    TimeStamp mtime; /// Last data modification timestamp.
    TimeStamp ctime; /// Last file status change timestamp.
}

// NOTE: The `Size` type is a U32 in the docs.
/// A size value in bytes.
alias Size = size_t;
/// Number of hard links to an inode.
alias LinkCount = ulong;
/// File serial number that is unique within its file system.
alias Inode = ulong;
/// Identifier for a device containing a file system. Can be used in combination with inode to uniquely identify a file or directory in the filesystem.
alias Device = ulong;
/// A reference to the offset of a directory entry. The value 0 signifies the start of the directory.
alias DirCookie = ulong;
/// Non-negative file size or length of a region within a file.
alias FileSize = ulong;
/// Relative offset within a file.
alias FileDelta = ulong;
/// Exit code generated by a process when exiting.
alias ExitCode  = uint;
/// A file descriptor handle.
alias Fd = uint;
/// Timestamp in nanoseconds.
alias TimeStamp = ulong;
/// A region of memory for scatter/gather reads.
alias Iovec = ForeignSlice!(ubyte);
/// A region of memory for scatter/gather writes.
alias Ciovec = ForeignSlice!(const(ubyte));
/// Convert a string to a `Iovec`.
alias toIovec = toForeignBytesMut;
/// Convert a string to a `Ciovec`.
alias toCiovec = toForeignBytes;

/// The WASI Preview 1 module import.
enum wasi = llvmAttr("wasm-import-module", "wasi_snapshot_preview1");
/// The WASI Preview 1 name import.
auto importName(DStr name) => llvmAttr("wasm-import-name", name);

// NOTE: The order of the functions in this block are based on: https://chicory.dev/docs/usage/wasi/#supported-features
extern(C) nothrow @nogc @wasi {
    /// Read command-line argument data.
    /// The size of the array should match that returned by args_sizes_get.
    /// Each argument is expected to be \0 terminated.
    @importName("args_get")
    Errno argsGet(ubyte** argv, ubyte* argvBuf);

    /// Return command-line argument data sizes.
    @importName("args_sizes_get")
    Errno argsSizesGet(Size* argc, Size* argvBufSize);

    /// Return the resolution of a clock.
    /// Implementations are required to provide a non-zero value for supported clocks.
    /// For unsupported clocks, return errno::inval.
    /// Note: This is similar to clock_getres in POSIX.
    @importName("clock_res_get")
    Errno clockResGet(ClockId clockId, TimeStamp* time);

    /// Return the time value of a clock.
    /// Note: This is similar to clock_gettime in POSIX.
    @importName("clock_time_get")
    Errno clockTimeGet(ClockId clockId, TimeStamp precision, TimeStamp* time);

    /// Read environment variable data.
    /// The sizes of the buffers should match that returned by environ_sizes_get.
    /// Key/value pairs are expected to be joined with =s, and terminated with \0s.
    @importName("environ_get")
    Errno environGet(ubyte** environ, ubyte* environBuf);

    /// Return environment variable data sizes.
    @importName("environ_sizes_get")
    Errno environSizesGet(Size* envCount, Size* envBufSize);

    /// Provide file advisory information on a file descriptor.
    /// Note: This is similar to posix_fadvise in POSIX.
    @importName("fd_advise")
    Errno fdAdvise(Fd fd, FileSize offset, FileSize len, Advice advice);

    /// Force the allocation of space in a file.
    /// Note: This is similar to posix_fallocate in POSIX.
    @importName("fd_allocate")
    Errno fdAllocate(Fd fd, FileSize offset, FileSize len);

    /// Close a file descriptor.
    /// Note: This is similar to close in POSIX.
    @importName("fd_close")
    Errno fdClose(Fd fd);

    /// Synchronize the data of a file to disk.
    /// Note: This is similar to fdatasync in POSIX.
    @importName("fd_datasync")
    Errno fdDataSync(Fd fd);

    /// Get the attributes of a file descriptor.
    /// Note: This returns similar flags to fcntl(fd, F_GETFL) in POSIX, as well as additional fields.
    @importName("fd_fdstat_get")
    Errno fdFdStatGet(Fd fd, FdStat* fdStat);

    /// Adjust the flags associated with a file descriptor.
    /// Note: This is similar to fcntl(fd, F_SETFL, flags) in POSIX.
    @importName("fd_fdstat_set_flags")
    Errno fdFdStatSetFlags(Fd fd, FdFlags flags);

    /// Adjust the rights associated with a file descriptor.
    /// This can only be used to remove rights, and returns errno::notcapable if called in a way that would attempt to add rights.
    @importName("fd_fdstat_set_rights")
    Errno fdFdStatSetRights(Fd fd, Rights rightsBase, Rights rightsInheriting);

    /// Return the attributes of an open file.
    @importName("fd_filestat_get")
    Errno fdFileStatGet(Fd fd, FileStat* fileStat);

    /// Adjust the size of an open file.
    /// If this increases the file's size, the extra bytes are filled with zeros.
    /// Note: This is similar to ftruncate in POSIX.
    @importName("fd_filestat_set_size")
    Errno fdFileStatSetSize(Fd fd, FileSize size);

    /// Adjust the timestamps of an open file or directory.
    /// Note: This is similar to futimens in POSIX.
    @importName("fd_filestat_set_times")
    Errno fdFileStatSetTimes(Fd fd, TimeStamp atime, TimeStamp mtime, FstFlags fstFlags);

    /// Read from a file descriptor, without using and updating the file descriptor's offset.
    /// Note: This is similar to preadv in Linux (and other Unix-es).
    @importName("fd_pread")
    Errno fdPread(Fd fd, Iovec* iovs, Size iovsLen, FileSize offset, Size* outSize);

    /// Return a description of the given preopened file descriptor.
    @importName("fd_prestat_dir_name")
    Errno fdPrestatDirName(Fd fd, ubyte* path, Size pathLen);

    /// Return a description of the given preopened file descriptor.
    @importName("fd_prestat_get")
    Errno fdPrestatGet(Fd fd, Prestat* outPrestat);

    /// Write to a file descriptor, without using and updating the file descriptor's offset.
    /// Note: This is similar to pwritev in Linux (and other Unix-es).
    /// Like Linux (and other Unix-es), any calls of pwrite (and other functions to read or write)
    /// for a regular file by other threads in the WASI process should not be interleaved while pwrite is executed.
    @importName("fd_pwrite")
    Errno fdPwrite(Fd fd, const(Ciovec)* iovs, Size iovsLen, FileSize offset, Size* outSize);

    /// Read from a file descriptor.
    /// Note: This is similar to readv in POSIX.
    @importName("fd_read")
    Errno fdRead(Fd fd, Iovec* iovs, Size iovsLen, Size* nread);

    /// Read directory entries from a directory.
    /// When successful, the contents of the output buffer consist of a sequence of directory entries.
    /// Each directory entry consists of a dirent object, followed by dirent::d_namlen bytes holding the name of the directory entry.
    /// This function fills the output buffer as much as possible, potentially truncating the last directory entry.
    /// This allows the caller to grow its read buffer size in case it's too small to fit a single large directory entry, or skip the oversized directory entry.
    @importName("fd_readdir")
    Errno fdReadDir(Fd fd, ubyte* buf, Size bufLen, DirCookie cookie, Size* nread);

    /// Atomically replace a file descriptor by renumbering another file descriptor.
    /// Due to the strong focus on thread safety, this environment does not provide a mechanism to duplicate or renumber a file descriptor to an arbitrary number, like dup2().
    /// This would be prone to race conditions, as an actual file descriptor with the same number could be allocated by a different thread at the same time.
    /// This function provides a way to atomically renumber file descriptors, which would disappear if dup2() were to be removed entirely.
    @importName("fd_renumber")
    Errno fdRenumber(Fd fd, Fd to);

    /// Move the offset of a file descriptor.
    /// Note: This is similar to lseek in POSIX.
    @importName("fd_seek")
    Errno fdSeek(Fd fd, FileDelta offset, Whence whence, FileSize* outOffset);

    /// Synchronize the data and metadata of a file to disk.
    /// Note: This is similar to fsync in POSIX.
    @importName("fd_sync")
    Errno fdSync(Fd fd);

    /// Return the current offset of a file descriptor.
    /// Note: This is similar to lseek(fd, 0, SEEK_CUR) in POSIX.
    @importName("fd_tell")
    Errno fdTell(Fd fd, FileSize* outOffset);

    /// Write to a file descriptor. Note: This is similar to writev in POSIX.
    /// Like POSIX, any calls of write (and other functions to read or write) for a regular file
    /// by other threads in the WASI process should not be interleaved while write is executed.
    @importName("fd_write")
    Errno fdWrite(Fd fd, const(Ciovec)* iovs, Size iovsLen, Size* nwritten);

    /// Open a file or directory.
    /// The returned file descriptor is not guaranteed to be the lowest-numbered file descriptor not currently open;
    /// it is randomized to prevent applications from depending on making assumptions about indexes,
    /// since this is error-prone in multi-threaded contexts.
    /// The returned file descriptor is guaranteed to be less than 2**31.
    /// Note: This is similar to openat in POSIX.
    @importName("path_open")
    Errno pathOpen(
        Fd fd,
        LookupFlags dirFlags,
        const(char)* path,
        Size pathLen,
        OFlags oFlags,
        Rights rightsBase,
        Rights rightsInheriting,
        FdFlags fdFlags,
        Fd* openedFd,
    );

    /// Terminate the process normally.
    /// An exit code of 0 indicates successful termination of the program.
    /// The meanings of other values is dependent on the environment.
    @importName("proc_exit")
    void procExit(ExitCode code);

    /// Write high-quality random data into a buffer.
    /// This function blocks when the implementation is unable to immediately provide sufficient high-quality random data.
    @importName("random_get")
    Errno randomGet(ubyte* buf, Size bufLen);
}
