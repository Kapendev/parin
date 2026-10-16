// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `steam` module provides access to the Steamworks flat C API.
/// These bindings match the Steamworks SDK v1.65 release and cover a subset of it:
/// init, callbacks, user, friends, utils, stats and achievements, leaderboards, apps, cloud, screenshots and timeline.
/// Link against `steam_api64.dll` (Windows), `libsteam_api.so` (Linux) or `libsteam_api.dylib` (macOS) from the SDK.
/// Callbacks use manual dispatch because the C++ callback macros are not available outside of C++.
module parin.bindings.steam;

extern(C) @system nothrow @nogc:

// Steam packs callback structures to 4 bytes on Linux and macOS and to 8 bytes elsewhere.
// Only 8 byte fields are affected, so they use these alignments.
version (linux) {
    enum steamPack = 4;
} else version (OSX) {
    enum steamPack = 4;
} else version (FreeBSD) {
    enum steamPack = 4;
} else {
    enum steamPack = 8;
}
enum steamPackPointer = steamPack < (void*).sizeof ? steamPack : (void*).sizeof;

alias HSteamPipe = int;
alias HSteamUser = int;
alias AppId_t = uint;
alias SteamAPICall_t = ulong;
alias uint64_steamid = ulong;
alias SteamLeaderboard_t = ulong;
alias SteamLeaderboardEntries_t = ulong;
alias UGCHandle_t = ulong;
alias ScreenshotHandle = uint;
alias TimelineEventHandle_t = ulong;
alias SteamErrMsg = char[k_cchMaxSteamErrMsg];

enum k_cchMaxSteamErrMsg = 1024;
enum k_cchStatNameMax = 128;
enum k_cchLeaderboardNameMax = 128;
enum k_uAPICallInvalid = 0;

alias ESteamAPIInitResult = int;
alias ESteamAPICallFailure = int;
alias EResult = int;
alias ELeaderboardSortMethod = int;
alias ELeaderboardDisplayType = int;
alias ELeaderboardDataRequest = int;
alias ELeaderboardUploadScoreMethod = int;
alias EOverlayToStoreFlag = int;
alias EActivateGameOverlayToWebPageMode = int;
alias ENotificationPosition = int;
alias EGamepadTextInputMode = int;
alias EGamepadTextInputLineMode = int;
alias EFloatingGamepadTextInputMode = int;
alias ETimelineGameMode = int;
alias ETimelineEventClipPriority = int;
alias ESteamHardwareType = int;
alias ESteamHardwareDefaultConfig = int;

enum : ESteamAPIInitResult {
    k_ESteamAPIInitResult_OK              = 0,
    k_ESteamAPIInitResult_FailedGeneric   = 1,
    k_ESteamAPIInitResult_NoSteamClient   = 2,
    k_ESteamAPIInitResult_VersionMismatch = 3,
}

enum : ESteamAPICallFailure {
    k_ESteamAPICallFailureNone               = -1,
    k_ESteamAPICallFailureSteamGone          = 0,
    k_ESteamAPICallFailureNetworkFailure     = 1,
    k_ESteamAPICallFailureInvalidHandle      = 2,
    k_ESteamAPICallFailureMismatchedCallback = 3,
}

// Only the common results. The full list is in `steamclientpublic.h`.
enum : EResult {
    k_EResultNone               = 0,
    k_EResultOK                 = 1,
    k_EResultFail               = 2,
    k_EResultNoConnection       = 3,
    k_EResultInvalidParam       = 8,
    k_EResultFileNotFound       = 9,
    k_EResultBusy               = 10,
    k_EResultInvalidState       = 11,
    k_EResultAccessDenied       = 15,
    k_EResultTimeout            = 16,
    k_EResultServiceUnavailable = 20,
    k_EResultNotLoggedOn        = 21,
    k_EResultPending            = 22,
    k_EResultLimitExceeded      = 25,
    k_EResultIOFailure          = 37,
}

enum : ELeaderboardSortMethod {
    k_ELeaderboardSortMethodNone       = 0,
    k_ELeaderboardSortMethodAscending  = 1,
    k_ELeaderboardSortMethodDescending = 2,
}

