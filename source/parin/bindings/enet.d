// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `enet` module provides access to the ENet networking library.
/// These bindings match the ENet v1.3.18 release.
/// The low level socket functions (`enet_socket_*`) are not included.
module parin.bindings.enet;

extern(C) @system nothrow @nogc:

alias enet_uint8 = ubyte;
alias enet_uint16 = ushort;
alias enet_uint32 = uint;
alias ENetVersion = enet_uint32;

version (Windows) {
    alias ENetSocket = size_t;
    enum ENetSocket ENET_SOCKET_NULL = ~cast(size_t) 0;
} else {
    alias ENetSocket = int;
    enum ENetSocket ENET_SOCKET_NULL = -1;
}

enum ENET_VERSION_MAJOR = 1;
enum ENET_VERSION_MINOR = 3;
enum ENET_VERSION_PATCH = 18;
enum ENetVersion ENET_VERSION = (ENET_VERSION_MAJOR << 16) | (ENET_VERSION_MINOR << 8) | ENET_VERSION_PATCH;

enum enet_uint32 ENET_HOST_ANY       = 0;
enum enet_uint32 ENET_HOST_BROADCAST = 0xFFFFFFFF;
enum enet_uint16 ENET_PORT_ANY       = 0;

alias ENetSocketType = int;
alias ENetSocketWait = int;
alias ENetSocketOption = int;
alias ENetSocketShutdown = int;
alias ENetPacketFlag = int;
alias ENetPeerState = int;
alias ENetPeerFlag = int;
alias ENetEventType = int;

enum : ENetSocketType {
    ENET_SOCKET_TYPE_STREAM   = 1,
    ENET_SOCKET_TYPE_DATAGRAM = 2,
}

enum : ENetSocketWait {
    ENET_SOCKET_WAIT_NONE      = 0,
    ENET_SOCKET_WAIT_SEND      = 1 << 0,
    ENET_SOCKET_WAIT_RECEIVE   = 1 << 1,
    ENET_SOCKET_WAIT_INTERRUPT = 1 << 2,
}

enum : ENetSocketOption {
    ENET_SOCKOPT_NONBLOCK  = 1,
    ENET_SOCKOPT_BROADCAST = 2,
    ENET_SOCKOPT_RCVBUF    = 3,
    ENET_SOCKOPT_SNDBUF    = 4,
    ENET_SOCKOPT_REUSEADDR = 5,
    ENET_SOCKOPT_RCVTIMEO  = 6,
    ENET_SOCKOPT_SNDTIMEO  = 7,
    ENET_SOCKOPT_ERROR     = 8,
    ENET_SOCKOPT_NODELAY   = 9,
    ENET_SOCKOPT_TTL       = 10,
}

enum : ENetSocketShutdown {
    ENET_SOCKET_SHUTDOWN_READ       = 0,
    ENET_SOCKET_SHUTDOWN_WRITE      = 1,
    ENET_SOCKET_SHUTDOWN_READ_WRITE = 2,
}

enum : ENetPacketFlag {
    ENET_PACKET_FLAG_RELIABLE           = 1 << 0,
    ENET_PACKET_FLAG_UNSEQUENCED        = 1 << 1,
    ENET_PACKET_FLAG_NO_ALLOCATE        = 1 << 2,
    ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT = 1 << 3,
    ENET_PACKET_FLAG_SENT               = 1 << 8,
}

enum : ENetPeerState {
    ENET_PEER_STATE_DISCONNECTED             = 0,
    ENET_PEER_STATE_CONNECTING               = 1,
    ENET_PEER_STATE_ACKNOWLEDGING_CONNECT    = 2,
    ENET_PEER_STATE_CONNECTION_PENDING       = 3,
    ENET_PEER_STATE_CONNECTION_SUCCEEDED     = 4,
    ENET_PEER_STATE_CONNECTED                = 5,
    ENET_PEER_STATE_DISCONNECT_LATER         = 6,
    ENET_PEER_STATE_DISCONNECTING            = 7,
    ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT = 8,
    ENET_PEER_STATE_ZOMBIE                   = 9,
}

enum : ENetPeerFlag {
    ENET_PEER_FLAG_NEEDS_DISPATCH   = 1 << 0,
    ENET_PEER_FLAG_CONTINUE_SENDING = 1 << 1,
}

