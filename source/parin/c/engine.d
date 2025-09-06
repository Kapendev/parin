// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The C API for the `engine` module. Doesn't include everything.
module parin.c.engine;

import parin.engine;

@safe extern(C):

// -- Texture
bool prTextureIsEmpty(Texture* self) => self.isEmpty;
int prTextureWidth(Texture* self) => self.width;
int prTextureHeight(Texture* self) => self.height;
Vec2 prTextureSize(Texture* self) => self.size;
void prTextureSetFilter(Texture* self, Filter value) => self.setFilter(value);
void prTextureSetWrap(Texture* self, Wrap value) => self.setWrap(value);
void prTextureFree(Texture* self) => self.free();

// -- TextureId
int prTextureIdWidth(TextureId* self) => self.width;
int prTextureIdHeight(TextureId* self) => self.height;
Vec2 prTextureIdSize(TextureId* self) => self.size;
void prTextureIdSetFilter(TextureId* self, Filter value) => self.setFilter(value);
void prTextureIdSetWrap(TextureId* self, Wrap value) => self.setWrap(value);
bool prTextureIdIsValid(TextureId* self) => self.isValid;
TextureId prTextureIdValidate(TextureId* self, IStr message) => self.validate(message);
Texture* prTextureIdGet(TextureId* self) => &self.get();
Texture prTextureIdGetOr(TextureId* self) => self.getOr();
void prTextureIdFree(TextureId* self) => self.free();

// -- Font
bool prFontIsEmpty(Font* self) => self.isEmpty;
int prFontSize(Font* self) => self.size;
void prFontSetFilter(Font* self, Filter value) => self.setFilter(value);
void prFontSetWrap(Font* self, Wrap value) => self.setWrap(value);
void prFontFree(Font* self) => self.free();

// -- FontId
int prFontIdRuneSpacing(FontId* self) => self.runeSpacing;
int prFontIdLineSpacing(FontId* self) => self.lineSpacing;
int prFontIdSize(FontId* self) => self.size;
void prFontIdSetFilter(FontId* self, Filter value) => self.setFilter(value);
void prFontIdSetWrap(FontId* self, Wrap value) => self.setWrap(value);
bool prFontIdIsValid(FontId* self) => self.isValid;
FontId prFontIdValidate(FontId* self, IStr message) => self.validate(message);
Font* prFontIdGet(FontId* self) => &self.get();
Font prFontIdGetOr(FontId* self) => self.getOr();
void prFontIdFree(FontId* self) => self.free();

// -- Sound
bool prSoundIsEmpty(Sound* self) => self.isEmpty;
float prSoundTime(Sound* self) => self.time;
float prSoundDuration(Sound* self) => self.duration;
float prSoundProgress(Sound* self) => self.progress;
void prSoundSetVolume(Sound* self, float value) => self.setVolume(value);
void prSoundSetPitch(Sound* self, float value, bool canUpdatePitchVarianceBase) => self.setPitch(value, canUpdatePitchVarianceBase);
void prSoundSetPan(Sound* self, float value) => self.setPan(value);
void prSoundFree(Sound* self) => self.free();

// -- SoundId
float prSoundIdPitchVariance(SoundId* self) => self.pitchVariance;
void prSoundIdSetPitchVariance(SoundId* self, float value) => self.setPitchVariance(value);
float prSoundIdPitchVarianceBase(SoundId* self) => self.pitchVarianceBase;
void prSoundIdSetPitchVarianceBase(SoundId* self, float value) => self.setPitchVariance(value);
bool prSoundIdCanRepeat(SoundId* self) => self.canRepeat;
bool prSoundIdIsActive(SoundId* self) => self.isActive;
bool prSoundIdIsPaused(SoundId* self) => self.isPaused;
float prSoundIdTime(SoundId* self) => self.time;
float prSoundIdDuration(SoundId* self) => self.duration;
float prSoundIdProgress(SoundId* self) => self.progress;
void prSoundIdSetVolume(SoundId* self, float value) => self.setVolume(value);
void prSoundIdSetPitch(SoundId* self, float value, bool canUpdateBuffer) => self.setPitch(value, canUpdateBuffer);
void prSoundIdSetPan(SoundId* self, float value) => self.setPan(value);
void prSoundIdSetCanRepeat(SoundId* self, bool value) => self.setCanRepeat(value);
bool prSoundIdIsValid(SoundId* self) => self.isValid;
SoundId prSoundIdValidate(SoundId* self, IStr message) => self.validate(message);
Sound* prSoundIdGet(SoundId* self) => &self.get();
Sound prSoundIdGetOr(SoundId* self) => self.getOr();
void prSoundIdFree(SoundId* self) => self.free();

