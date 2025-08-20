// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `rlgl` module provides access to the rlgl.h functions.
module parin.rl.rlgl;

nothrow @nogc extern(C):

enum RLGL_VERSION = "4.5";

enum RL_DEFAULT_BATCH_BUFFER_ELEMENTS = 8192;
enum RL_DEFAULT_BATCH_BUFFERS = 1; // Default number of batch buffers (multi-buffering)
enum RL_DEFAULT_BATCH_DRAWCALLS = 256; // Default number of batch draw calls (by state changes: mode, texture)
enum RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS = 4; // Maximum number of textures units that can be activated on batch drawing (SetShaderValueTexture())

// Internal Matrix stack
enum RL_MAX_MATRIX_STACK_SIZE = 32; // Maximum size of Matrix stack

// Shader limits
enum RL_MAX_SHADER_LOCATIONS = 32; // Maximum number of shader locations supported

// Projection matrix culling
enum RL_CULL_DISTANCE_NEAR = 0.01; // Default near cull distance
enum RL_CULL_DISTANCE_FAR = 1000.0; // Default far cull distance

// Texture parameters (equivalent to OpenGL defines)
enum RL_TEXTURE_WRAP_S = 0x2802; // GL_TEXTURE_WRAP_S
enum RL_TEXTURE_WRAP_T = 0x2803; // GL_TEXTURE_WRAP_T
enum RL_TEXTURE_MAG_FILTER = 0x2800; // GL_TEXTURE_MAG_FILTER
enum RL_TEXTURE_MIN_FILTER = 0x2801; // GL_TEXTURE_MIN_FILTER

enum RL_TEXTURE_FILTER_NEAREST = 0x2600; // GL_NEAREST
enum RL_TEXTURE_FILTER_LINEAR = 0x2601; // GL_LINEAR
enum RL_TEXTURE_FILTER_MIP_NEAREST = 0x2700; // GL_NEAREST_MIPMAP_NEAREST
enum RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR = 0x2702; // GL_NEAREST_MIPMAP_LINEAR
enum RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST = 0x2701; // GL_LINEAR_MIPMAP_NEAREST
enum RL_TEXTURE_FILTER_MIP_LINEAR = 0x2703; // GL_LINEAR_MIPMAP_LINEAR
enum RL_TEXTURE_FILTER_ANISOTROPIC = 0x3000; // Anisotropic filter (custom identifier)
enum RL_TEXTURE_MIPMAP_BIAS_RATIO = 0x4000; // Texture mipmap bias, percentage ratio (custom identifier)

enum RL_TEXTURE_WRAP_REPEAT = 0x2901; // GL_REPEAT
enum RL_TEXTURE_WRAP_CLAMP = 0x812F; // GL_CLAMP_TO_EDGE
enum RL_TEXTURE_WRAP_MIRROR_REPEAT = 0x8370; // GL_MIRRORED_REPEAT
enum RL_TEXTURE_WRAP_MIRROR_CLAMP = 0x8742; // GL_MIRROR_CLAMP_EXT

// Matrix modes (equivalent to OpenGL)
enum RL_MODELVIEW = 0x1700; // GL_MODELVIEW
enum RL_PROJECTION = 0x1701; // GL_PROJECTION
enum RL_TEXTURE = 0x1702; // GL_TEXTURE

// Primitive assembly draw modes
enum RL_LINES = 0x0001; // GL_LINES
enum RL_TRIANGLES = 0x0004; // GL_TRIANGLES
enum RL_QUADS = 0x0007; // GL_QUADS

// GL equivalent data types
enum RL_UNSIGNED_BYTE = 0x1401; // GL_UNSIGNED_BYTE
enum RL_FLOAT = 0x1406; // GL_FLOAT

// GL buffer usage hint
enum RL_STREAM_DRAW = 0x88E0; // GL_STREAM_DRAW
enum RL_STREAM_READ = 0x88E1; // GL_STREAM_READ
enum RL_STREAM_COPY = 0x88E2; // GL_STREAM_COPY
enum RL_STATIC_DRAW = 0x88E4; // GL_STATIC_DRAW
enum RL_STATIC_READ = 0x88E5; // GL_STATIC_READ
enum RL_STATIC_COPY = 0x88E6; // GL_STATIC_COPY
enum RL_DYNAMIC_DRAW = 0x88E8; // GL_DYNAMIC_DRAW
enum RL_DYNAMIC_READ = 0x88E9; // GL_DYNAMIC_READ
enum RL_DYNAMIC_COPY = 0x88EA; // GL_DYNAMIC_COPY