enum : ELeaderboardDisplayType {
    k_ELeaderboardDisplayTypeNone             = 0,
    k_ELeaderboardDisplayTypeNumeric          = 1,
    k_ELeaderboardDisplayTypeTimeSeconds      = 2,
    k_ELeaderboardDisplayTypeTimeMilliSeconds = 3,
}

enum : ELeaderboardDataRequest {
    k_ELeaderboardDataRequestGlobal           = 0,
    k_ELeaderboardDataRequestGlobalAroundUser = 1,
    k_ELeaderboardDataRequestFriends          = 2,
    k_ELeaderboardDataRequestUsers            = 3,
}

enum : ELeaderboardUploadScoreMethod {
    k_ELeaderboardUploadScoreMethodNone        = 0,
    k_ELeaderboardUploadScoreMethodKeepBest    = 1,
    k_ELeaderboardUploadScoreMethodForceUpdate = 2,
}

enum : EOverlayToStoreFlag {
    k_EOverlayToStoreFlag_None             = 0,
    k_EOverlayToStoreFlag_AddToCart        = 1,
    k_EOverlayToStoreFlag_AddToCartAndShow = 2,
}

enum : EActivateGameOverlayToWebPageMode {
    k_EActivateGameOverlayToWebPageMode_Default = 0,
    k_EActivateGameOverlayToWebPageMode_Modal   = 1,
}

enum : ENotificationPosition {
    k_EPositionInvalid     = -1,
    k_EPositionTopLeft     = 0,
    k_EPositionTopRight    = 1,
    k_EPositionBottomLeft  = 2,
    k_EPositionBottomRight = 3,
}

enum : EGamepadTextInputMode {
    k_EGamepadTextInputModeNormal   = 0,
    k_EGamepadTextInputModePassword = 1,
}

enum : EGamepadTextInputLineMode {
    k_EGamepadTextInputLineModeSingleLine    = 0,
    k_EGamepadTextInputLineModeMultipleLines = 1,
}

enum : EFloatingGamepadTextInputMode {
    k_EFloatingGamepadTextInputModeModeSingleLine    = 0,
    k_EFloatingGamepadTextInputModeModeMultipleLines = 1,
    k_EFloatingGamepadTextInputModeModeEmail         = 2,
    k_EFloatingGamepadTextInputModeModeNumeric       = 3,
}

enum : ETimelineGameMode {
    k_ETimelineGameMode_Invalid       = 0,
    k_ETimelineGameMode_Playing       = 1,
    k_ETimelineGameMode_Staging       = 2,
    k_ETimelineGameMode_Menus         = 3,
    k_ETimelineGameMode_LoadingScreen = 4,
    k_ETimelineGameMode_Max,
}

enum : ETimelineEventClipPriority {
    k_ETimelineEventClipPriority_Invalid  = 0,
    k_ETimelineEventClipPriority_None     = 1,
    k_ETimelineEventClipPriority_Standard = 2,
    k_ETimelineEventClipPriority_Featured = 3,
}

enum : ESteamHardwareType {
    k_ESteamHardwareTypeNone         = 0,
    k_ESteamHardwareTypeSteamDeck    = 1,
    k_ESteamHardwareTypeSteamMachine = 2,
    k_ESteamHardwareTypeSteamFrame   = 3,
}

enum : ESteamHardwareDefaultConfig {
    k_ESteamHardwareDefaultConfigNone         = 0,
    k_ESteamHardwareDefaultConfigLow          = 1,
    k_ESteamHardwareDefaultConfigMedium       = 2,
    k_ESteamHardwareDefaultConfigHigh         = 3,
    k_ESteamHardwareDefaultConfigMax          = 4,
    k_ESteamHardwareDefaultConfigSteamDeck    = 5,
    k_ESteamHardwareDefaultConfigSteamMachine = 6,
    k_ESteamHardwareDefaultConfigSteamFrame   = 7,
}

// Base values for callback ids.
enum k_iSteamUserCallbacks          = 100;
enum k_iSteamFriendsCallbacks       = 300;
enum k_iSteamUtilsCallbacks         = 700;
enum k_iSteamAppsCallbacks          = 1000;
enum k_iSteamUserStatsCallbacks     = 1100;
enum k_iSteamRemoteStorageCallbacks = 1300;

// Interface handles. They are only used through pointers.
struct ISteamUser;
struct ISteamFriends;
struct ISteamUtils;
struct ISteamUserStats;
struct ISteamApps;
struct ISteamRemoteStorage;
struct ISteamScreenshots;
struct ISteamTimeline;

