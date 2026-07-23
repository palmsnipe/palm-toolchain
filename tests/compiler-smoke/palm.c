#include <PalmOS.h>

Boolean palm_pointer_return_probe(UInt16 formID) {
    return FrmInitForm(formID) != 0;
}

UInt32 PilotMain(UInt16 command, MemPtr commandPBP, UInt16 launchFlags) {
    (void)command;
    (void)commandPBP;
    (void)launchFlags;
    return 0;
}