// GL Shader type
enum RL_FRAGMENT_SHADER = 0x8B30; // GL_FRAGMENT_SHADER
enum RL_VERTEX_SHADER = 0x8B31; // GL_VERTEX_SHADER
enum RL_COMPUTE_SHADER = 0x91B9; // GL_COMPUTE_SHADER

// GL blending factors
enum RL_ZERO = 0; // GL_ZERO
enum RL_ONE = 1; // GL_ONE
enum RL_SRC_COLOR = 0x0300; // GL_SRC_COLOR
enum RL_ONE_MINUS_SRC_COLOR = 0x0301; // GL_ONE_MINUS_SRC_COLOR
enum RL_SRC_ALPHA = 0x0302; // GL_SRC_ALPHA
enum RL_ONE_MINUS_SRC_ALPHA = 0x0303; // GL_ONE_MINUS_SRC_ALPHA
enum RL_DST_ALPHA = 0x0304; // GL_DST_ALPHA
enum RL_ONE_MINUS_DST_ALPHA = 0x0305; // GL_ONE_MINUS_DST_ALPHA
enum RL_DST_COLOR = 0x0306; // GL_DST_COLOR
enum RL_ONE_MINUS_DST_COLOR = 0x0307; // GL_ONE_MINUS_DST_COLOR
enum RL_SRC_ALPHA_SATURATE = 0x0308; // GL_SRC_ALPHA_SATURATE
enum RL_CONSTANT_COLOR = 0x8001; // GL_CONSTANT_COLOR
enum RL_ONE_MINUS_CONSTANT_COLOR = 0x8002; // GL_ONE_MINUS_CONSTANT_COLOR
enum RL_CONSTANT_ALPHA = 0x8003; // GL_CONSTANT_ALPHA
enum RL_ONE_MINUS_CONSTANT_ALPHA = 0x8004; // GL_ONE_MINUS_CONSTANT_ALPHA

// GL blending functions/equations
enum RL_FUNC_ADD = 0x8006; // GL_FUNC_ADD
enum RL_MIN = 0x8007; // GL_MIN
enum RL_MAX = 0x8008; // GL_MAX
enum RL_FUNC_SUBTRACT = 0x800A; // GL_FUNC_SUBTRACT
enum RL_FUNC_REVERSE_SUBTRACT = 0x800B; // GL_FUNC_REVERSE_SUBTRACT
enum RL_BLEND_EQUATION = 0x8009; // GL_BLEND_EQUATION
enum RL_BLEND_EQUATION_RGB = 0x8009; // GL_BLEND_EQUATION_RGB   // (Same as BLEND_EQUATION)
enum RL_BLEND_EQUATION_ALPHA = 0x883D; // GL_BLEND_EQUATION_ALPHA
enum RL_BLEND_DST_RGB = 0x80C8; // GL_BLEND_DST_RGB
enum RL_BLEND_SRC_RGB = 0x80C9; // GL_BLEND_SRC_RGB
enum RL_BLEND_DST_ALPHA = 0x80CA; // GL_BLEND_DST_ALPHA
enum RL_BLEND_SRC_ALPHA = 0x80CB; // GL_BLEND_SRC_ALPHA
enum RL_BLEND_COLOR = 0x8005; // GL_BLEND_COLOR

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

// Boolean type

// Matrix, 4x4 components, column major, OpenGL style, right handed
struct Matrix
{
    float m0 = 0.0f;
    float m4 = 0.0f;
    float m8 = 0.0f;
    float m12 = 0.0f; // Matrix first row (4 components)
    float m1 = 0.0f;
    float m5 = 0.0f;
    float m9 = 0.0f;
    float m13 = 0.0f; // Matrix second row (4 components)
    float m2 = 0.0f;
    float m6 = 0.0f;
    float m10 = 0.0f;
    float m14 = 0.0f; // Matrix third row (4 components)
    float m3 = 0.0f;
    float m7 = 0.0f;
    float m11 = 0.0f;
    float m15 = 0.0f; // Matrix fourth row (4 components)
}

// Dynamic vertex buffers (position + texcoords + colors + indices arrays)
struct rlVertexBuffer
{
    int elementCount; // Number of elements in the buffer (QUADS)

    float* vertices; // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    float* texcoords; // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    ubyte* colors; // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)

    uint* indices; // Vertex indices (in case vertex data comes indexed) (6 indices per quad)

    // Vertex indices (in case vertex data comes indexed) (6 indices per quad)

    uint vaoId; // OpenGL Vertex Array Object id
    uint[4] vboId; // OpenGL Vertex Buffer Objects id (4 types of vertex data)
}

