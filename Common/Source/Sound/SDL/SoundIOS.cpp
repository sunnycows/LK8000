/*
 * LK8000 Tactical Flight Computer -  WWW.LK8000.IT
 * Released under GNU/GPL License v.2
 * See CREDITS.TXT file for authors and copyrights
 */
#include "../Sound.h"
#include "externs.h"

SoundGlobalInit::SoundGlobalInit() {
    StartupStore(_T("------ LK8000 SOUNDS NOT WORKING!%s"),NEWLINE);
}

SoundGlobalInit::~SoundGlobalInit() {
}

bool IsSoundInit() {
    return false;
}

bool SetSoundVolume() {
    return false;
}


void LKSound(const TCHAR *lpName) {
}

void PlayResource (const TCHAR* lpName) {
}