enum : ENetEventType {
    ENET_EVENT_TYPE_NONE       = 0,
    ENET_EVENT_TYPE_CONNECT    = 1,
    ENET_EVENT_TYPE_DISCONNECT = 2,
    ENET_EVENT_TYPE_RECEIVE    = 3,
}

enum {
    ENET_PROTOCOL_MINIMUM_MTU             = 576,
    ENET_PROTOCOL_MAXIMUM_MTU             = 4096,
    ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS = 32,
    ENET_PROTOCOL_MINIMUM_WINDOW_SIZE     = 4096,
    ENET_PROTOCOL_MAXIMUM_WINDOW_SIZE     = 65536,
    ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT   = 1,
    ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT   = 255,
    ENET_PROTOCOL_MAXIMUM_PEER_ID         = 0xFFF,
    ENET_PROTOCOL_MAXIMUM_FRAGMENT_COUNT  = 1024 * 1024,
}

enum {
    ENET_HOST_RECEIVE_BUFFER_SIZE          = 256 * 1024,
    ENET_HOST_SEND_BUFFER_SIZE             = 256 * 1024,
    ENET_HOST_BANDWIDTH_THROTTLE_INTERVAL  = 1000,
    ENET_HOST_DEFAULT_MTU                  = 1392,
    ENET_HOST_DEFAULT_MAXIMUM_PACKET_SIZE  = 32 * 1024 * 1024,
    ENET_HOST_DEFAULT_MAXIMUM_WAITING_DATA = 32 * 1024 * 1024,
    ENET_PEER_DEFAULT_ROUND_TRIP_TIME      = 500,
    ENET_PEER_DEFAULT_PACKET_THROTTLE      = 32,
    ENET_PEER_PACKET_THROTTLE_SCALE        = 32,
    ENET_PEER_PACKET_THROTTLE_COUNTER      = 7,
    ENET_PEER_PACKET_THROTTLE_ACCELERATION = 2,
    ENET_PEER_PACKET_THROTTLE_DECELERATION = 2,
    ENET_PEER_PACKET_THROTTLE_INTERVAL     = 5000,
    ENET_PEER_PACKET_LOSS_SCALE            = 1 << 16,
    ENET_PEER_PACKET_LOSS_INTERVAL         = 10000,
    ENET_PEER_WINDOW_SIZE_SCALE            = 64 * 1024,
    ENET_PEER_TIMEOUT_LIMIT                = 32,
    ENET_PEER_TIMEOUT_MINIMUM              = 5000,
    ENET_PEER_TIMEOUT_MAXIMUM              = 30000,
    ENET_PEER_PING_INTERVAL                = 500,
    ENET_PEER_UNSEQUENCED_WINDOWS          = 64,
    ENET_PEER_UNSEQUENCED_WINDOW_SIZE      = 1024,
    ENET_PEER_FREE_UNSEQUENCED_WINDOWS     = 32,
    ENET_PEER_RELIABLE_WINDOWS             = 16,
    ENET_PEER_RELIABLE_WINDOW_SIZE         = 0x1000,
    ENET_PEER_FREE_RELIABLE_WINDOWS        = 8,
}

enum ENET_BUFFER_MAXIMUM = 1 + 2 * ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS;

alias ENetPacketFreeCallback = void function(ENetPacket* packet);
alias ENetChecksumCallback = enet_uint32 function(const(ENetBuffer)* buffers, size_t bufferCount);
alias ENetInterceptCallback = int function(ENetHost* host, ENetEvent* event);

struct ENetAddress {
    enet_uint32 host;
    enet_uint16 port;
}

version (Windows) {
    struct ENetBuffer {
        size_t dataLength;
        void* data;
    }
} else {
    struct ENetBuffer {
        void* data;
        size_t dataLength;
    }
}

struct ENetListNode {
    ENetListNode* next;
    ENetListNode* previous;
}

struct ENetList {
    ENetListNode sentinel;
}

struct ENetCallbacks {
    void* function(size_t size) malloc;
    void function(void* memory) free;
    void function() no_memory;
}

struct ENetPacket {
    size_t referenceCount;
    enet_uint32 flags;
    enet_uint8* data;
    size_t dataLength;
    ENetPacketFreeCallback freeCallback;
    void* userData;
}

/// A packed protocol command. Only used internally, so its contents are not exposed.
struct ENetProtocol {
    enet_uint8[48] data;
}