// Draw call type
// used at this moment (vaoId, shaderId, matrices), raylib just forces a batch draw call if any
// of those state-change happens (this is done in core module)
struct rlDrawCall
{
    int mode; // Drawing mode: LINES, TRIANGLES, QUADS
    int vertexCount; // Number of vertex of the draw
    int vertexAlignment; // Number of vertex required for index alignment (LINES, TRIANGLES)
    //unsigned int vaoId;       // Vertex array id to be used on the draw -> Using RLGL.currentBatch->vertexBuffer.vaoId
    //unsigned int shaderId;    // Shader id to be used on the draw -> Using RLGL.currentShaderId
    uint textureId; // Texture id to be used on the draw -> Use to create new draw call if changes

    //Matrix projection;        // Projection matrix for this draw -> Using RLGL.projection by default
    //Matrix modelview;         // Modelview matrix for this draw -> Using RLGL.modelview by default
}

// rlRenderBatch type
struct rlRenderBatch
{
    int bufferCount; // Number of vertex buffers (multi-buffering support)
    int currentBuffer; // Current buffer tracking in case of multi-buffering
    rlVertexBuffer* vertexBuffer; // Dynamic buffer(s) for vertex data

    rlDrawCall* draws; // Draw calls array, depends on textureId
    int drawCounter; // Draw calls counter
    float currentDepth = 0.0f; // Current depth value for next draw
}

// OpenGL version
enum
{
    RL_OPENGL_11 = 1, // OpenGL 1.1
    RL_OPENGL_21 = 2, // OpenGL 2.1 (GLSL 120)
    RL_OPENGL_33 = 3, // OpenGL 3.3 (GLSL 330)
    RL_OPENGL_43 = 4, // OpenGL 4.3 (using GLSL 330)
    RL_OPENGL_ES_20 = 5, // OpenGL ES 2.0 (GLSL 100)
    RL_OPENGL_ES_30 = 6 // OpenGL ES 3.0 (GLSL 300 es)
}

// Trace log level
enum
{
    RL_LOG_ALL = 0, // Display all logs
    RL_LOG_TRACE = 1, // Trace logging, intended for internal use only
    RL_LOG_DEBUG = 2, // Debug logging, used for internal debugging, it should be disabled on release builds
    RL_LOG_INFO = 3, // Info logging, used for program execution info
    RL_LOG_WARNING = 4, // Warning logging, used on recoverable failures
    RL_LOG_ERROR = 5, // Error logging, used on unrecoverable failures
    RL_LOG_FATAL = 6, // Fatal logging, used to abort program: exit(EXIT_FAILURE)
    RL_LOG_NONE = 7 // Disable logging
}

// Texture pixel formats
enum
{
    RL_PIXELFORMAT_UNCOMPRESSED_GRAYSCALE = 1, // 8 bit per pixel (no alpha)
    RL_PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA = 2, // 8*2 bpp (2 channels)
    RL_PIXELFORMAT_UNCOMPRESSED_R5G6B5 = 3, // 16 bpp
    RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8 = 4, // 24 bpp
    RL_PIXELFORMAT_UNCOMPRESSED_R5G5B5A1 = 5, // 16 bpp (1 bit alpha)
    RL_PIXELFORMAT_UNCOMPRESSED_R4G4B4A4 = 6, // 16 bpp (4 bit alpha)
    RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 = 7, // 32 bpp
    RL_PIXELFORMAT_UNCOMPRESSED_R32 = 8, // 32 bpp (1 channel - float)
    RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32 = 9, // 32*3 bpp (3 channels - float)
    RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32A32 = 10, // 32*4 bpp (4 channels - float)
    RL_PIXELFORMAT_UNCOMPRESSED_R16 = 11, // 16 bpp (1 channel - half float)
    RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16 = 12, // 16*3 bpp (3 channels - half float)
    RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16A16 = 13, // 16*4 bpp (4 channels - half float)
    RL_PIXELFORMAT_COMPRESSED_DXT1_RGB = 14, // 4 bpp (no alpha)
    RL_PIXELFORMAT_COMPRESSED_DXT1_RGBA = 15, // 4 bpp (1 bit alpha)
    RL_PIXELFORMAT_COMPRESSED_DXT3_RGBA = 16, // 8 bpp
    RL_PIXELFORMAT_COMPRESSED_DXT5_RGBA = 17, // 8 bpp
    RL_PIXELFORMAT_COMPRESSED_ETC1_RGB = 18, // 4 bpp
    RL_PIXELFORMAT_COMPRESSED_ETC2_RGB = 19, // 4 bpp
    RL_PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA = 20, // 8 bpp
    RL_PIXELFORMAT_COMPRESSED_PVRT_RGB = 21, // 4 bpp
    RL_PIXELFORMAT_COMPRESSED_PVRT_RGBA = 22, // 4 bpp
    RL_PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA = 23, // 8 bpp
    RL_PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA = 24 // 2 bpp
}

