/*
 * macOS error reporting: messages go to stderr, and fatal errors are also
 * shown in an alert panel since a Finder-launched app has no console.
 */

#include <cstdio>
#include <cstdarg>
#include <cstdlib>

#import <Cocoa/Cocoa.h>

#include "error.h"

static void showAlert(const char* title, const char* message,
                      NSAlertStyle style)
{
    @autoreleasepool {
        // The alert can appear before GLFW has created the application.
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];

        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = style;
        alert.messageText = [NSString stringWithUTF8String:title];
        NSString* info = [NSString stringWithUTF8String:message];
        alert.informativeText = info ? info : @"";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

void errorFatal(const char *fmt, ...) {
    char buffer[1000];
    va_list args;

    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);

    fprintf(stderr, "xu4 error: %s\n", buffer);
    showAlert("XU4 Error", buffer, NSAlertStyleCritical);
    exit(1);
}

void errorWarning(const char *fmt, ...) {
    char buffer[1000];
    va_list args;

    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);

    // Warnings can come in bursts (e.g. missing tile images), so they are
    // not shown in a modal panel.
    fprintf(stderr, "xu4 warning: %s\n", buffer);
}