/// A Steam ID as stored inside callback structures.
/// It is byte aligned, so it can start at any offset.
struct CSteamID {
    align(1) ulong steamID;
}

/// Used by the manual dispatch functions.
struct CallbackMsg_t {
    HSteamUser m_hSteamUser;
    int m_iCallback;
    align(steamPackPointer) ubyte* m_pubParam;
    int m_cubParam;
}

struct SteamAPICallCompleted_t {
    enum k_iCallback = k_iSteamUtilsCallbacks + 3;
    align(steamPack) SteamAPICall_t m_hAsyncCall;
    int m_iCallback;
    uint m_cubParam;
}

struct SteamShutdown_t {
    enum k_iCallback = k_iSteamUtilsCallbacks + 4;
}

struct GamepadTextInputDismissed_t {
    enum k_iCallback = k_iSteamUtilsCallbacks + 14;
    bool m_bSubmitted;
    uint m_unSubmittedText;
    AppId_t m_unAppID;
}

struct FloatingGamepadTextInputDismissed_t {
    enum k_iCallback = k_iSteamUtilsCallbacks + 38;
}

struct GameOverlayActivated_t {
    enum k_iCallback = k_iSteamFriendsCallbacks + 31;
    ubyte m_bActive;
    bool m_bUserInitiated;
    AppId_t m_nAppID;
    uint m_dwOverlayPID;
}

struct DlcInstalled_t {
    enum k_iCallback = k_iSteamAppsCallbacks + 5;
    AppId_t m_nAppID;
}

struct UserStatsReceived_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 1;
    align(steamPack) ulong m_nGameID;
    EResult m_eResult;
    CSteamID m_steamIDUser;
}

struct UserStatsStored_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 2;
    align(steamPack) ulong m_nGameID;
    EResult m_eResult;
}

struct UserAchievementStored_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 3;
    align(steamPack) ulong m_nGameID;
    bool m_bGroupAchievement;
    char[k_cchStatNameMax] m_rgchAchievementName;
    uint m_nCurProgress;
    uint m_nMaxProgress;
}

struct LeaderboardFindResult_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 4;
    align(steamPack) SteamLeaderboard_t m_hSteamLeaderboard;
    ubyte m_bLeaderboardFound;
}

struct LeaderboardScoresDownloaded_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 5;
    align(steamPack) SteamLeaderboard_t m_hSteamLeaderboard;
    align(steamPack) SteamLeaderboardEntries_t m_hSteamLeaderboardEntries;
    int m_cEntryCount;
}

struct LeaderboardScoreUploaded_t {
    enum k_iCallback = k_iSteamUserStatsCallbacks + 6;
    ubyte m_bSuccess;
    align(steamPack) SteamLeaderboard_t m_hSteamLeaderboard;
    int m_nScore;
    ubyte m_bScoreChanged;
    int m_nGlobalRankNew;
    int m_nGlobalRankPrevious;
}

struct LeaderboardEntry_t {
    CSteamID m_steamIDUser;
    int m_nGlobalRank;
    int m_nScore;
    int m_cDetails;
    align(steamPack) UGCHandle_t m_hUGC;
}

// Init
ESteamAPIInitResult SteamAPI_InitFlat(SteamErrMsg* pOutErrMsg);
ESteamAPIInitResult SteamInternal_SteamAPI_Init(const(char)* pszInternalCheckInterfaceVersions, SteamErrMsg* pOutErrMsg);
void SteamAPI_Shutdown();
bool SteamAPI_RestartAppIfNecessary(uint unOwnAppID);
bool SteamAPI_IsSteamRunning();
void SteamAPI_ReleaseCurrentThreadMemory();
HSteamPipe SteamAPI_GetHSteamPipe();
HSteamUser SteamAPI_GetHSteamUser();

/// The interface versions used by this module. Pass it to `SteamInternal_SteamAPI_Init` to init
/// and check that the Steam client supports them, like `SteamAPI_InitEx` does in C++.
enum steamInterfaceVersions =
    "SteamUtils011\0" ~
    "STEAMAPPS_INTERFACE_VERSION009\0" ~
    "SteamFriends018\0" ~
    "STEAMREMOTESTORAGE_INTERFACE_VERSION016\0" ~
    "STEAMSCREENSHOTS_INTERFACE_VERSION003\0" ~
    "STEAMUSERSTATS_INTERFACE_VERSION013\0" ~
    "SteamUser023\0" ~
    "\0";