// Texture parameters: filter mode
enum
{
    RL_TEXTURE_FILTER_POINT = 0, // No filter, just pixel approximation
    RL_TEXTURE_FILTER_BILINEAR = 1, // Linear filtering
    RL_TEXTURE_FILTER_TRILINEAR = 2, // Trilinear filtering (linear with mipmaps)
    RL_TEXTURE_FILTER_ANISOTROPIC_4X = 3, // Anisotropic filtering 4x
    RL_TEXTURE_FILTER_ANISOTROPIC_8X = 4, // Anisotropic filtering 8x
    RL_TEXTURE_FILTER_ANISOTROPIC_16X = 5 // Anisotropic filtering 16x
}

// Color blending modes (pre-defined)
enum
{
    RL_BLEND_ALPHA = 0, // Blend textures considering alpha (default)
    RL_BLEND_ADDITIVE = 1, // Blend textures adding colors
    RL_BLEND_MULTIPLIED = 2, // Blend textures multiplying colors
    RL_BLEND_ADD_COLORS = 3, // Blend textures adding colors (alternative)
    RL_BLEND_SUBTRACT_COLORS = 4, // Blend textures subtracting colors (alternative)
    RL_BLEND_ALPHA_PREMULTIPLY = 5, // Blend premultiplied textures considering alpha
    RL_BLEND_CUSTOM = 6, // Blend textures using custom src/dst factors (use rlSetBlendFactors())
    RL_BLEND_CUSTOM_SEPARATE = 7 // Blend textures using custom src/dst factors (use rlSetBlendFactorsSeparate())
}

// Shader location point type
enum
{
    RL_SHADER_LOC_VERTEX_POSITION = 0, // Shader location: vertex attribute: position
    RL_SHADER_LOC_VERTEX_TEXCOORD01 = 1, // Shader location: vertex attribute: texcoord01
    RL_SHADER_LOC_VERTEX_TEXCOORD02 = 2, // Shader location: vertex attribute: texcoord02
    RL_SHADER_LOC_VERTEX_NORMAL = 3, // Shader location: vertex attribute: normal
    RL_SHADER_LOC_VERTEX_TANGENT = 4, // Shader location: vertex attribute: tangent
    RL_SHADER_LOC_VERTEX_COLOR = 5, // Shader location: vertex attribute: color
    RL_SHADER_LOC_MATRIX_MVP = 6, // Shader location: matrix uniform: model-view-projection
    RL_SHADER_LOC_MATRIX_VIEW = 7, // Shader location: matrix uniform: view (camera transform)
    RL_SHADER_LOC_MATRIX_PROJECTION = 8, // Shader location: matrix uniform: projection
    RL_SHADER_LOC_MATRIX_MODEL = 9, // Shader location: matrix uniform: model (transform)
    RL_SHADER_LOC_MATRIX_NORMAL = 10, // Shader location: matrix uniform: normal
    RL_SHADER_LOC_VECTOR_VIEW = 11, // Shader location: vector uniform: view
    RL_SHADER_LOC_COLOR_DIFFUSE = 12, // Shader location: vector uniform: diffuse color
    RL_SHADER_LOC_COLOR_SPECULAR = 13, // Shader location: vector uniform: specular color
    RL_SHADER_LOC_COLOR_AMBIENT = 14, // Shader location: vector uniform: ambient color
    RL_SHADER_LOC_MAP_ALBEDO = 15, // Shader location: sampler2d texture: albedo (same as: RL_SHADER_LOC_MAP_DIFFUSE)
    RL_SHADER_LOC_MAP_METALNESS = 16, // Shader location: sampler2d texture: metalness (same as: RL_SHADER_LOC_MAP_SPECULAR)
    RL_SHADER_LOC_MAP_NORMAL = 17, // Shader location: sampler2d texture: normal
    RL_SHADER_LOC_MAP_ROUGHNESS = 18, // Shader location: sampler2d texture: roughness
    RL_SHADER_LOC_MAP_OCCLUSION = 19, // Shader location: sampler2d texture: occlusion
    RL_SHADER_LOC_MAP_EMISSION = 20, // Shader location: sampler2d texture: emission
    RL_SHADER_LOC_MAP_HEIGHT = 21, // Shader location: sampler2d texture: height
    RL_SHADER_LOC_MAP_CUBEMAP = 22, // Shader location: samplerCube texture: cubemap
    RL_SHADER_LOC_MAP_IRRADIANCE = 23, // Shader location: samplerCube texture: irradiance
    RL_SHADER_LOC_MAP_PREFILTER = 24, // Shader location: samplerCube texture: prefilter
    RL_SHADER_LOC_MAP_BRDF = 25 // Shader location: sampler2d texture: brdf
}

