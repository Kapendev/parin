/// This example shows how to use Parin with Steamworks.
/// It uses Spacewar (App ID 480), the test app of Valve, so it needs the Steam client running.
/// Put a `steam_appid.txt` file containing `480` next to the executable,
/// and link the `steam_api` library from the Steamworks SDK.
/// Website: https://partner.steamgames.com/doc/sdk

import parin;
import parin.bindings.steam;

auto isReady = false;
auto hasStats = false;
auto leaderboardEntryCount = -1;
auto pipe = HSteamPipe();
auto leaderboardCall = SteamAPICall_t();
SteamErrMsg errorMessage;

enum achievement = "ACH_WIN_ONE_GAME";
enum leaderboard = "Feet Traveled";

void ready() {
    lockResolution(320, 180);
    // Start Steam and check that it supports the interfaces of the binding.
    if (SteamInternal_SteamAPI_Init(steamInterfaceVersions.ptr, &errorMessage) != k_ESteamAPIInitResult_OK) return;
    SteamAPI_ManualDispatch_Init();
    pipe = SteamAPI_GetHSteamPipe();
    isReady = true;
    // Ask for a leaderboard. The result arrives later as a call result.
    leaderboardCall = SteamAPI_ISteamUserStats_FindLeaderboard(SteamAPI_SteamUserStats(), leaderboard);
}

void handleCallbacks() {
    SteamAPI_ManualDispatch_RunFrame(pipe);
    CallbackMsg_t message;
    while (SteamAPI_ManualDispatch_GetNextCallback(pipe, &message)) {
        if (message.m_iCallback == UserStatsReceived_t.k_iCallback) {
            auto received = cast(UserStatsReceived_t*) message.m_pubParam;
            hasStats = received.m_eResult == k_EResultOK;
        } else if (message.m_iCallback == SteamAPICallCompleted_t.k_iCallback) {
            // Read the result of an async call.
            auto call = cast(SteamAPICallCompleted_t*) message.m_pubParam;
            LeaderboardFindResult_t result;
            bool isFailed;
            if (call.m_hAsyncCall == leaderboardCall
                && SteamAPI_ManualDispatch_GetAPICallResult(pipe, call.m_hAsyncCall, &result, result.sizeof, result.k_iCallback, &isFailed)
                && !isFailed && result.m_bLeaderboardFound
            ) {
                leaderboardEntryCount = SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(SteamAPI_SteamUserStats(), result.m_hSteamLeaderboard);
            }
        }
        SteamAPI_ManualDispatch_FreeLastCallback(pipe);
    }
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    if (!isReady) {
        drawText("Steam failed to start:\n{}".fmt(strzToStr(errorMessage.ptr)), Vec2(8));
        return false;
    }
    handleCallbacks();
    // Toggle the achievement. Stats can be used after they are received.
    auto stats = SteamAPI_SteamUserStats();
    auto isAchieved = false;
    if (hasStats) {
        SteamAPI_ISteamUserStats_GetAchievement(stats, achievement, &isAchieved);
        if (Keyboard.space.isPressed) {
            if (isAchieved) SteamAPI_ISteamUserStats_ClearAchievement(stats, achievement);
            else SteamAPI_ISteamUserStats_SetAchievement(stats, achievement);
            SteamAPI_ISteamUserStats_StoreStats(stats);
        }
    }
    // Draw the info.
    drawText(
        "Player: {}\nApp ID: {}\nHardware type: {}\nStats received: {}\nAchievement: {}\nLeaderboard entries: {}\n\nPress space to toggle the achievement."
        .fmt(
            strzToStr(SteamAPI_ISteamFriends_GetPersonaName(SteamAPI_SteamFriends())),
            SteamAPI_ISteamUtils_GetAppID(SteamAPI_SteamUtils()),
            SteamAPI_ISteamUtils_IsRunningOnSteamHardware(SteamAPI_SteamUtils()),
            hasStats,
            isAchieved,
            leaderboardEntryCount,
        ),
        Vec2(8),
    );
    return false;
}

void finish() {
    if (isReady) SteamAPI_Shutdown();
}

mixin runGame!(ready, update, finish);