// -- Viewport
bool prViewportIsEmpty(Viewport* self) => self.isEmpty;
int prViewportWidth(Viewport* self) => self.width;
int prViewportHeight(Viewport* self) => self.height;
Vec2 prViewportSize(Viewport* self) => self.size;
void prViewportResize(Viewport* self, int newWidth, int newHeight) => self.resize(newWidth, newHeight);
void prViewportAttach(Viewport* self) => self.attach();
void prViewportDetach(Viewport* self) => self.detach();
void prViewportSetFilter(Viewport* self, Filter value) => self.setFilter(value);
void prViewportSetWrap(Viewport* self, Wrap value) => self.setWrap(value);
void prViewportFree(Viewport* self) => self.free();

// -- Camera
Hook prCameraHook(Camera* self) => self.hook;
Vec2 prCameraOrigin(Camera* self, Viewport viewport) => self.origin(viewport);
Rect prCameraArea(Camera* self, Viewport viewport) => self.area(viewport);
Vec2 prCameraTopLeftPoint(Camera* self) => self.leftPoint;
Vec2 prCameraTopPoint(Camera* self) => self.topPoint;
Vec2 prCameraTopRightPoint(Camera* self) => self.topRightPoint;
Vec2 prCameraLeftPoint(Camera* self) => self.leftPoint;
Vec2 prCameraCenterPoint(Camera* self) => self.centerPoint;
Vec2 prCameraRightPoint(Camera* self) => self.rightPoint;
Vec2 prCameraBottomLeftPoint(Camera* self) => self.bottomLeftPoint;
Vec2 prCameraBottomPoint(Camera* self) => self.bottomPoint;
Vec2 prCameraBottomRightPoint(Camera* self) => self.bottomRightPoint;
void prCameraFollowPosition(Camera* self, Vec2 target, float speed) => self.followPosition(target, speed);
void prCameraFollowPositionWithSlowdown(Camera* self, Vec2 target, float slowdown) => self.followPositionWithSlowdown(target, slowdown);
void prCameraFollowScale(Camera* self, float target, float speed) => self.followScale(target, speed);
void prCameraFollowScaleWithSlowdown(Camera* self, float target, float slowdown) => self.followScaleWithSlowdown(target, slowdown);
void prCameraAttach(Camera* self) => self.attach();
void prCameraDetach(Camera* self) => self.detach();

// -- Functions
void prOpenWindow(int width, int height, int argc, ICStr* argv, ICStr title) => _openWindowC(width, height, argc, argv, title);
void prUpdateWindow(EngineUpdateFunc updateFunc) => _updateWindow(updateFunc);
void prCloseWindow() => _closeWindow();

Font prToFontAscii(Texture from, int tileWidth, int tileHeight) => toFontAscii(from, tileWidth, tileHeight);
TextureId prToTextureId(Texture from) => toTextureId(from);
FontId prToFontId(Font from) => toFontId(from);
SoundId prToSoundId(Sound from) => toSoundId(from);
Fault prLastLoadFault() => lastLoadFault;

Fault prLoadRawTextIntoBuffer(IStr path, LStr* buffer) => loadRawTextIntoBuffer(path, *buffer);
TextureId prLoadTexture(IStr path) => loadTexture(path);
FontId prLoadFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes) => loadFont(path, size, runeSpacing, lineSpacing, runes);
FontId prLoadFontFromTexture(IStr path, int tileWidth, int tileHeight) => loadFontFromTexture(path, tileWidth, tileHeight);
SoundId prLoadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance) => loadSound(path, volume, pitch, canRepeat, pitchVariance);
Fault prSaveText(IStr path, IStr text) => saveText(path, text);

int prScreenWidth() => screenWidth;
int prScreenHeight() => screenHeight;
Vec2 prScreenSize() => screenSize;
int prWindowWidth() => windowWidth;
int prWindowHeight() => windowHeight;
Vec2 prWindowSize() => windowSize;
int prResolutionWidth() => resolutionWidth;
int prResolutionHeight() => resolutionHeight;
Vec2 prResolution() => resolution;

