// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.backend.rl;

import rl = parin.bindings.rl;
version (WebAssembly) {
    import em = parin.bindings.em;
}

import parin.joka.ascii;
import parin.joka.containers;
import parin.joka.math;
import parin.joka.memory;
import parin.joka.types;
import parin.types;

__gshared BackendState* _backendState;

// ---------- Config
version (WebAssembly) {
    enum defaultBackendResourcesCapacity = 256;
} else {
    enum defaultBackendResourcesCapacity = 1024;
}
// ----------

alias BasicContainer(T)  = FixedList!(T, defaultBackendResourcesCapacity);
alias SparseContainer(T) = FixedList!(SparseListItem!T, defaultBackendResourcesCapacity);
alias GenData            = BasicContainer!(Gen);
alias TexturesData       = SparseList!(RlTexture, SparseContainer!(RlTexture));
alias FontsData          = SparseList!(RlFont, SparseContainer!(RlFont));
alias SoundsData         = SparseList!(RlSound, SparseContainer!(RlSound));
alias ViewportsData      = SparseList!(RlViewport, SparseContainer!(RlViewport));

alias RlFilter = int; /// Raylib texture filter modes.
alias RlWrap   = int; /// Raylib texture wrapping modes.
alias RlBlend  = int; /// Raylib texture blending modes.
alias RlKey    = int; /// Raylib input key.

/// A raylib texture.
struct RlTexture {
    rl.Texture2D data; /// Raylib data.
    Filter filter;     /// Texture filtering mode.
    Wrap wrap;         /// Texture wrapping mode.
}

/// A raylib font.
struct RlFont {
    rl.Font data;    /// Raylib data.
    int runeSpacing; /// The spacing between individual characters.
    int lineSpacing; /// The spacing between lines of text.
    Filter filter;   /// Texture filtering mode.
    Wrap wrap;       /// Texture wrapping mode.
}

/// A raylib sound.
struct RlSound {
    Union!(rl.Sound, rl.Music) data; /// Raylib data.
    float volume = 1.0f;             /// The volume. A value of 1.0 is max level.
    float pan = 0.5f;                /// The pan. A value of 0.5 is center.
    float pitch = 1.0f;              /// The pitch. A value of 1.0 is base level.
    float pitchVariance = 1.0f;      /// The pitch variance. A value of 1.0 is no variation.
    float pitchVarianceBase = 1.0f;  /// Used as a base when changing the pitch with `pitchVariance`.
    bool canRepeat;                  /// True if the sound can repeat when it ends.
    bool isActive;                   /// True is the sound is or has started playing.
    bool isPaused;                   /// True if the sound is paused.
}

/// A raylib viewport.
struct RlViewport {
    rl.RenderTexture2D data; /// Raylib data.
    Rgba color;              /// The viewport background color.
    bool isAttached;         /// True if the viewport is currently in use.
    Filter filter;           /// Texture filtering mode.
    Wrap wrap;               /// Texture wrapping mode.
    Blend blend;             /// Texture blending mode.
}

struct BackendState {
    GenList!(TexturesData.Item.Item, TexturesData, GenData) textures;
    GenList!(FontsData.Item.Item, FontsData, GenData) fonts;
    GenList!(SoundsData.Item.Item, SoundsData, GenData) sounds;
    GenList!(ViewportsData.Item.Item, ViewportsData, GenData) viewports;
    BasicContainer!IStr droppedPaths;

    uint elapsedTicks;
    int fpsMax;
    Vec2 mouseBuffer;
    bool isCursorVisible;

    bool windowIsChanging;
    float windowChangeTime;
    int windowPreviousWindowWidth;
    int windowPreviousWindowHeight;

    bool vsyncIsChanging;
    bool vsync;
}

@trusted:

/// Updates the window every frame with the given function.
/// Returns when the given function returns true.
void updateWindow(alias loop)() {
    version (WebAssembly) {
        static void loopWeb() {
            if (loop) em.emscripten_cancel_main_loop();
        }
        em.emscripten_set_main_loop(&loopWeb, 0, true);
    } else {
        while (true) if (isWindowCloseButtonPressed || loop) break;
    }
}

@trusted nothrow:

void openWindow(int width, int height, IStr title, bool vsync, int fpsMax, int windowMinWidth, int windowMinHeight) {
    enum targetHtmlElementId = "canvas";

    // Create the null values.
    _backendState = jokaMake!BackendState();
    _backendState.textures.push(RlTexture());
    _backendState.fonts.push(RlFont());
    _backendState.sounds.push(RlSound());
    _backendState.viewports.push(RlViewport());

    // Setup backend and raylib.
    _backendState.vsync = vsync;
    _backendState.fpsMax = fpsMax;
    _backendState.isCursorVisible = true;
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | (vsync ? rl.FLAG_VSYNC_HINT : 0));
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    rl.InitWindow(width, height, title.toStrz().getOr());
    rl.InitAudioDevice();
    rl.SetExitKey(rl.KEY_NULL);
    rl.SetTargetFPS(fpsMax);
    rl.SetWindowMinSize(windowMinWidth, windowMinHeight);
    rl.rlSetBlendFactorsSeparate(0x0302, 0x0303, 1, 0x0303, 0x8006, 0x8006);

    version (WebAssembly) {
        static extern(C) nothrow @nogc bool _webMouseCallback(int eventType, const(em.EmscriptenMouseEvent)* mouseEvent, void* userData) {
            switch (eventType) {
                case em.EMSCRIPTEN_EVENT_MOUSEMOVE:
                    _backendState.mouseBuffer = Vec2(mouseEvent.clientX, mouseEvent.clientY);
                    return true;
                default:
                    return false;
            }
        }
        em.emscripten_set_mousemove_callback_on_thread(targetHtmlElementId, null, true, &_webMouseCallback);
    }
}