enum RL_SHADER_LOC_MAP_DIFFUSE = RL_SHADER_LOC_MAP_ALBEDO;
enum RL_SHADER_LOC_MAP_SPECULAR = RL_SHADER_LOC_MAP_METALNESS;

// Shader uniform data type
enum
{
    RL_SHADER_UNIFORM_FLOAT = 0, // Shader uniform type: float
    RL_SHADER_UNIFORM_VEC2 = 1, // Shader uniform type: vec2 (2 float)
    RL_SHADER_UNIFORM_VEC3 = 2, // Shader uniform type: vec3 (3 float)
    RL_SHADER_UNIFORM_VEC4 = 3, // Shader uniform type: vec4 (4 float)
    RL_SHADER_UNIFORM_INT = 4, // Shader uniform type: int
    RL_SHADER_UNIFORM_IVEC2 = 5, // Shader uniform type: ivec2 (2 int)
    RL_SHADER_UNIFORM_IVEC3 = 6, // Shader uniform type: ivec3 (3 int)
    RL_SHADER_UNIFORM_IVEC4 = 7, // Shader uniform type: ivec4 (4 int)
    RL_SHADER_UNIFORM_SAMPLER2D = 8 // Shader uniform type: sampler2d
}

// Shader attribute data types
enum
{
    RL_SHADER_ATTRIB_FLOAT = 0, // Shader attribute type: float
    RL_SHADER_ATTRIB_VEC2 = 1, // Shader attribute type: vec2 (2 float)
    RL_SHADER_ATTRIB_VEC3 = 2, // Shader attribute type: vec3 (3 float)
    RL_SHADER_ATTRIB_VEC4 = 3 // Shader attribute type: vec4 (4 float)
}

// Framebuffer attachment type
enum
{
    RL_ATTACHMENT_COLOR_CHANNEL0 = 0, // Framebuffer attachment type: color 0
    RL_ATTACHMENT_COLOR_CHANNEL1 = 1, // Framebuffer attachment type: color 1
    RL_ATTACHMENT_COLOR_CHANNEL2 = 2, // Framebuffer attachment type: color 2
    RL_ATTACHMENT_COLOR_CHANNEL3 = 3, // Framebuffer attachment type: color 3
    RL_ATTACHMENT_COLOR_CHANNEL4 = 4, // Framebuffer attachment type: color 4
    RL_ATTACHMENT_COLOR_CHANNEL5 = 5, // Framebuffer attachment type: color 5
    RL_ATTACHMENT_COLOR_CHANNEL6 = 6, // Framebuffer attachment type: color 6
    RL_ATTACHMENT_COLOR_CHANNEL7 = 7, // Framebuffer attachment type: color 7
    RL_ATTACHMENT_DEPTH = 100, // Framebuffer attachment type: depth
    RL_ATTACHMENT_STENCIL = 200 // Framebuffer attachment type: stencil
}

// Framebuffer texture attachment type
enum
{
    RL_ATTACHMENT_CUBEMAP_POSITIVE_X = 0, // Framebuffer texture attachment type: cubemap, +X side
    RL_ATTACHMENT_CUBEMAP_NEGATIVE_X = 1, // Framebuffer texture attachment type: cubemap, -X side
    RL_ATTACHMENT_CUBEMAP_POSITIVE_Y = 2, // Framebuffer texture attachment type: cubemap, +Y side
    RL_ATTACHMENT_CUBEMAP_NEGATIVE_Y = 3, // Framebuffer texture attachment type: cubemap, -Y side
    RL_ATTACHMENT_CUBEMAP_POSITIVE_Z = 4, // Framebuffer texture attachment type: cubemap, +Z side
    RL_ATTACHMENT_CUBEMAP_NEGATIVE_Z = 5, // Framebuffer texture attachment type: cubemap, -Z side
    RL_ATTACHMENT_TEXTURE2D = 100, // Framebuffer texture attachment type: texture2d
    RL_ATTACHMENT_RENDERBUFFER = 200 // Framebuffer texture attachment type: renderbuffer
}

// Face culling mode
enum
{
    RL_CULL_FACE_FRONT = 0,
    RL_CULL_FACE_BACK = 1
}

//------------------------------------------------------------------------------------
// Functions Declaration - Matrix operations
//------------------------------------------------------------------------------------

// Prevents name mangling of functions

