#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

extern int _CGSDefaultConnection(void);

extern void CGSSetSwipeScrollDirection(int cid, Boolean dir);

static int connectedMice = 0;

void setNaturalScrolling(BOOL naturalScrolling) {
    NSLog(@"Setting natural scrolling: %d", naturalScrolling);

    int connection = _CGSDefaultConnection();
    CGSSetSwipeScrollDirection(connection, naturalScrolling);

    CFPreferencesSetAppValue(
        CFSTR("com.apple.swipescrolldirection"),
        naturalScrolling ? kCFBooleanTrue : kCFBooleanFalse,
        kCFPreferencesAnyApplication
    );
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwipeScrollDirectionDidChangeNotification" object:nil];
}

void deviceAddedCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    NSLog(@"Device added: %@", device);

    connectedMice++;
    if (connectedMice == 1) setNaturalScrolling(NO);
}

void deviceRemovedCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    NSLog(@"Device removed: %@", device);

    if (connectedMice > 0) {
        connectedMice--;
        if (connectedMice == 0) setNaturalScrolling(YES);
    }
}

int main() {
    @autoreleasepool {
        IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        NSDictionary *matchingDict = @{
            @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
            @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Mouse),
            @kIOHIDTransportKey: @(kIOHIDTransportUSBValue),
        };
        IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef) matchingDict);
        IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceAddedCallback, 0);
        IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemovedCallback, 0);
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRunLoopRun();
        CFRelease(manager);
    }
    return 0;
}