struct ENetChannel {
    enet_uint16 outgoingReliableSequenceNumber;
    enet_uint16 outgoingUnreliableSequenceNumber;
    enet_uint16 usedReliableWindows;
    enet_uint16[ENET_PEER_RELIABLE_WINDOWS] reliableWindows;
    enet_uint16 incomingReliableSequenceNumber;
    enet_uint16 incomingUnreliableSequenceNumber;
    ENetList incomingReliableCommands;
    ENetList incomingUnreliableCommands;
}

struct ENetPeer {
    ENetListNode dispatchList;
    ENetHost* host;
    enet_uint16 outgoingPeerID;
    enet_uint16 incomingPeerID;
    enet_uint32 connectID;
    enet_uint8 outgoingSessionID;
    enet_uint8 incomingSessionID;
    ENetAddress address;
    void* data;
    ENetPeerState state;
    ENetChannel* channels;
    size_t channelCount;
    enet_uint32 incomingBandwidth;
    enet_uint32 outgoingBandwidth;
    enet_uint32 incomingBandwidthThrottleEpoch;
    enet_uint32 outgoingBandwidthThrottleEpoch;
    enet_uint32 incomingDataTotal;
    enet_uint32 outgoingDataTotal;
    enet_uint32 lastSendTime;
    enet_uint32 lastReceiveTime;
    enet_uint32 nextTimeout;
    enet_uint32 earliestTimeout;
    enet_uint32 packetLossEpoch;
    enet_uint32 packetsSent;
    enet_uint32 packetsLost;
    enet_uint32 packetLoss;
    enet_uint32 packetLossVariance;
    enet_uint32 packetThrottle;
    enet_uint32 packetThrottleLimit;
    enet_uint32 packetThrottleCounter;
    enet_uint32 packetThrottleEpoch;
    enet_uint32 packetThrottleAcceleration;
    enet_uint32 packetThrottleDeceleration;
    enet_uint32 packetThrottleInterval;
    enet_uint32 pingInterval;
    enet_uint32 timeoutLimit;
    enet_uint32 timeoutMinimum;
    enet_uint32 timeoutMaximum;
    enet_uint32 lastRoundTripTime;
    enet_uint32 lowestRoundTripTime;
    enet_uint32 lastRoundTripTimeVariance;
    enet_uint32 highestRoundTripTimeVariance;
    enet_uint32 roundTripTime;
    enet_uint32 roundTripTimeVariance;
    enet_uint32 mtu;
    enet_uint32 windowSize;
    enet_uint32 reliableDataInTransit;
    enet_uint16 outgoingReliableSequenceNumber;
    ENetList acknowledgements;
    ENetList sentReliableCommands;
    ENetList outgoingSendReliableCommands;
    ENetList outgoingCommands;
    ENetList dispatchedCommands;
    enet_uint16 flags;
    enet_uint16 reserved;
    enet_uint16 incomingUnsequencedGroup;
    enet_uint16 outgoingUnsequencedGroup;
    enet_uint32[ENET_PEER_UNSEQUENCED_WINDOW_SIZE / 32] unsequencedWindow;
    enet_uint32 eventData;
    size_t totalWaitingData;
}

struct ENetCompressor {
    void* context;
    size_t function(void* context, const(ENetBuffer)* inBuffers, size_t inBufferCount, size_t inLimit, enet_uint8* outData, size_t outLimit) compress;
    size_t function(void* context, const(enet_uint8)* inData, size_t inLimit, enet_uint8* outData, size_t outLimit) decompress;
    void function(void* context) destroy;
}

struct ENetHost {
    ENetSocket socket;
    ENetAddress address;
    enet_uint32 incomingBandwidth;
    enet_uint32 outgoingBandwidth;
    enet_uint32 bandwidthThrottleEpoch;
    enet_uint32 mtu;
    enet_uint32 randomSeed;
    int recalculateBandwidthLimits;
    ENetPeer* peers;
    size_t peerCount;
    size_t channelLimit;
    enet_uint32 serviceTime;
    ENetList dispatchQueue;
    enet_uint32 totalQueued;
    size_t packetSize;
    enet_uint16 headerFlags;
    ENetProtocol[ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS] commands;
    size_t commandCount;
    ENetBuffer[ENET_BUFFER_MAXIMUM] buffers;
    size_t bufferCount;
    ENetChecksumCallback checksum;
    ENetCompressor compressor;
    enet_uint8[ENET_PROTOCOL_MAXIMUM_MTU][2] packetData;
    ENetAddress receivedAddress;
    enet_uint8* receivedData;
    size_t receivedDataLength;
    enet_uint32 totalSentData;
    enet_uint32 totalSentPackets;
    enet_uint32 totalReceivedData;
    enet_uint32 totalReceivedPackets;
    ENetInterceptCallback intercept;
    size_t connectedPeers;
    size_t bandwidthLimitedPeers;
    size_t duplicatePeers;
    size_t maximumPacketSize;
    size_t maximumWaitingData;
}