void rlMatrixMode (int mode); // Choose the current matrix to be transformed
void rlPushMatrix (); // Push the current matrix to stack
void rlPopMatrix (); // Pop latest inserted matrix from stack
void rlLoadIdentity (); // Reset current matrix to identity matrix
void rlTranslatef (float x, float y, float z); // Multiply the current matrix by a translation matrix
void rlRotatef (float angle, float x, float y, float z); // Multiply the current matrix by a rotation matrix
void rlScalef (float x, float y, float z); // Multiply the current matrix by a scaling matrix
void rlMultMatrixf (const(float)* matf); // Multiply the current matrix by another matrix
void rlFrustum (double left, double right, double bottom, double top, double znear, double zfar);
void rlOrtho (double left, double right, double bottom, double top, double znear, double zfar);
void rlViewport (int x, int y, int width, int height); // Set the viewport area

//------------------------------------------------------------------------------------
// Functions Declaration - Vertex level operations
//------------------------------------------------------------------------------------
void rlBegin (int mode); // Initialize drawing mode (how to organize vertex)
void rlEnd (); // Finish vertex providing
void rlVertex2i (int x, int y); // Define one vertex (position) - 2 int
void rlVertex2f (float x, float y); // Define one vertex (position) - 2 float
void rlVertex3f (float x, float y, float z); // Define one vertex (position) - 3 float
void rlTexCoord2f (float x, float y); // Define one vertex (texture coordinate) - 2 float
void rlNormal3f (float x, float y, float z); // Define one vertex (normal) - 3 float
void rlColor4ub (ubyte r, ubyte g, ubyte b, ubyte a); // Define one vertex (color) - 4 byte
void rlColor3f (float x, float y, float z); // Define one vertex (color) - 3 float
void rlColor4f (float x, float y, float z, float w); // Define one vertex (color) - 4 float

//------------------------------------------------------------------------------------
// Functions Declaration - OpenGL style functions (common to 1.1, 3.3+, ES2)
// some of them are direct wrappers over OpenGL calls, some others are custom
//------------------------------------------------------------------------------------

// Vertex buffers state
bool rlEnableVertexArray (uint vaoId); // Enable vertex array (VAO, if supported)
void rlDisableVertexArray (); // Disable vertex array (VAO, if supported)
void rlEnableVertexBuffer (uint id); // Enable vertex buffer (VBO)
void rlDisableVertexBuffer (); // Disable vertex buffer (VBO)
void rlEnableVertexBufferElement (uint id); // Enable vertex buffer element (VBO element)
void rlDisableVertexBufferElement (); // Disable vertex buffer element (VBO element)
void rlEnableVertexAttribute (uint index); // Enable vertex attribute index
void rlDisableVertexAttribute (uint index); // Disable vertex attribute index

// Enable attribute state pointer
// Disable attribute state pointer

// Textures state
void rlActiveTextureSlot (int slot); // Select and active a texture slot
void rlEnableTexture (uint id); // Enable texture
void rlDisableTexture (); // Disable texture
void rlEnableTextureCubemap (uint id); // Enable texture cubemap
void rlDisableTextureCubemap (); // Disable texture cubemap
void rlTextureParameters (uint id, int param, int value); // Set texture parameters (filter, wrap)
void rlCubemapParameters (uint id, int param, int value); // Set cubemap parameters (filter, wrap)

// Shader state
void rlEnableShader (uint id); // Enable shader program
void rlDisableShader (); // Disable shader program

// Framebuffer state
void rlEnableFramebuffer (uint id); // Enable render texture (fbo)
void rlDisableFramebuffer (); // Disable render texture (fbo), return to default framebuffer
void rlActiveDrawBuffers (int count); // Activate multiple draw color buffers
void rlBlitFramebuffer (int srcX, int srcY, int srcWidth, int srcHeight, int dstX, int dstY, int dstWidth, int dstHeight, int bufferMask); // Blit active framebuffer to main framebuffer

// General render state
void rlEnableColorBlend (); // Enable color blending
void rlDisableColorBlend (); // Disable color blending
void rlEnableDepthTest (); // Enable depth test
void rlDisableDepthTest (); // Disable depth test
void rlEnableDepthMask (); // Enable depth write
void rlDisableDepthMask (); // Disable depth write
void rlEnableBackfaceCulling (); // Enable backface culling
void rlDisableBackfaceCulling (); // Disable backface culling
void rlSetCullFace (int mode); // Set face culling mode
void rlEnableScissorTest (); // Enable scissor test
void rlDisableScissorTest (); // Disable scissor test
void rlScissor (int x, int y, int width, int height); // Scissor test
void rlEnableWireMode (); // Enable wire mode
void rlEnablePointMode (); //  Enable point mode
void rlDisableWireMode (); // Disable wire mode ( and point ) maybe rename
void rlSetLineWidth (float width); // Set the line drawing width
float rlGetLineWidth (); // Get the line drawing width
void rlEnableSmoothLines (); // Enable line aliasing
void rlDisableSmoothLines (); // Disable line aliasing
void rlEnableStereoRender (); // Enable stereo rendering
void rlDisableStereoRender (); // Disable stereo rendering
bool rlIsStereoRenderEnabled (); // Check if stereo render is enabled