Vec2 prMouse() => mouse;
Vec2 prDeltaMouse() => deltaMouse;
float prDeltaWheel() => deltaWheel;

bool prIsDown(char key) => isDown(key);
bool prIsDownKey(Keyboard key) => isDown(key);
bool prIsDownMouse(Mouse key) => isDown(key);
bool prIsDownGamepad(Gamepad key, int id = 0) => isDown(key, id);
bool prIsPressed(char key) => isPressed(key);
bool prIsPressedKey(Keyboard key) => isPressed(key);
bool prIsPressedMouse(Mouse key) => isPressed(key);
bool prIsPressedGamepad(Gamepad key, int id = 0) => isPressed(key, id);
bool prIsReleased(char key) => isReleased(key);
bool prIsReleasedKey(Keyboard key) => isReleased(key);
bool prIsReleasedMouse(Mouse key) => isReleased(key);
bool prIsReleasedGamepad(Gamepad key, int id = 0) => isReleased(key, id);
Keyboard prDequeuePressedKey() => dequeuePressedKey();
dchar prDequeuePressedRune() => dequeuePressedRune();

Vec2 prMeasureTextSize(Font font, IStr text, DrawOptions options, TextOptions extra) => measureTextSize(font, text, options, extra);
Vec2 prMeasureTextSizeId(FontId font, IStr text, DrawOptions options, TextOptions extra) => measureTextSize(font, text, options, extra);

void prDrawRect(Rect area, Rgba color) => drawRect(area, color);
void prDrawHollowRect(Rect area, float thickness, Rgba color) => drawHollowRect(area, thickness, color);
void prDrawVec2(Vec2 point, float size, Rgba color) => drawVec2(point, size, color);
void prDrawCirc(Circ area, Rgba color) => drawCirc(area, color);
void prDrawHollowCirc(Circ area, float thickness, Rgba color) => drawHollowCirc(area, thickness, color);
void prDrawLine(Line area, float size, Rgba color) => drawLine(area, size, color);
void prDrawTexture(Texture texture, Vec2 position, DrawOptions options) => drawTexture(texture, position, options);
void prDrawTextureId(TextureId texture, Vec2 position, DrawOptions options) => drawTexture(texture, position, options);
void prDrawTextureArea(Texture texture, Rect area, Vec2 position, DrawOptions options) => drawTextureArea(texture, area, position, options);
void prDrawTextureAreaId(TextureId texture, Rect area, Vec2 position, DrawOptions options) => drawTextureArea(texture, area, position, options);
void prDrawTextureAreaDf(Rect area, Vec2 position, DrawOptions options) => drawTextureArea(area, position, options);
void prDrawTextureSlice(Texture texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options) => drawTextureSlice(texture, area, target, margin, canRepeat, options);
void prDrawTextureSliceId(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options) => drawTextureSlice(texture, area, target, margin, canRepeat, options);
void prDrawTextureSliceDf(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options) => drawTextureSlice(area, target, margin, canRepeat, options);
void prDrawViewportArea(Viewport viewport, Rect area, Vec2 position, DrawOptions options) => drawViewportArea(viewport, area, position, options);
void prDrawViewport(Viewport viewport, Vec2 position, DrawOptions options) => drawViewport(viewport, position, options);
void prDrawRune(Font font, dchar rune, Vec2 position, DrawOptions options) => drawRune(font, rune, position, options);
void prDrawRuneId(FontId font, dchar rune, Vec2 position, DrawOptions options) => drawRune(font, rune, position, options);
void prDrawRuneDf(dchar rune, Vec2 position, DrawOptions options) => drawRune(rune, position, options);
void prDrawText(Font font, IStr text, Vec2 position, DrawOptions options, TextOptions extra) => drawText(font, text, position, options, extra);
void prDrawTextId(FontId font, IStr text, Vec2 position, DrawOptions options, TextOptions extra) => drawText(font, text, position, options, extra);
void prDrawTextDf(IStr text, Vec2 position, DrawOptions options, TextOptions extra) => drawText(text, position, options, extra);
void prDrawDebugEngineInfo(Vec2 screenPoint, Camera camera, DrawOptions options, bool isLogging = false) => drawDebugEngineInfo(screenPoint, camera, options, isLogging);
void prDrawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera, DrawOptions options, bool isLogging = false) => drawDebugTileInfo(tileWidth, tileHeight, screenPoint, camera, options, isLogging);