Maybe!ResourceId loadTexture(IStr path) {
    auto resource = rl.LoadTexture(path.toStrz().getOr());
    if (resource.id == 0) return Maybe!ResourceId(Fault.cannotFind);
    return Maybe!ResourceId(_backendState.textures.append(RlTexture(resource)));
}

Maybe!ResourceId loadTexture(const(ubyte)[] memory, IStr ext = ".png") {
    auto image = rl.LoadImageFromMemory(ext.toStrz().getOr(), memory.ptr, cast(int) memory.length);
    if (image.data == null) return Maybe!ResourceId(Fault.invalid);
    auto resource = rl.LoadTextureFromImage(image);
    rl.UnloadImage(image);
    if (resource.id == 0) return Maybe!ResourceId(Fault.cannotFind);
    return Maybe!ResourceId(_backendState.textures.append(RlTexture(resource)));
}

Maybe!ResourceId loadFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes) {
    auto resource = rl.LoadFontEx(path.toStrz().getOr(), size, runes.length ? cast(int*) runes.ptr : null, cast(int) runes.length);
    if (resource.texture.id == 0 || resource.texture.id == rl.GetFontDefault().texture.id) return Maybe!ResourceId(Fault.cannotFind);
    return Maybe!ResourceId(_backendState.fonts.push(RlFont(resource, runeSpacing >= 0 ? runeSpacing : 0, lineSpacing >= 0 ? lineSpacing : size)));
}

Maybe!ResourceId loadFont(const(ubyte)[] memory, int size, int runeSpacing, int lineSpacing, IStr32 runes, IStr ext = ".ttf") {
    auto resource = rl.LoadFontFromMemory(ext.toStrz().getOr(), memory.ptr, cast(int) memory.length, size, runes.length ? cast(int*) runes.ptr : null, cast(int) runes.length);
    if (resource.texture.id == 0 || resource.texture.id == rl.GetFontDefault().texture.id) return Maybe!ResourceId(Fault.invalid);
    return Maybe!ResourceId(_backendState.fonts.append(RlFont(resource, runeSpacing >= 0 ? runeSpacing : 0, lineSpacing >= 0 ? lineSpacing : size)));
}

Maybe!ResourceId loadFont(ResourceId texture, int tileWidth, int tileHeight) {
    if (resourceIsNull(texture) || tileWidth <= 0|| tileHeight <= 0) return Maybe!ResourceId(Fault.invalid);
    auto oldResource = &_backendState.textures[texture];
    auto newResource = rl.Font();
    auto rowCount = textureHeight(texture) / tileHeight;
    auto colCount = textureWidth(texture) / tileWidth;
    auto maxCount = rowCount * colCount;
    newResource.baseSize = tileHeight;
    newResource.glyphCount = maxCount;
    newResource.glyphPadding = 0;
    newResource.texture = oldResource.data;
    newResource.recs = cast(rl.Rectangle*) rl.MemAlloc(cast(uint) (maxCount * rl.Rectangle.sizeof));
    foreach (i; 0 .. maxCount) {
        newResource.recs[i].x = (i % colCount) * tileWidth;
        newResource.recs[i].y = (i / colCount) * tileHeight;
        newResource.recs[i].width = tileWidth;
        newResource.recs[i].height = tileHeight;
    }
    newResource.glyphs = cast(rl.GlyphInfo*) rl.MemAlloc(cast(uint) (maxCount * rl.GlyphInfo.sizeof));
    foreach (i; 0 .. maxCount) {
        newResource.glyphs[i] = rl.GlyphInfo();
        newResource.glyphs[i].value = i + 32;
    }
    _backendState.textures.remove(texture); // Remove ID, but not the resource.
    return Maybe!ResourceId(_backendState.fonts.push(RlFont(newResource, 0, tileHeight)));
}

Maybe!ResourceId loadViewport(int width, int height, Rgba color, Blend blend) {
    auto resource = RlViewport();
    resource.data = rl.LoadRenderTexture(width, height);
    if (resource.data.id == 0) return Maybe!ResourceId(Fault.cannotFind);
    resource.color = color;
    resource.blend = blend;
    return Maybe!ResourceId(_backendState.viewports.push(resource));
}

Maybe!ResourceId loadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance = 1.0f) {
    auto resource = RlSound();
    auto isEmpty = true;
    if (path.endsWith(".wav")) {
        auto temp =  rl.LoadSound(path.toStrz().getOr());
        resource.data = temp;
        isEmpty = temp.stream.sampleRate == 0;
    } else {
        auto temp = rl.LoadMusicStream(path.toStrz().getOr());
        resource.data = temp;
        isEmpty = temp.stream.sampleRate == 0;
    }
    if (isEmpty) {
        return Maybe!ResourceId(Fault.invalid);
    } else {
        auto id = _backendState.sounds.push(resource);
        soundSetVolume(id, volume);
        soundSetPitch(id, pitch, true);
        soundSetCanRepeat(id, canRepeat);
        soundSetPitchVariance(id, pitchVariance);
        return Maybe!ResourceId(id);
    }
}

@trusted nothrow @nogc:

void closeWindow() {
    freeAllTextures(false);
    freeAllFonts(false);
    freeAllSounds(false);
    freeAllViewports(false);
    jokaFree(_backendState);
    rl.CloseAudioDevice();
    rl.CloseWindow();
}

