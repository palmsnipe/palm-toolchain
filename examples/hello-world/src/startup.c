#include <PalmOS.h>

UInt32 PilotMain(UInt16 command, void *commandPBP, UInt16 launchFlags);
UInt32 __Startup__(void);
extern UInt32 __reloc_offsets_start[];
extern UInt32 __reloc_offsets_end[];

#define LINK_CODE_BASE 0x10000000UL
#define LINK_CODE_LIMIT 0x10010000UL

static void ApplyAbsoluteRelocations(void) {
    UInt32 runtimeBase = (UInt32)&__Startup__;
    UInt32 delta;
    UInt32 *offsetP;

    __asm__ volatile ("" : "+d" (runtimeBase));
    delta = runtimeBase - LINK_CODE_BASE;
    if (delta == 0) return;
    if (MemSemaphoreReserve(true) != errNone) return;

    for (offsetP = __reloc_offsets_start; offsetP < __reloc_offsets_end; offsetP++) {
        UInt32 *entryP = (UInt32 *)(runtimeBase + *offsetP);
        UInt32 value = *entryP;
        if (value >= LINK_CODE_BASE && value < LINK_CODE_LIMIT) {
            *entryP = value + delta;
        }
    }

    MemSemaphoreRelease(true);
}

UInt32 __attribute__((section(".vectors"))) __Startup__(void) {
    SysAppInfoPtr appInfoP;
    void *previousGlobalsP;
    void *globalsP;
    UInt32 result;

    ApplyAbsoluteRelocations();
    SysAppStartup(&appInfoP, &previousGlobalsP, &globalsP);
    result = PilotMain(appInfoP->cmd, appInfoP->cmdPBP, appInfoP->launchFlags);
    SysAppExit(appInfoP, previousGlobalsP, globalsP);
    return result;
}