struct ENetEvent {
    ENetEventType type;
    ENetPeer* peer;
    enet_uint8 channelID;
    enet_uint32 data;
    ENetPacket* packet;
}

// Global
int enet_initialize();
int enet_initialize_with_callbacks(ENetVersion version_, const(ENetCallbacks)* inits);
void enet_deinitialize();
ENetVersion enet_linked_version();
enet_uint32 enet_time_get();
void enet_time_set(enet_uint32 newTimeBase);

// Address
int enet_address_set_host_ip(ENetAddress* address, const(char)* hostName);
int enet_address_set_host(ENetAddress* address, const(char)* hostName);
int enet_address_get_host_ip(const(ENetAddress)* address, char* hostName, size_t nameLength);
int enet_address_get_host(const(ENetAddress)* address, char* hostName, size_t nameLength);

// Packet
ENetPacket* enet_packet_create(const(void)* data, size_t dataLength, enet_uint32 flags);
void enet_packet_destroy(ENetPacket* packet);
int enet_packet_resize(ENetPacket* packet, size_t dataLength);
enet_uint32 enet_crc32(const(ENetBuffer)* buffers, size_t bufferCount);

// Host
ENetHost* enet_host_create(const(ENetAddress)* address, size_t peerCount, size_t channelLimit, enet_uint32 incomingBandwidth, enet_uint32 outgoingBandwidth);
void enet_host_destroy(ENetHost* host);
ENetPeer* enet_host_connect(ENetHost* host, const(ENetAddress)* address, size_t channelCount, enet_uint32 data);
int enet_host_check_events(ENetHost* host, ENetEvent* event);
int enet_host_service(ENetHost* host, ENetEvent* event, enet_uint32 timeout);
void enet_host_flush(ENetHost* host);
void enet_host_broadcast(ENetHost* host, enet_uint8 channelID, ENetPacket* packet);
void enet_host_compress(ENetHost* host, const(ENetCompressor)* compressor);
int enet_host_compress_with_range_coder(ENetHost* host);
void enet_host_channel_limit(ENetHost* host, size_t channelLimit);
void enet_host_bandwidth_limit(ENetHost* host, enet_uint32 incomingBandwidth, enet_uint32 outgoingBandwidth);

// Peer
int enet_peer_send(ENetPeer* peer, enet_uint8 channelID, ENetPacket* packet);
ENetPacket* enet_peer_receive(ENetPeer* peer, enet_uint8* channelID);
void enet_peer_ping(ENetPeer* peer);
void enet_peer_ping_interval(ENetPeer* peer, enet_uint32 pingInterval);
void enet_peer_timeout(ENetPeer* peer, enet_uint32 timeoutLimit, enet_uint32 timeoutMinimum, enet_uint32 timeoutMaximum);
void enet_peer_reset(ENetPeer* peer);
void enet_peer_disconnect(ENetPeer* peer, enet_uint32 data);
void enet_peer_disconnect_now(ENetPeer* peer, enet_uint32 data);
void enet_peer_disconnect_later(ENetPeer* peer, enet_uint32 data);
void enet_peer_throttle_configure(ENetPeer* peer, enet_uint32 interval, enet_uint32 acceleration, enet_uint32 deceleration);

// Range coder
void* enet_range_coder_create();
void enet_range_coder_destroy(void* context);
size_t enet_range_coder_compress(void* context, const(ENetBuffer)* inBuffers, size_t inBufferCount, size_t inLimit, enet_uint8* outData, size_t outLimit);
size_t enet_range_coder_decompress(void* context, const(enet_uint8)* inData, size_t inLimit, enet_uint8* outData, size_t outLimit);