void freeAllTextures(bool canSkipFirst) {
    foreach (id; _backendState.textures.ids) if (id.value) {
        if (canSkipFirst && id.value == 1) {} else textureFree(id);
    }
}

void freeAllFonts(bool canSkipFirst) {
    foreach (id; _backendState.fonts.ids) if (id.value) {
        if (canSkipFirst && id.value == 1) {} else fontFree(id);
    }
}

void freeAllSounds(bool canSkipFirst) {
    foreach (id; _backendState.sounds.ids) if (id.value) {
        if (canSkipFirst && id.value == 1) {} else soundFree(id);
    }
}

void freeAllViewports(bool canSkipFirst) {
    foreach (id; _backendState.viewports.ids) if (id.value) {
        if (canSkipFirst && id.value == 1) {} else viewportFree(id);
    }
}

Sz textureCount() => _backendState.textures.length - 1;
Sz fontCount() => _backendState.fonts.length - 1;
Sz soundCount() => _backendState.sounds.length - 1;
Sz viewportCount() => _backendState.viewports.length - 1;

pragma(inline, true) bool resourceIsNull(ResourceId id) => id.value == 0;
pragma(inline, true) bool textureIsValid(ResourceId id) => !id.resourceIsNull && _backendState.textures.has(id);

Filter textureFilter(ResourceId id) {
    if (id.resourceIsNull) return Filter.init;
    auto resource = &_backendState.textures[id];
    return resource.filter;
}

void textureSetFilter(ResourceId id, Filter value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.textures[id];
    rl.SetTextureFilter(resource.data, toRl(value));
    resource.filter = value;
}

Wrap textureWrap(ResourceId id) {
    if (id.resourceIsNull) return Wrap.init;
    auto resource = &_backendState.textures[id];
    return resource.wrap;
}

void textureSetWrap(ResourceId id, Wrap value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.textures[id];
    rl.SetTextureWrap(resource.data, toRl(value));
    resource.wrap = value;
}

int textureWidth(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.textures[id];
    return resource.data.width;
}

int textureHeight(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.textures[id];
    return resource.data.height;
}

Vec2 textureSize(ResourceId id) {
    if (id.resourceIsNull) return Vec2();
    auto resource = &_backendState.textures[id];
    return Vec2(resource.data.width, resource.data.height);
}

void textureFree(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.textures[id];
    rl.UnloadTexture(resource.data);
    _backendState.textures.remove(id);
}

pragma(inline, true) bool fontIsValid(ResourceId id) => !id.resourceIsNull && _backendState.fonts.has(id);

Filter fontFilter(ResourceId id) {
    if (id.resourceIsNull) return Filter.init;
    auto resource = &_backendState.fonts[id];
    return resource.filter;
}

void fontSetFilter(ResourceId id, Filter value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.fonts[id];
    rl.SetTextureFilter(resource.data.texture, toRl(value));
    resource.filter = value;
}

Wrap fontWrap(ResourceId id) {
    if (id.resourceIsNull) return Wrap.init;
    auto resource = &_backendState.fonts[id];
    return resource.wrap;
}

void fontSetWrap(ResourceId id, Wrap value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.fonts[id];
    rl.SetTextureWrap(resource.data.texture, toRl(value));
    resource.wrap = value;
}

int fontSize(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.fonts[id];
    return resource.data.baseSize;
}

int fontRuneSpacing(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.fonts[id];
    return resource.runeSpacing;
}

void fontSetRuneSpacing(ResourceId id, int value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.fonts[id];
    resource.runeSpacing = value;
}

int fontLineSpacing(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.fonts[id];
    return resource.lineSpacing;
}

void fontSetLineSpacing(ResourceId id, int value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.fonts[id];
    resource.lineSpacing = value;
}

GlyphInfo fontGlyphInfo(ResourceId id, int rune) {
    if (id.resourceIsNull) return GlyphInfo();
    auto resource = &_backendState.fonts[id];
    auto glyphIndex = rl.GetGlyphIndex(resource.data, rune);
    auto info = resource.data.glyphs[glyphIndex];
    auto rect = resource.data.recs[glyphIndex];
    auto result = GlyphInfo();
    result.value = info.value;
    result.offset = IVec2(info.offsetX, info.offsetY);
    result.advanceX = info.advanceX;
    result.rect = IRect(cast(int) rect.x, cast(int) rect.y, cast(int) rect.width, cast(int) rect.height);
    return result;
}

void fontFree(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.fonts[id];
    rl.UnloadFont(resource.data);
    _backendState.fonts.remove(id);
}

pragma(inline, true) bool soundIsValid(ResourceId id) => !id.resourceIsNull && _backendState.sounds.has(id);

float soundVolume(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    return resource.volume;
}

void soundSetVolume(ResourceId id, float value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.volume = value;
    if (resource.data.isType!(rl.Sound)) {
        rl.SetSoundVolume(resource.data.as!(rl.Sound)(), value);
    } else {
        rl.SetMusicVolume(resource.data.as!(rl.Music)(), value);
    }
}

float soundPan(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    return resource.pan;
}

void soundSetPan(ResourceId id, float value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.pan = value;
    if (resource.data.isType!(rl.Sound)) {
        rl.SetSoundPan(resource.data.as!(rl.Sound)(), value);
    } else {
        rl.SetMusicPan(resource.data.as!(rl.Music)(), value);
    }
}

float soundPitch(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    return resource.pitch;
}