// Manual dispatch
// Call `SteamAPI_ManualDispatch_Init` once after init, then every frame:
// call `SteamAPI_ManualDispatch_RunFrame`, loop over `SteamAPI_ManualDispatch_GetNextCallback`,
// and call `SteamAPI_ManualDispatch_FreeLastCallback` after handling each callback.
// Results of async calls (`SteamAPICall_t`) arrive as a `SteamAPICallCompleted_t` callback
// and are read with `SteamAPI_ManualDispatch_GetAPICallResult`.
void SteamAPI_ManualDispatch_Init();
void SteamAPI_ManualDispatch_RunFrame(HSteamPipe hSteamPipe);
bool SteamAPI_ManualDispatch_GetNextCallback(HSteamPipe hSteamPipe, CallbackMsg_t* pCallbackMsg);
void SteamAPI_ManualDispatch_FreeLastCallback(HSteamPipe hSteamPipe);
bool SteamAPI_ManualDispatch_GetAPICallResult(HSteamPipe hSteamPipe, SteamAPICall_t hSteamAPICall, void* pCallback, int cubCallback, int iCallbackExpected, bool* pbFailed);

// Interface accessors
ISteamUser* SteamAPI_SteamUser_v023();
ISteamFriends* SteamAPI_SteamFriends_v018();
ISteamUtils* SteamAPI_SteamUtils_v011();
ISteamUserStats* SteamAPI_SteamUserStats_v013();
ISteamApps* SteamAPI_SteamApps_v009();
ISteamRemoteStorage* SteamAPI_SteamRemoteStorage_v016();
ISteamScreenshots* SteamAPI_SteamScreenshots_v003();
ISteamTimeline* SteamAPI_SteamTimeline_v004();

alias SteamAPI_SteamUser = SteamAPI_SteamUser_v023;
alias SteamAPI_SteamFriends = SteamAPI_SteamFriends_v018;
alias SteamAPI_SteamUtils = SteamAPI_SteamUtils_v011;
alias SteamAPI_SteamUserStats = SteamAPI_SteamUserStats_v013;
alias SteamAPI_SteamApps = SteamAPI_SteamApps_v009;
alias SteamAPI_SteamRemoteStorage = SteamAPI_SteamRemoteStorage_v016;
alias SteamAPI_SteamScreenshots = SteamAPI_SteamScreenshots_v003;
alias SteamAPI_SteamTimeline = SteamAPI_SteamTimeline_v004;

// User
bool SteamAPI_ISteamUser_BLoggedOn(ISteamUser* self);
uint64_steamid SteamAPI_ISteamUser_GetSteamID(ISteamUser* self);
int SteamAPI_ISteamUser_GetPlayerSteamLevel(ISteamUser* self);

// Friends
const(char)* SteamAPI_ISteamFriends_GetPersonaName(ISteamFriends* self);
const(char)* SteamAPI_ISteamFriends_GetFriendPersonaName(ISteamFriends* self, uint64_steamid steamIDFriend);
void SteamAPI_ISteamFriends_ActivateGameOverlay(ISteamFriends* self, const(char)* pchDialog);
void SteamAPI_ISteamFriends_ActivateGameOverlayToUser(ISteamFriends* self, const(char)* pchDialog, uint64_steamid steamID);
void SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(ISteamFriends* self, const(char)* pchURL, EActivateGameOverlayToWebPageMode eMode);
void SteamAPI_ISteamFriends_ActivateGameOverlayToStore(ISteamFriends* self, AppId_t nAppID, EOverlayToStoreFlag eFlag);
bool SteamAPI_ISteamFriends_SetRichPresence(ISteamFriends* self, const(char)* pchKey, const(char)* pchValue);
void SteamAPI_ISteamFriends_ClearRichPresence(ISteamFriends* self);

