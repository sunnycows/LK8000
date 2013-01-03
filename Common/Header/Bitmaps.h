/*
   LK8000 Tactical Flight Computer -  WWW.LK8000.IT
   Released under GNU/GPL License v.2
   See CREDITS.TXT file for authors and copyrights

   $Id: Bitmaps.h,v 1.1 2011/12/21 10:35:29 root Exp root $
*/

#if !defined(BITMAPS_H)
#define BITMAPS_H

#if defined(STATIC_BITMAPS)
  #define BEXTMODE 
  #undef  STATIC_BITMAPS
  #define BEXTNULL	=NULL

#else
  #undef  BEXTMODE
  #define BEXTMODE extern
  #define BEXTNULL

  extern void LKLoadFixedBitmaps(void);
  extern void LKLoadProfileBitmaps(void);
  extern void LKUnloadFixedBitmaps(void);
  extern void LKUnloadProfileBitmaps(void);
#endif

//
// FIXED BITMAPS
//
BEXTMODE  HBITMAP hTurnPoint BEXTNULL;
BEXTMODE  HBITMAP hInvTurnPoint BEXTNULL;
BEXTMODE  HBITMAP hSmall BEXTNULL;
BEXTMODE  HBITMAP hInvSmall BEXTNULL;
BEXTMODE  HBITMAP hTerrainWarning BEXTNULL;
BEXTMODE  HBITMAP hAirspaceWarning BEXTNULL;
BEXTMODE  HBITMAP hLogger BEXTNULL;
BEXTMODE  HBITMAP hLoggerOff BEXTNULL;
BEXTMODE  HBITMAP hFLARMTraffic BEXTNULL;
BEXTMODE  HBITMAP hBatteryFull BEXTNULL;
BEXTMODE  HBITMAP hBatteryFullC BEXTNULL;
BEXTMODE  HBITMAP hBattery96 BEXTNULL;
BEXTMODE  HBITMAP hBattery84 BEXTNULL;
BEXTMODE  HBITMAP hBattery72 BEXTNULL;
BEXTMODE  HBITMAP hBattery60 BEXTNULL;
BEXTMODE  HBITMAP hBattery48 BEXTNULL;
BEXTMODE  HBITMAP hBattery36 BEXTNULL;
BEXTMODE  HBITMAP hBattery24 BEXTNULL;
BEXTMODE  HBITMAP hBattery12 BEXTNULL;

BEXTMODE  HBITMAP hNoTrace BEXTNULL;
BEXTMODE  HBITMAP hFullTrace BEXTNULL;
BEXTMODE  HBITMAP hClimbTrace BEXTNULL;
BEXTMODE  HBITMAP hHeadUp BEXTNULL;
BEXTMODE  HBITMAP hHeadRight BEXTNULL;

BEXTMODE  HBITMAP hMM0 BEXTNULL;
BEXTMODE  HBITMAP hMM1 BEXTNULL;
BEXTMODE  HBITMAP hMM2 BEXTNULL;
BEXTMODE  HBITMAP hMM3 BEXTNULL;
BEXTMODE  HBITMAP hMM4 BEXTNULL;
BEXTMODE  HBITMAP hMM5 BEXTNULL;
BEXTMODE  HBITMAP hMM6 BEXTNULL;
BEXTMODE  HBITMAP hMM7 BEXTNULL;
BEXTMODE  HBITMAP hMM8 BEXTNULL;

BEXTMODE  HBITMAP hBmpThermalSource BEXTNULL;
BEXTMODE  HBITMAP hBmpTarget BEXTNULL;
BEXTMODE  HBITMAP hBmpMarker BEXTNULL;
BEXTMODE  HBITMAP hBmpTeammatePosition BEXTNULL;
BEXTMODE  HBITMAP hAboveTerrainBitmap BEXTNULL;

BEXTMODE  HBITMAP hAirspaceBitmap[NUMAIRSPACEBRUSHES];

BEXTMODE  HBITMAP hBmpLeft32 BEXTNULL;
BEXTMODE  HBITMAP hBmpRight32 BEXTNULL;
BEXTMODE  HBITMAP hScrollBarBitmapTop BEXTNULL;
BEXTMODE  HBITMAP hScrollBarBitmapMid BEXTNULL;
BEXTMODE  HBITMAP hScrollBarBitmapBot BEXTNULL;

// Map icons 
BEXTMODE  HBITMAP hMountop   BEXTNULL;
BEXTMODE  HBITMAP hMountpass BEXTNULL;
BEXTMODE  HBITMAP hBridge    BEXTNULL;
BEXTMODE  HBITMAP hIntersect BEXTNULL;
BEXTMODE  HBITMAP hDam       BEXTNULL;
BEXTMODE  HBITMAP hSender    BEXTNULL;
BEXTMODE  HBITMAP hNdb       BEXTNULL;
BEXTMODE  HBITMAP hLKThermal BEXTNULL;


//
// PROFILE DEPENDENT BITMAPS
//
BEXTMODE  HBITMAP hBmpAirportReachable BEXTNULL;
BEXTMODE  HBITMAP hBmpAirportUnReachable BEXTNULL;
BEXTMODE  HBITMAP hBmpFieldReachable BEXTNULL;
BEXTMODE  HBITMAP hBmpFieldUnReachable BEXTNULL;
BEXTMODE  HBITMAP hCruise BEXTNULL;
BEXTMODE  HBITMAP hClimb BEXTNULL;
BEXTMODE  HBITMAP hFinalGlide BEXTNULL;

#endif