void soundSetPitch(ResourceId id, float value, bool canUpdatePitchVarianceBase) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.pitch = value;
    if (canUpdatePitchVarianceBase) resource.pitchVarianceBase = value;
    if (resource.data.isType!(rl.Sound)) {
        rl.SetSoundPitch(resource.data.as!(rl.Sound)(), value);
    } else {
        rl.SetMusicPitch(resource.data.as!(rl.Music)(), value);
    }
}

float soundPitchVariance(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    return resource.pitchVariance;
}

void soundSetPitchVariance(ResourceId id, float value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.pitchVariance = value;
}

float soundPitchVarianceBase(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    return resource.pitchVarianceBase;
}

void soundSetPitchVarianceBase(ResourceId id, float value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.pitchVarianceBase = value;
}

bool soundCanRepeat(ResourceId id) {
    if (id.resourceIsNull) return false;
    auto resource = &_backendState.sounds[id];
    return resource.canRepeat;
}

void soundSetCanRepeat(ResourceId id, bool value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.canRepeat = value;
}

bool soundIsActive(ResourceId id) {
    if (id.resourceIsNull) return false;
    auto resource = &_backendState.sounds[id];
    return resource.isActive;
}

bool soundIsPaused(ResourceId id) {
    if (id.resourceIsNull) return false;
    auto resource = &_backendState.sounds[id];
    return resource.isPaused;
}

float soundTime(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    if (resource.data.isType!(rl.Sound)) {
        return 0.0f;
    } else {
        return rl.GetMusicTimePlayed(resource.data.as!(rl.Music)());
    }
}

float soundDuration(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    auto resource = &_backendState.sounds[id];
    if (resource.data.isType!(rl.Sound)) {
        return 0.0f;
    } else {
        return rl.GetMusicTimeLength(resource.data.as!(rl.Music)());
    }
}

float soundProgress(ResourceId id) {
    if (id.resourceIsNull) return 0.0f;
    return soundTime(id) / soundDuration(id);
}

void soundFree(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (resource.data.isType!(rl.Sound)) {
        rl.UnloadSound(resource.data.as!(rl.Sound)());
    } else {
        rl.UnloadMusicStream(resource.data.as!(rl.Music)());
    }
    _backendState.sounds.remove(id);
}

pragma(inline, true) bool viewportIsValid(ResourceId id) => !id.resourceIsNull && _backendState.viewports.has(id);

Filter viewportFilter(ResourceId id) {
    if (id.resourceIsNull) return Filter.init;
    auto resource = &_backendState.viewports[id];
    return resource.filter;
}

void viewportSetFilter(ResourceId id, Filter value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto isEmpty = resource.data.texture.id == 0;
    if (isEmpty) return;
    rl.SetTextureFilter(resource.data.texture, toRl(value));
    resource.filter = value;
}

Wrap viewportWrap(ResourceId id) {
    if (id.resourceIsNull) return Wrap.init;
    auto resource = &_backendState.viewports[id];
    return resource.wrap;
}

void viewportSetWrap(ResourceId id, Wrap value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto isEmpty = resource.data.texture.id == 0;
    if (isEmpty) return;
    rl.SetTextureWrap(resource.data.texture, toRl(value));
    resource.wrap = value;
}

Blend viewportBlend(ResourceId id) {
    if (id.resourceIsNull) return Blend();
    auto resource = &_backendState.viewports[id];
    return resource.blend;
}

void viewportSetBlend(ResourceId id, Blend value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    resource.blend = value;
}

Rgba viewportColor(ResourceId id) {
    if (id.resourceIsNull) return Rgba();
    auto resource = &_backendState.viewports[id];
    return resource.color;
}

void viewportSetColor(ResourceId id, Rgba value) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    resource.color = value;
}

int viewportWidth(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.viewports[id];
    return resource.data.texture.width;
}

int viewportHeight(ResourceId id) {
    if (id.resourceIsNull) return 0;
    auto resource = &_backendState.viewports[id];
    return resource.data.texture.height;
}

Vec2 viewportSize(ResourceId id) {
    if (id.resourceIsNull) return Vec2();
    auto resource = &_backendState.viewports[id];
    return Vec2(resource.data.texture.width, resource.data.texture.height);
}

bool viewportIsAttached(ResourceId id) {
    if (id.resourceIsNull) return false;
    auto resource = &_backendState.viewports[id];
    return resource.isAttached;
}

void viewportResize(ResourceId id, int newWidth, int newHeight) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto hasSameSize = resource.data.texture.width == newWidth && resource.data.texture.height == newHeight;
    auto hasData = resource.data.texture.id != 0;
    auto hasInvalidNewSize = newWidth < 0 || newHeight < 0;
    if (hasSameSize) return;
    if (hasData) rl.UnloadRenderTexture(resource.data);
    if (hasInvalidNewSize) {
        resource.data = rl.RenderTexture2D();
        return;
    }
    resource.data = rl.LoadRenderTexture(newWidth, newHeight);
    // NOTE: The rule is that the engine will set the filter and wrap mode, but viewport resizing is a special case, so we do it here.
    //   There is also no need to call the member functions here because we just reuse the old values.
    rl.SetTextureFilter(resource.data.texture, toRl(resource.filter));
    rl.SetTextureWrap(resource.data.texture, toRl(resource.wrap));
}

void viewportFree(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto hasData = resource.data.texture.id != 0;
    if (hasData) rl.UnloadRenderTexture(resource.data);
    _backendState.viewports.remove(id);
}

void beginDroppedPaths() {
    if (rl.IsFileDropped()) {
        _backendState.droppedPaths.clear();
        auto list = rl.LoadDroppedFiles();
        foreach (i; 0 .. min(list.count, defaultBackendResourcesCapacity)) {
            _backendState.droppedPaths.append(list.paths[i].toStr());
        }
    }
}

