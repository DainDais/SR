// View size in world pixels — rendered into the rooms' 1920x1080 port.
// Keep 16:9 and divide 1920 evenly for clean pixel scaling:
//   480x270 = 4x | 384x216 = 5x | 320x180 = 6x | 240x135 = 8x
camWidth  = 384;
camHeight = 216;

follow = obj_player;

xTo = x;
yTo = y;

// Look-ahead settings
lookAheadDist = 35;  // How far ahead to look

// Manual offset in world pixels, applied to the view position every frame.
// Negative camOffsetY = camera sits higher (player appears below center).
camOffsetX = 0;
camOffsetY = -50;