// Utils
uint SteamAPI_ISteamUtils_GetSecondsSinceAppActive(ISteamUtils* self);
uint SteamAPI_ISteamUtils_GetAppID(ISteamUtils* self);
bool SteamAPI_ISteamUtils_IsAPICallCompleted(ISteamUtils* self, SteamAPICall_t hSteamAPICall, bool* pbFailed);
ESteamAPICallFailure SteamAPI_ISteamUtils_GetAPICallFailureReason(ISteamUtils* self, SteamAPICall_t hSteamAPICall);
bool SteamAPI_ISteamUtils_GetAPICallResult(ISteamUtils* self, SteamAPICall_t hSteamAPICall, void* pCallback, int cubCallback, int iCallbackExpected, bool* pbFailed);
void SteamAPI_ISteamUtils_SetOverlayNotificationPosition(ISteamUtils* self, ENotificationPosition eNotificationPosition);
bool SteamAPI_ISteamUtils_IsOverlayEnabled(ISteamUtils* self);
bool SteamAPI_ISteamUtils_IsSteamInBigPictureMode(ISteamUtils* self);
ESteamHardwareType SteamAPI_ISteamUtils_IsRunningOnSteamHardware(ISteamUtils* self);
ESteamHardwareDefaultConfig SteamAPI_ISteamUtils_GetSteamHardwareDefaultConfig(ISteamUtils* self);
bool SteamAPI_ISteamUtils_IsRunningUnderProton(ISteamUtils* self);
bool SteamAPI_ISteamUtils_ShowGamepadTextInput(ISteamUtils* self, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, const(char)* pchDescription, uint unCharMax, const(char)* pchExistingText);
uint SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(ISteamUtils* self);
bool SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(ISteamUtils* self, char* pchText, uint cchText);
bool SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(ISteamUtils* self, EFloatingGamepadTextInputMode eKeyboardMode, int nTextFieldXPosition, int nTextFieldYPosition, int nTextFieldWidth, int nTextFieldHeight);
bool SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(ISteamUtils* self);

// Stats and achievements
// Stats are fetched automatically after init. Wait for `UserStatsReceived_t` before reading them.
bool SteamAPI_ISteamUserStats_GetStatInt32(ISteamUserStats* self, const(char)* pchName, int* pData);
bool SteamAPI_ISteamUserStats_GetStatFloat(ISteamUserStats* self, const(char)* pchName, float* pData);
bool SteamAPI_ISteamUserStats_SetStatInt32(ISteamUserStats* self, const(char)* pchName, int nData);
bool SteamAPI_ISteamUserStats_SetStatFloat(ISteamUserStats* self, const(char)* pchName, float fData);
bool SteamAPI_ISteamUserStats_GetAchievement(ISteamUserStats* self, const(char)* pchName, bool* pbAchieved);
bool SteamAPI_ISteamUserStats_SetAchievement(ISteamUserStats* self, const(char)* pchName);
bool SteamAPI_ISteamUserStats_ClearAchievement(ISteamUserStats* self, const(char)* pchName);
bool SteamAPI_ISteamUserStats_StoreStats(ISteamUserStats* self);
const(char)* SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(ISteamUserStats* self, const(char)* pchName, const(char)* pchKey);
bool SteamAPI_ISteamUserStats_IndicateAchievementProgress(ISteamUserStats* self, const(char)* pchName, uint nCurProgress, uint nMaxProgress);
uint SteamAPI_ISteamUserStats_GetNumAchievements(ISteamUserStats* self);
const(char)* SteamAPI_ISteamUserStats_GetAchievementName(ISteamUserStats* self, uint iAchievement);
bool SteamAPI_ISteamUserStats_ResetAllStats(ISteamUserStats* self, bool bAchievementsToo);

// Leaderboards
SteamAPICall_t SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(ISteamUserStats* self, const(char)* pchLeaderboardName, ELeaderboardSortMethod eLeaderboardSortMethod, ELeaderboardDisplayType eLeaderboardDisplayType);
SteamAPICall_t SteamAPI_ISteamUserStats_FindLeaderboard(ISteamUserStats* self, const(char)* pchLeaderboardName);
const(char)* SteamAPI_ISteamUserStats_GetLeaderboardName(ISteamUserStats* self, SteamLeaderboard_t hSteamLeaderboard);
int SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(ISteamUserStats* self, SteamLeaderboard_t hSteamLeaderboard);
SteamAPICall_t SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(ISteamUserStats* self, SteamLeaderboard_t hSteamLeaderboard, ELeaderboardDataRequest eLeaderboardDataRequest, int nRangeStart, int nRangeEnd);
bool SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(ISteamUserStats* self, SteamLeaderboardEntries_t hSteamLeaderboardEntries, int index, LeaderboardEntry_t* pLeaderboardEntry, int* pDetails, int cDetailsMax);
SteamAPICall_t SteamAPI_ISteamUserStats_UploadLeaderboardScore(ISteamUserStats* self, SteamLeaderboard_t hSteamLeaderboard, ELeaderboardUploadScoreMethod eLeaderboardUploadScoreMethod, int nScore, const(int)* pScoreDetails, int cScoreDetailsCount);