void endDroppedPaths() {
    if (rl.IsFileDropped()) {
        // NOTE: LoadDroppedFiles just returns a global variable.
        rl.UnloadDroppedFiles(rl.LoadDroppedFiles());
    }
}

IStr[] droppedPaths() {
    return _backendState.droppedPaths.items;
}

int screenWidth() {
    return rl.GetMonitorWidth(rl.GetCurrentMonitor());
}

int screenHeight() {
    return rl.GetMonitorHeight(rl.GetCurrentMonitor());
}

int windowWidth() {
    if (isFullscreen) return screenWidth;
    else return rl.GetScreenWidth();
}

int windowHeight() {
    if (isFullscreen) return screenHeight;
    else return rl.GetScreenHeight();
}

bool isFullscreen() {
    return rl.IsWindowFullscreen();
}

void setIsFullscreen(bool value) {
    version (WebAssembly) {
        // NOTE: Add Emscripten code later.
    } else {
        if (_backendState.windowIsChanging) return;
        if (value && !isFullscreen) {
            _backendState.windowPreviousWindowWidth = rl.GetScreenWidth();
            _backendState.windowPreviousWindowHeight = rl.GetScreenHeight();
            rl.SetWindowPosition(0, 0);
            rl.SetWindowSize(screenWidth, screenHeight);
        }
        _backendState.windowChangeTime = 0.0f;
        _backendState.windowIsChanging = true;
    }
}

void updateIsFullscreen() {
    enum changeDuration = 0.03f;

    if (!_backendState.windowIsChanging) return;
    _backendState.windowChangeTime += deltaTime;
    if (_backendState.windowChangeTime >= changeDuration) {
        if (isFullscreen) {
            // Size is first because raylib likes that. I will make raylib happy.
            rl.ToggleFullscreen();
            rl.SetWindowSize(
                _backendState.windowPreviousWindowWidth,
                _backendState.windowPreviousWindowHeight,
            );
            rl.SetWindowPosition(
                cast(int) (screenWidth * 0.5f - _backendState.windowPreviousWindowWidth * 0.5f),
                cast(int) (screenHeight * 0.5f - _backendState.windowPreviousWindowHeight * 0.5f),
            );
        } else {
            rl.ToggleFullscreen();
        }
        _backendState.windowIsChanging = false;
    }
}

bool isWindowCloseButtonPressed() {
    version (WebAssembly) {
        return false;
    } else {
        return rl.WindowShouldClose();
    }
}

bool isWindowResized() {
    return rl.IsWindowResized();
}

void setWindowMinSize(int width, int height) {
    rl.SetWindowMinSize(width, height);
}

void setWindowMaxSize(int width, int height) {
    rl.SetWindowMaxSize(width, height);
}

Fault setWindowIconFromFiles(IStr path) {
    auto image = rl.LoadImage(path.toStrz().getOr());
    if (image.data == null) return Fault.cannotFind;
    rl.SetWindowIcon(image);
    rl.UnloadImage(image);
    return Fault.none;
}

void openUrl(IStr url) {
    rl.OpenURL(url.toStrz().getOr());
}

void takeScreenshot(IStr path) {
    // NOTE: Provided fileName should not contain paths, saving to working directory. This is how raylib works.
    rl.TakeScreenshot(path.pathBaseName.toStrz().getOr());
}

int fps() {
    return rl.GetFPS();
}

int fpsMax() {
    return _backendState.fpsMax;
}

void setFpsMax(int value) {
    _backendState.fpsMax = value > 0 ? value : 0;
    rl.SetTargetFPS(_backendState.fpsMax);
}

double elapsedTime() {
    return rl.GetTime();
}

float deltaTime() {
    return rl.GetFrameTime();
}

void setRandomSeed(int value) {
    rl.SetRandomSeed(value);
}

void randomize() {
    setRandomSeed(randi);
}

int randi() {
    return rl.GetRandomValue(0, int.max);
}

float randf() {
    return rl.GetRandomValue(0, cast(int) float.max) / cast(float) cast(int) float.max;
}

Vec2 toCanvasPoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    auto vec = rl.GetWorldToScreen2D(toRl(point), toRl(camera, canvasSize, Rounding.none));
    return Vec2(vec.x, vec.y);
}

Vec2 toScenePoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    auto vec = rl.GetScreenToWorld2D(toRl(point), toRl(camera, canvasSize, Rounding.none));
    return Vec2(vec.x, vec.y);
}

ulong elapsedTicks() {
    return _backendState.elapsedTicks;
}

bool vsync() {
    return _backendState.vsync;
}

void setVsync(bool value) {
    version (WebAssembly) {
        // NOTE: Add Emscripten code later.
    } else {
        if (value == _backendState.vsync) return;
        _backendState.vsyncIsChanging = true;
    }
}

void updateVsync() {
    if (!_backendState.vsyncIsChanging) return;
    // NOTE: Maybe one day we will be able to change vsync, so keep da code.
    _backendState.vsyncIsChanging = false;
}

bool isCursorVisible() {
    return _backendState.isCursorVisible;
}

void setIsCursorVisible(bool value) {
    if (value) rl.ShowCursor();
    else rl.HideCursor();
    _backendState.isCursorVisible = value;
}

