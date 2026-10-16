/// This example shows how to use Parin with ENet.
/// Run it many times. The first window becomes the server and the others connect to it.
/// Every window is a player that moves with WASD or the arrow keys.
/// Clients send their position to the server and the server sends the positions of all players back.
/// Repository: https://github.com/lsalzman/enet

import parin;
import parin.bindings.enet;

ENetHost* host;
ENetPeer* server; // The connection to the server. Only used by clients.
auto isServer = false;
auto player = Vec2();
auto state = State();

immutable Rgba[maxPlayers] colors = [pink, cyan, yellow, green, orange, magenta, white, red];

enum port = 7777;
enum maxPlayers = 8; // The server and 7 clients.

/// The game state that the server sends to every client.
/// Slot 0 is the server and the clients use the slots after it.
struct State {
    int yourId;
    bool[maxPlayers] isActive;
    Vec2[maxPlayers] positions;
}

void ready() {
    lockResolution(320, 180);
    randomize();
    player = Vec2(32 + randf * 240, 32 + randf * 100);
    enet_initialize();
    // Try to become the server. If the port is already used, connect to the server instead.
    auto address = ENetAddress(ENET_HOST_ANY, port);
    host = enet_host_create(&address, maxPlayers - 1, 1, 0, 0);
    isServer = host != null;
    if (isServer) {
        state.isActive[0] = true;
    } else {
        host = enet_host_create(null, 1, 1, 0, 0);
        enet_address_set_host(&address, "localhost");
        server = enet_host_connect(host, &address, 1, 0);
    }
    setWindowTitle(isServer ? "Server" : "Client");
}

void updateServer() {
    // Handle the network events. A client uses the slot after its index in the peer array.
    ENetEvent event;
    while (enet_host_service(host, &event, 0) > 0) {
        auto id = cast(int) (event.peer - host.peers) + 1;
        if (event.type == ENET_EVENT_TYPE_CONNECT) {
            state.isActive[id] = true;
        } else if (event.type == ENET_EVENT_TYPE_DISCONNECT) {
            state.isActive[id] = false;
        } else if (event.type == ENET_EVENT_TYPE_RECEIVE) {
            if (event.packet.dataLength == Vec2.sizeof) state.positions[id] = *(cast(Vec2*) event.packet.data);
            enet_packet_destroy(event.packet);
        }
    }
    // Send the state to every connected client.
    state.positions[0] = player;
    foreach (i; 0 .. host.peerCount) {
        auto peer = &host.peers[i];
        if (peer.state != ENET_PEER_STATE_CONNECTED) continue;
        auto clientState = state;
        clientState.yourId = cast(int) i + 1;
        enet_peer_send(peer, 0, enet_packet_create(&clientState, State.sizeof, 0));
    }
}

void updateClient() {
    // Handle the network events.
    ENetEvent event;
    while (enet_host_service(host, &event, 0) > 0) {
        if (event.type == ENET_EVENT_TYPE_DISCONNECT) {
            server = null;
            state = State(state.yourId);
        } else if (event.type == ENET_EVENT_TYPE_RECEIVE) {
            if (event.packet.dataLength == State.sizeof) state = *(cast(State*) event.packet.data);
            enet_packet_destroy(event.packet);
        }
    }
    // Send the position of the player. Unreliable packets are fine for data sent every frame.
    if (server && server.state == ENET_PEER_STATE_CONNECTED) {
        enet_peer_send(server, 0, enet_packet_create(&player, Vec2.sizeof, 0));
    }
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Move the player and update the network.
    player += wasd * 120 * dt;
    if (isServer) updateServer();
    else updateClient();
    // Draw the other players and then the player.
    auto playerCount = 0;
    foreach (id, isActive; state.isActive) {
        if (!isActive) continue;
        playerCount += 1;
        if (id != state.yourId) drawRect(Rect(state.positions[id], Vec2(16)), colors[id]);
    }
    drawRect(Rect(player, Vec2(16)), colors[state.yourId]);
    // Draw the info.
    auto info = "Server";
    if (!isServer) info = server ? (playerCount ? "Client" : "Connecting...") : "Disconnected";
    drawText("{}\nPlayers: {}".fmt(info, playerCount), Vec2(8));
    return false;
}

void finish() {
    // Tell the others that we are leaving.
    foreach (i; 0 .. host.peerCount) enet_peer_disconnect_now(&host.peers[i], 0);
    enet_host_destroy(host);
    enet_deinitialize();
}

mixin runGame!(ready, update, finish);