// Apps
bool SteamAPI_ISteamApps_BIsSubscribed(ISteamApps* self);
bool SteamAPI_ISteamApps_BIsSubscribedApp(ISteamApps* self, AppId_t appID);
bool SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(ISteamApps* self);
bool SteamAPI_ISteamApps_BIsDlcInstalled(ISteamApps* self, AppId_t appID);
int SteamAPI_ISteamApps_GetDLCCount(ISteamApps* self);
bool SteamAPI_ISteamApps_BGetDLCDataByIndex(ISteamApps* self, int iDLC, AppId_t* pAppID, bool* pbAvailable, char* pchName, int cchNameBufferSize);
const(char)* SteamAPI_ISteamApps_GetCurrentGameLanguage(ISteamApps* self);
const(char)* SteamAPI_ISteamApps_GetAvailableGameLanguages(ISteamApps* self);
int SteamAPI_ISteamApps_GetAppBuildId(ISteamApps* self);
int SteamAPI_ISteamApps_GetLaunchCommandLine(ISteamApps* self, char* pszCommandLine, int cubCommandLine);

// Cloud
bool SteamAPI_ISteamRemoteStorage_FileWrite(ISteamRemoteStorage* self, const(char)* pchFile, const(void)* pvData, int cubData);
int SteamAPI_ISteamRemoteStorage_FileRead(ISteamRemoteStorage* self, const(char)* pchFile, void* pvData, int cubDataToRead);
bool SteamAPI_ISteamRemoteStorage_FileForget(ISteamRemoteStorage* self, const(char)* pchFile);
bool SteamAPI_ISteamRemoteStorage_FileDelete(ISteamRemoteStorage* self, const(char)* pchFile);
bool SteamAPI_ISteamRemoteStorage_FileExists(ISteamRemoteStorage* self, const(char)* pchFile);
bool SteamAPI_ISteamRemoteStorage_FilePersisted(ISteamRemoteStorage* self, const(char)* pchFile);
int SteamAPI_ISteamRemoteStorage_GetFileSize(ISteamRemoteStorage* self, const(char)* pchFile);
int SteamAPI_ISteamRemoteStorage_GetFileCount(ISteamRemoteStorage* self);
const(char)* SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(ISteamRemoteStorage* self, int iFile, int* pnFileSizeInBytes);
bool SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(ISteamRemoteStorage* self);
bool SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(ISteamRemoteStorage* self);
void SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(ISteamRemoteStorage* self, bool bEnabled);

// Screenshots
ScreenshotHandle SteamAPI_ISteamScreenshots_WriteScreenshot(ISteamScreenshots* self, void* pubRGB, uint cubRGB, int nWidth, int nHeight);
void SteamAPI_ISteamScreenshots_TriggerScreenshot(ISteamScreenshots* self);
void SteamAPI_ISteamScreenshots_HookScreenshots(ISteamScreenshots* self, bool bHook);

// Timeline
void SteamAPI_ISteamTimeline_SetTimelineTooltip(ISteamTimeline* self, const(char)* pchDescription, float flTimeDelta);
void SteamAPI_ISteamTimeline_ClearTimelineTooltip(ISteamTimeline* self, float flTimeDelta);
void SteamAPI_ISteamTimeline_SetTimelineGameMode(ISteamTimeline* self, ETimelineGameMode eMode);
TimelineEventHandle_t SteamAPI_ISteamTimeline_AddInstantaneousTimelineEvent(ISteamTimeline* self, const(char)* pchTitle, const(char)* pchDescription, const(char)* pchIcon, uint unIconPriority, float flStartOffsetSeconds, ETimelineEventClipPriority ePossibleClip);