// raylib does stuff internally.
// NOTE: No idea if this is a good name.
void pumpEvents() {
    version (WebAssembly) {
        // Check the `_webMouseCallback` function.
    } else {
        auto vec = rl.GetTouchPosition(0);
        _backendState.mouseBuffer = Vec2(vec.x, vec.y);
    }
    _backendState.elapsedTicks += 1;
    updateIsFullscreen();
    updateVsync();
    foreach (id; _backendState.sounds.ids) updateSound(id);
}

bool isDown(char key) => rl.IsKeyDown(toRl(key));
bool isDown(Keyboard key) => rl.IsKeyDown(toRl(key));
bool isDown(Mouse key) => rl.IsMouseButtonDown(toRl(key));
bool isDown(Gamepad key, int id = 0) => rl.IsGamepadButtonDown(id, toRl(key));

bool isPressed(char key) => rl.IsKeyPressed(toRl(key));
bool isPressed(Keyboard key) => rl.IsKeyPressed(toRl(key));
bool isPressed(Mouse key) => rl.IsMouseButtonPressed(toRl(key));
bool isPressed(Gamepad key, int id = 0) => rl.IsGamepadButtonPressed(id, toRl(key));

bool isReleased(char key) => rl.IsKeyReleased(toRl(key));
bool isReleased(Keyboard key) => rl.IsKeyReleased(toRl(key));
bool isReleased(Mouse key) => rl.IsMouseButtonReleased(toRl(key));
bool isReleased(Gamepad key, int id = 0) => rl.IsGamepadButtonReleased(id, toRl(key));

Vec2 mouse() => _backendState.mouseBuffer;
Vec2 deltaMouse() => Vec2(rl.GetMouseDelta().x, rl.GetMouseDelta().y);

// TODO: The value still depends on target. Fix that one day?
float deltaWheel() {
    float result = void;
    version (WebAssembly) {
        result = rl.GetMouseWheelMove();
    } else version (OSX) {
        result = rl.GetMouseWheelMove();
    } else {
        result = -rl.GetMouseWheelMove();
    }
    return result;
}

Keyboard dequeuePressedKey() {
    auto result = cast(Keyboard) rl.GetKeyPressed();
    if (result.toStr() == "?") return Keyboard.none; // NOTE: Could maybe be better, but who cares.
    return result;
}

dchar dequeuePressedRune() {
    return rl.GetCharPressed();
}

float masterVolume() {
    return rl.GetMasterVolume();
}

void setMasterVolume(float value) {
    rl.SetMasterVolume(value);
}

void updateSoundPitchVariance(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (resource.pitchVariance != 1.0f) {
        soundSetPitch(
            id,
            resource.pitchVarianceBase + (resource.pitchVarianceBase * resource.pitchVariance - resource.pitchVarianceBase) * randf,
            false,
        );
    }
}

void activateSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.isActive = true;
    if (resource.data.isType!(rl.Sound)) {
        rl.PlaySound(resource.data.as!(rl.Sound)());
    } else {
        rl.PlayMusicStream(resource.data.as!(rl.Music)());
    }
}

void deactivateSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    resource.isActive = false;
    if (resource.data.isType!(rl.Sound)) {
        rl.StopSound(resource.data.as!(rl.Sound)());
    } else {
        rl.StopMusicStream(resource.data.as!(rl.Music)());
    }
}

void playSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (resource.isActive) return;
    resumeSound(id);
    updateSoundPitchVariance(id);
    activateSound(id);
}

void stopSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (!resource.isActive) return;
    resumeSound(id);
    deactivateSound(id);
}

void startSound(ResourceId id) {
    if (id.resourceIsNull) return;
    stopSound(id);
    playSound(id);
}

void pauseSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (resource.isPaused) return;
    resource.isPaused = true;
    if (resource.data.isType!(rl.Sound)) {
        rl.PauseSound(resource.data.as!(rl.Sound)());
    } else {
        rl.PauseMusicStream(resource.data.as!(rl.Music)());
    }
}

void resumeSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (!resource.isPaused) return;
    resource.isPaused = false;
    if (resource.data.isType!(rl.Sound)) {
        rl.ResumeSound(resource.data.as!(rl.Sound)());
    } else {
        rl.ResumeMusicStream(resource.data.as!(rl.Music)());
    }
}

void updateSound(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.sounds[id];
    if (resource.isPaused || !resource.isActive) return;
    if (resource.data.isType!(rl.Sound)) {
        if (rl.IsSoundPlaying(resource.data.as!(rl.Sound)())) return;
        resource.isActive = false;
        if (resource.canRepeat) playSound(id);
    } else {
        auto isPlayingInternally = rl.IsMusicStreamPlaying(resource.data.as!(rl.Music)());
        auto hasLoopedInternally = soundDuration(id) - soundTime(id) < 0.1f;
        if (hasLoopedInternally) {
            if (resource.canRepeat) {
                updateSoundPitchVariance(id);
            } else {
                stopSound(id);
                isPlayingInternally = false;
            }
        }
        if (isPlayingInternally) rl.UpdateMusicStream(resource.data.as!(rl.Music)());
    }
}

void beginDrawing() {
    rl.BeginDrawing();
}

void endDrawing() {
    rl.EndDrawing();
}

void beginCamera(ref Camera camera, Vec2 canvasSize, Rounding type) {
    camera.isAttached = true;
    rl.BeginMode2D(toRl(camera, canvasSize, type));
}

void endCamera(ref Camera camera) {
    camera.isAttached = false;
    rl.EndMode2D();
}

void beginViewport(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto isEmpty = resource.data.texture.id == 0;
    if (isEmpty) return;
    resource.isAttached = true;
    rl.BeginTextureMode(resource.data);
}