void rlClearColor (ubyte r, ubyte g, ubyte b, ubyte a); // Clear color buffer with color
void rlClearScreenBuffers (); // Clear used screen buffers (color and depth)
void rlCheckErrors (); // Check and log OpenGL error codes
void rlSetBlendMode (int mode); // Set blending mode
void rlSetBlendFactors (int glSrcFactor, int glDstFactor, int glEquation); // Set blending mode factor and equation (using OpenGL factors)
void rlSetBlendFactorsSeparate (int glSrcRGB, int glDstRGB, int glSrcAlpha, int glDstAlpha, int glEqRGB, int glEqAlpha); // Set blending mode factors and equations separately (using OpenGL factors)

//------------------------------------------------------------------------------------
// Functions Declaration - rlgl functionality
//------------------------------------------------------------------------------------
// rlgl initialization functions
void rlglInit (int width, int height); // Initialize rlgl (buffers, shaders, textures, states)
void rlglClose (); // De-initialize rlgl (buffers, shaders, textures)
void rlLoadExtensions (void* loader); // Load OpenGL extensions (loader function required)
int rlGetVersion (); // Get current OpenGL version
void rlSetFramebufferWidth (int width); // Set current framebuffer width
int rlGetFramebufferWidth (); // Get default framebuffer width
void rlSetFramebufferHeight (int height); // Set current framebuffer height
int rlGetFramebufferHeight (); // Get default framebuffer height

uint rlGetTextureIdDefault (); // Get default texture id
uint rlGetShaderIdDefault (); // Get default shader id
int* rlGetShaderLocsDefault (); // Get default shader locations

// Render batch management
// but this render batch API is exposed in case of custom batches are required
rlRenderBatch rlLoadRenderBatch (int numBuffers, int bufferElements); // Load a render batch system
void rlUnloadRenderBatch (rlRenderBatch batch); // Unload render batch system
void rlDrawRenderBatch (rlRenderBatch* batch); // Draw render batch data (Update->Draw->Reset)
void rlSetRenderBatchActive (rlRenderBatch* batch); // Set the active render batch for rlgl (NULL for default internal)
void rlDrawRenderBatchActive (); // Update and draw internal render batch
bool rlCheckRenderBatchLimit (int vCount); // Check internal buffer overflow for a given number of vertex

void rlSetTexture (uint id); // Set current texture for render batch and check buffers limits

//------------------------------------------------------------------------------------------------------------------------

// Vertex buffers management
uint rlLoadVertexArray (); // Load vertex array (vao) if supported
uint rlLoadVertexBuffer (const(void)* buffer, int size, bool dynamic); // Load a vertex buffer attribute
uint rlLoadVertexBufferElement (const(void)* buffer, int size, bool dynamic); // Load a new attributes element buffer
void rlUpdateVertexBuffer (uint bufferId, const(void)* data, int dataSize, int offset); // Update GPU buffer with new data
void rlUpdateVertexBufferElements (uint id, const(void)* data, int dataSize, int offset); // Update vertex buffer elements with new data
void rlUnloadVertexArray (uint vaoId);
void rlUnloadVertexBuffer (uint vboId);
void rlSetVertexAttribute (uint index, int compSize, int type, bool normalized, int stride, const(void)* pointer);
void rlSetVertexAttributeDivisor (uint index, int divisor);
void rlSetVertexAttributeDefault (int locIndex, const(void)* value, int attribType, int count); // Set vertex attribute default value
void rlDrawVertexArray (int offset, int count);
void rlDrawVertexArrayElements (int offset, int count, const(void)* buffer);
void rlDrawVertexArrayInstanced (int offset, int count, int instances);
void rlDrawVertexArrayElementsInstanced (int offset, int count, const(void)* buffer, int instances);

