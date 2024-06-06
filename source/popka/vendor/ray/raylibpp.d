module popka.vendor.ray.raylibpp;

import popka.vendor.ray.raylib;

@safe @nogc nothrow:

// NOTE: Everything here is untested.

// Basic shapes drawing functions
alias drawPixel = DrawPixel;
alias drawPixel = DrawPixelV;

alias drawLine = DrawLine;
alias drawLine = DrawLineV;
alias drawLine = DrawLineEx;
alias drawLineStrip = DrawLineStrip;
alias drawLineBezier = DrawLineBezier;

alias drawCircle = DrawCircle;
alias drawCircleSector = DrawCircleSector;
alias drawCircleSectorLines = DrawCircleSectorLines;
alias drawCircleGradient = DrawCircleGradient;
alias drawCircle = DrawCircleV;
alias drawCircleLines = DrawCircleLines;
alias drawCircleLines = DrawCircleLinesV;

alias drawEllipse = DrawEllipse;
alias drawEllipseLines = DrawEllipseLines;

alias drawRing = DrawRing;
alias drawRingLines = DrawRingLines;

alias drawRectangle = DrawRectangle;
alias drawRectangle = DrawRectangleV;
alias drawRectangle = DrawRectangleRec;
alias drawRectangle = DrawRectanglePro;
alias drawRectangleGradientV = DrawRectangleGradientV;
alias drawRectangleGradientH = DrawRectangleGradientH;
alias drawRectangleGradient = DrawRectangleGradientEx;
alias drawRectangleLines = DrawRectangleLines;
alias drawRectangleLines = DrawRectangleLinesEx;
alias drawRectangleRounded = DrawRectangleRounded;
alias drawRectangleRoundedLines = DrawRectangleRoundedLines;

alias drawTriangle = DrawTriangle;
alias drawTriangleLines = DrawTriangleLines;
alias drawTriangleFan = DrawTriangleFan;
alias drawTriangleStrip = DrawTriangleStrip;
alias drawPoly = DrawPoly;
alias drawPolyLines = DrawPolyLines;
alias drawPolyLines = DrawPolyLinesEx;

// Splines drawing functions
alias drawSplineLinear = DrawSplineLinear;
alias drawSplineBasis = DrawSplineBasis;
alias drawSplineCatmullRom = DrawSplineCatmullRom;
alias drawSplineBezierQuadratic = DrawSplineBezierQuadratic;
alias drawSplineBezierCubic = DrawSplineBezierCubic;
alias drawSplineSegmentLinear = DrawSplineSegmentLinear;
alias drawSplineSegmentBasis = DrawSplineSegmentBasis;
alias drawSplineSegmentCatmullRom = DrawSplineSegmentCatmullRom;
alias drawSplineSegmentBezierQuadratic = DrawSplineSegmentBezierQuadratic;
alias drawSplineSegmentBezierCubic = DrawSplineSegmentBezierCubic;

// Texture drawing functions
alias drawTexture = DrawTexture;
alias drawTexture = DrawTextureV;
alias drawTexture = DrawTextureEx;
alias drawTexture = DrawTextureRec;
alias drawTexture = DrawTexturePro;
alias drawTexture = DrawTextureNPatch;

// Text drawing functions
alias drawFPS = DrawFPS;
alias drawText = DrawText;
alias drawText = DrawTextEx;
alias drawText = DrawTextPro;
alias drawText = DrawTextCodepoint;
alias drawText = DrawTextCodepoints;

// Basic geometric 3D shapes drawing functions
alias drawLine3D = DrawLine3D;
alias drawPoint3D = DrawPoint3D;
alias drawCircle3D = DrawCircle3D;

alias drawTriangle3D = DrawTriangle3D;
alias drawTriangle3D = DrawTriangleStrip3D;

alias drawCube = DrawCube;
alias drawCube = DrawCubeV;
alias drawCubeWires = DrawCubeWires;
alias drawCubeWires = DrawCubeWiresV;

alias drawSphere = DrawSphere;
alias drawSphere = DrawSphereEx;
alias drawSphereWires = DrawSphereWires;

alias drawCylinder = DrawCylinder;
alias drawCylinder = DrawCylinderEx;
alias drawCylinderWires = DrawCylinderWires;
alias drawCylinderWires = DrawCylinderWiresEx;

alias drawCapsule = DrawCapsule;
alias drawCapsuleWires = DrawCapsuleWires;
alias drawPlane = DrawPlane;
alias drawRay = DrawRay;
alias drawGrid = DrawGrid;

// Model drawing functions
alias drawModel = DrawModel;
alias drawModel = DrawModelEx;
alias drawModelWires = DrawModelWires;
alias drawModelWires = DrawModelWiresEx;

alias drawBoundingBox = DrawBoundingBox;

alias drawBillboard = DrawBillboard;
alias drawBillboard = DrawBillboardRec;
alias drawBillboard = DrawBillboardPro;

// Mesh management functions
alias drawMesh = DrawMesh;
alias drawMeshInstanced = DrawMeshInstanced;