void endViewport(ResourceId id) {
    if (id.resourceIsNull) return;
    auto resource = &_backendState.viewports[id];
    auto isEmpty = resource.data.texture.id == 0;
    if (isEmpty) return;
    resource.isAttached = false;
    rl.EndTextureMode();
}

void beginBlend(Blend blend) {
    rl.BeginBlendMode(toRl(blend));
}

void endBlend() {
    rl.EndBlendMode();
}

void beginClip(Rect area) {
    rl.BeginScissorMode(cast(int) area.position.x, cast(int) area.position.y, cast(int) area.size.x, cast(int) area.size.y);
}

void endClip() {
    rl.EndScissorMode();
}

void clearBackground(Rgba color) {
    rl.ClearBackground(toRl(color));
}

void pushMatrix() {
    rl.rlPushMatrix();
}

void matrixTranslate(float x, float y, float z) {
    rl.rlTranslatef(x, y, z);
}

void matrixRotate(float angle, float x, float y, float z) {
    rl.rlRotatef(angle, x, y, z);
}

void matrixScale(float x, float y, float z) {
    rl.rlScalef(x, y, z);
}

void popMatrix() {
    rl.rlPopMatrix();
}

void drawRect(Rect area, Rgba color, float thickness) {
    if (thickness < 0) {
        rl.DrawRectanglePro(toRl(area), rl.Vector2(0.0f, 0.0f), 0.0f, toRl(color));
    } else {
        rl.DrawRectangleLinesEx(toRl(area), thickness, toRl(color));
    }
}

void drawCirc(Circ area, Rgba color, float thickness) {
    if (thickness < 0) {
        rl.DrawCircleV(toRl(area.position), area.radius, toRl(color));
    } else {
        rl.DrawRing(toRl(area.position), area.radius - thickness, area.radius, 0.0f, 360.0f, 30, toRl(color));
    }
}

void drawLine(Line area, Rgba color, float thickness) {
    rl.DrawLineEx(toRl(area.a), toRl(area.b), thickness, toRl(color));
}

