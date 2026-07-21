#include <PalmOS.h>

#include "resource.h"

static Boolean MainFormHandleEvent(EventPtr eventP) {
    switch (eventP->eType) {
        case frmOpenEvent:
            FrmDrawForm(FrmGetActiveForm());
            return true;

        case ctlSelectEvent:
            if (eventP->data.ctlSelect.controlID == DoneButton) {
                EventType stopEvent;
                MemSet(&stopEvent, sizeof(stopEvent), 0);
                stopEvent.eType = appStopEvent;
                EvtAddEventToQueue(&stopEvent);
                return true;
            }
            break;

        default:
            break;
    }

    return false;
}

static Boolean AppHandleEvent(EventPtr eventP) {
    if (eventP->eType == frmLoadEvent) {
        FormType *formP = FrmInitForm(eventP->data.frmLoad.formID);
        FrmSetActiveForm(formP);
        FrmSetEventHandler(formP, MainFormHandleEvent);
        return true;
    }

    return false;
}

static void AppEventLoop(void) {
    EventType event;
    UInt16 error = errNone;

    do {
        EvtGetEvent(&event, evtWaitForever);
        if (!SysHandleEvent(&event) && !MenuHandleEvent(0, &event, &error)) {
            if (!AppHandleEvent(&event)) FrmDispatchEvent(&event);
        }
    } while (event.eType != appStopEvent);
}

UInt32 PilotMain(UInt16 command, void *commandPBP, UInt16 launchFlags) {
    (void)commandPBP;
    (void)launchFlags;

    if (command != sysAppLaunchCmdNormalLaunch) return errNone;

    FrmGotoForm(MainForm);
    AppEventLoop();
    FrmCloseAllForms();
    return errNone;
}