// Textures management
uint rlLoadTexture (const(void)* data, int width, int height, int format, int mipmapCount); // Load texture in GPU
uint rlLoadTextureDepth (int width, int height, bool useRenderBuffer); // Load depth texture/renderbuffer (to be attached to fbo)
uint rlLoadTextureCubemap (const(void)* data, int size, int format); // Load texture cubemap
void rlUpdateTexture (uint id, int offsetX, int offsetY, int width, int height, int format, const(void)* data); // Update GPU texture with new data
void rlGetGlTextureFormats (int format, uint* glInternalFormat, uint* glFormat, uint* glType); // Get OpenGL internal formats
const(char)* rlGetPixelFormatName (uint format); // Get name string for pixel format
void rlUnloadTexture (uint id); // Unload texture from GPU memory
void rlGenTextureMipmaps (uint id, int width, int height, int format, int* mipmaps); // Generate mipmap data for selected texture
void* rlReadTexturePixels (uint id, int width, int height, int format); // Read texture pixel data
ubyte* rlReadScreenPixels (int width, int height); // Read screen pixel data (color buffer)

// Framebuffer management (fbo)
uint rlLoadFramebuffer (int width, int height); // Load an empty framebuffer
void rlFramebufferAttach (uint fboId, uint texId, int attachType, int texType, int mipLevel); // Attach texture/renderbuffer to a framebuffer
bool rlFramebufferComplete (uint id); // Verify framebuffer is complete
void rlUnloadFramebuffer (uint id); // Delete framebuffer from GPU

// Shaders management
uint rlLoadShaderCode (const(char)* vsCode, const(char)* fsCode); // Load shader from code strings
uint rlCompileShader (const(char)* shaderCode, int type); // Compile custom shader and return shader id (type: RL_VERTEX_SHADER, RL_FRAGMENT_SHADER, RL_COMPUTE_SHADER)
uint rlLoadShaderProgram (uint vShaderId, uint fShaderId); // Load custom shader program
void rlUnloadShaderProgram (uint id); // Unload shader program
int rlGetLocationUniform (uint shaderId, const(char)* uniformName); // Get shader location uniform
int rlGetLocationAttrib (uint shaderId, const(char)* attribName); // Get shader location attribute
void rlSetUniform (int locIndex, const(void)* value, int uniformType, int count); // Set shader value uniform
void rlSetUniformMatrix (int locIndex, Matrix mat); // Set shader value matrix
void rlSetUniformSampler (int locIndex, uint textureId); // Set shader value sampler
void rlSetShader (uint id, int* locs); // Set shader currently active (id and locations)

// Compute shader management
uint rlLoadComputeShaderProgram (uint shaderId); // Load compute shader program
void rlComputeShaderDispatch (uint groupX, uint groupY, uint groupZ); // Dispatch compute shader (equivalent to *draw* for graphics pipeline)

// Shader buffer storage object management (ssbo)
uint rlLoadShaderBuffer (uint size, const(void)* data, int usageHint); // Load shader storage buffer object (SSBO)
void rlUnloadShaderBuffer (uint ssboId); // Unload shader storage buffer object (SSBO)
void rlUpdateShaderBuffer (uint id, const(void)* data, uint dataSize, uint offset); // Update SSBO buffer data
void rlBindShaderBuffer (uint id, uint index); // Bind SSBO buffer
void rlReadShaderBuffer (uint id, void* dest, uint count, uint offset); // Read SSBO buffer data (GPU->CPU)
void rlCopyShaderBuffer (uint destId, uint srcId, uint destOffset, uint srcOffset, uint count); // Copy SSBO data between buffers
uint rlGetShaderBufferSize (uint id); // Get SSBO buffer size

// Buffer management
void rlBindImageTexture (uint id, uint index, int format, bool readonly); // Bind image texture

// Matrix state management
Matrix rlGetMatrixModelview (); // Get internal modelview matrix
Matrix rlGetMatrixProjection (); // Get internal projection matrix
Matrix rlGetMatrixTransform (); // Get internal accumulated transform matrix
Matrix rlGetMatrixProjectionStereo (int eye); // Get internal projection matrix for stereo render (selected eye)
Matrix rlGetMatrixViewOffsetStereo (int eye); // Get internal view offset matrix for stereo render (selected eye)
void rlSetMatrixProjection (Matrix proj); // Set a custom projection matrix (replaces internal projection matrix)
void rlSetMatrixModelview (Matrix view); // Set a custom modelview matrix (replaces internal modelview matrix)
void rlSetMatrixProjectionStereo (Matrix right, Matrix left); // Set eyes projection matrices for stereo rendering
void rlSetMatrixViewOffsetStereo (Matrix right, Matrix left); // Set eyes view offsets matrices for stereo rendering

// Quick and dirty cube/quad buffers load->draw->unload
void rlLoadDrawCube (); // Load and draw a cube
void rlLoadDrawQuad (); // Load and draw a quad