void drawTexture(ResourceId id, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {
    auto resource = &_backendState.textures[id];
    rl.DrawTexturePro(
        resource.data,
        toRl(area),
        toRl(target),
        toRl(origin),
        rotation,
        toRl(color),
    );
}

void drawViewport(ResourceId id, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {
    auto resource = &_backendState.viewports[id];
    rl.DrawTexturePro(
        resource.data.texture,
        toRl(area),
        toRl(target),
        toRl(origin),
        rotation,
        toRl(color),
    );
}

void drawRune(ResourceId id, int rune, Vec2 position, Rgba color) {
    auto resource = &_backendState.fonts[id];
    rl.DrawTextCodepoint(resource.data, rune, toRl(position), resource.data.baseSize, toRl(color));
}

pragma(inline, true) {
    rl.Color toRl(Rgba from) {
        return rl.Color(from.r, from.g, from.b, from.a);
    }

    rl.Vector2 toRl(Vec2 from) {
        return rl.Vector2(from.x, from.y);
    }

    rl.Vector3 toRl(Vec3 from) {
        return rl.Vector3(from.x, from.y, from.z);
    }

    rl.Vector4 toRl(Vec4 from) {
        return rl.Vector4(from.x, from.y, from.z, from.w);
    }

    rl.Rectangle toRl(Rect from) {
        return rl.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
    }

    rl.Camera2D toRl(Camera from, Vec2 canvasSize, Rounding type) {
        return rl.Camera2D(
            Rect(canvasSize).origin(from.isCentered ? Hook.center : Hook.topLeft).applyRounding(type).toRl(),
            from.sum.applyRounding(type).toRl(),
            from.rotation,
            from.scale,
        );
    }

    RlFilter toRl(Filter from) {
        with (Filter) final switch (from) {
            case nearest: return rl.TEXTURE_FILTER_POINT;
            case linear: return rl.TEXTURE_FILTER_BILINEAR;
        }
    }

    RlWrap toRl(Wrap from) {
        with (Wrap) final switch (from) {
            case clamp: return rl.TEXTURE_WRAP_CLAMP;
            case repeat: return rl.TEXTURE_WRAP_REPEAT;
        }
    }

    RlBlend toRl(Blend from) {
        with (Blend) final switch (from) {
            case alpha: return rl.BLEND_CUSTOM_SEPARATE;
            case additive: return rl.BLEND_ADDITIVE;
            case multiplied: return rl.BLEND_MULTIPLIED;
            case add: return rl.BLEND_ADD_COLORS;
            case sub: return rl.BLEND_SUBTRACT_COLORS;
        }
    }

    RlKey toRl(char from) {
        return toUpper(from);
    }

    RlKey toRl(Keyboard from) {
        with (Keyboard) final switch (from) {
            case none: return rl.KEY_NULL;
            case apostrophe: return rl.KEY_APOSTROPHE;
            case comma: return rl.KEY_COMMA;
            case minus: return rl.KEY_MINUS;
            case period: return rl.KEY_PERIOD;
            case slash: return rl.KEY_SLASH;
            case n0: return rl.KEY_ZERO;
            case n1: return rl.KEY_ONE;
            case n2: return rl.KEY_TWO;
            case n3: return rl.KEY_THREE;
            case n4: return rl.KEY_FOUR;
            case n5: return rl.KEY_FIVE;
            case n6: return rl.KEY_SIX;
            case n7: return rl.KEY_SEVEN;
            case n8: return rl.KEY_EIGHT;
            case n9: return rl.KEY_NINE;
            case nn0: return rl.KEY_KP_0;
            case nn1: return rl.KEY_KP_1;
            case nn2: return rl.KEY_KP_2;
            case nn3: return rl.KEY_KP_3;
            case nn4: return rl.KEY_KP_4;
            case nn5: return rl.KEY_KP_5;
            case nn6: return rl.KEY_KP_6;
            case nn7: return rl.KEY_KP_7;
            case nn8: return rl.KEY_KP_8;
            case nn9: return rl.KEY_KP_9;
            case semicolon: return rl.KEY_SEMICOLON;
            case equal: return rl.KEY_EQUAL;
            case a: return rl.KEY_A;
            case b: return rl.KEY_B;
            case c: return rl.KEY_C;
            case d: return rl.KEY_D;
            case e: return rl.KEY_E;
            case f: return rl.KEY_F;
            case g: return rl.KEY_G;
            case h: return rl.KEY_H;
            case i: return rl.KEY_I;
            case j: return rl.KEY_J;
            case k: return rl.KEY_K;
            case l: return rl.KEY_L;
            case m: return rl.KEY_M;
            case n: return rl.KEY_N;
            case o: return rl.KEY_O;
            case p: return rl.KEY_P;
            case q: return rl.KEY_Q;
            case r: return rl.KEY_R;
            case s: return rl.KEY_S;
            case t: return rl.KEY_T;
            case u: return rl.KEY_U;
            case v: return rl.KEY_V;
            case w: return rl.KEY_W;
            case x: return rl.KEY_X;
            case y: return rl.KEY_Y;
            case z: return rl.KEY_Z;
            case bracketLeft: return rl.KEY_LEFT_BRACKET;
            case bracketRight: return rl.KEY_RIGHT_BRACKET;
            case backslash: return rl.KEY_BACKSLASH;
            case grave: return rl.KEY_GRAVE;
            case space: return rl.KEY_SPACE;
            case esc: return rl.KEY_ESCAPE;
            case enter: return rl.KEY_ENTER;
            case tab: return rl.KEY_TAB;
            case backspace: return rl.KEY_BACKSPACE;
            case insert: return rl.KEY_INSERT;
            case del: return rl.KEY_DELETE;
            case right: return rl.KEY_RIGHT;
            case left: return rl.KEY_LEFT;
            case down: return rl.KEY_DOWN;
            case up: return rl.KEY_UP;
            case pageUp: return rl.KEY_PAGE_UP;
            case pageDown: return rl.KEY_PAGE_DOWN;
            case home: return rl.KEY_HOME;
            case end: return rl.KEY_END;
            case capsLock: return rl.KEY_CAPS_LOCK;
            case scrollLock: return rl.KEY_SCROLL_LOCK;
            case numLock: return rl.KEY_NUM_LOCK;
            case printScreen: return rl.KEY_PRINT_SCREEN;
            case pause: return rl.KEY_PAUSE;
            case shift: return rl.KEY_LEFT_SHIFT;
            case shiftRight: return rl.KEY_RIGHT_SHIFT;
            case ctrl: return rl.KEY_LEFT_CONTROL;
            case ctrlRight: return rl.KEY_RIGHT_CONTROL;
            case alt: return rl.KEY_LEFT_ALT;
            case altRight: return rl.KEY_RIGHT_ALT;
            case win: return rl.KEY_LEFT_SUPER;
            case winRight: return rl.KEY_RIGHT_SUPER;
            case menu: return rl.KEY_KB_MENU;
            case f1: return rl.KEY_F1;
            case f2: return rl.KEY_F2;
            case f3: return rl.KEY_F3;
            case f4: return rl.KEY_F4;
            case f5: return rl.KEY_F5;
            case f6: return rl.KEY_F6;
            case f7: return rl.KEY_F7;
            case f8: return rl.KEY_F8;
            case f9: return rl.KEY_F9;
            case f10: return rl.KEY_F10;
            case f11: return rl.KEY_F11;
            case f12: return rl.KEY_F12;
        }
    }

    RlKey toRl(Mouse from) {
        with (Mouse) final switch (from) {
            case none: return rl.MOUSE_BUTTON_LEFT; // NOTE: This is funny, but works.
            case left: return rl.MOUSE_BUTTON_LEFT;
            case right: return rl.MOUSE_BUTTON_RIGHT;
            case middle: return rl.MOUSE_BUTTON_MIDDLE;
        }
    }

    RlKey toRl(Gamepad from) {
        with (Gamepad) final switch (from) {
            case none: return rl.GAMEPAD_BUTTON_UNKNOWN;
            case left: return rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT;
            case right: return rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
            case up: return rl.GAMEPAD_BUTTON_LEFT_FACE_UP;
            case down: return rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN;
            case y: return rl.GAMEPAD_BUTTON_RIGHT_FACE_UP;
            case x: return rl.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
            case a: return rl.GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
            case b: return rl.GAMEPAD_BUTTON_RIGHT_FACE_LEFT;
            case lt: return rl.GAMEPAD_BUTTON_LEFT_TRIGGER_2;
            case lb: return rl.GAMEPAD_BUTTON_LEFT_TRIGGER_1;
            case lsb: return rl.GAMEPAD_BUTTON_LEFT_THUMB;
            case rt: return rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_2;
            case rb: return rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_1;
            case rsb: return rl.GAMEPAD_BUTTON_RIGHT_THUMB;
            case back: return rl.GAMEPAD_BUTTON_MIDDLE_LEFT;
            case start: return rl.GAMEPAD_BUTTON_MIDDLE_RIGHT;
            case middle: return rl.GAMEPAD_BUTTON_MIDDLE;
        }
    }
}
