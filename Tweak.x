#import <CoreFoundation/CoreFoundation.h>
#import <Preferences/PSSpecifier.h>

@interface BatteryUIResourceClass : NSObject
+ (bool)inDemoMode;
+ (NSString *)containerPath;
@end

// extern CFTypeRef MGCopyAnswer(CFStringRef key, CFDictionaryRef options);
extern CFPropertyListRef _CFPreferencesCopyValueWithContainer(CFStringRef key, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName, CFStringRef containerPath);

static NSString *BatteryUILocalization(Class BUIR, NSString *key) {
    return [[NSBundle bundleForClass:BUIR] localizedStringForKey:key value:@"" table:@"BatteryUI"];
}

%group Hooks

%hook BatteryUIResourceClass

// iPhone's is 4
+ (int)getManagementState {
    return 2;
}

// Non-iPhone don't have mechanism to detect genuine battery
+ (int)genuineBatteryStatus {
    return 1;
}

// Make Maximum Capacity and [Peek] Performance Capability sections display
+ (int)getBatteryHealthServiceState {
    return 0;
}

%end

%hook BatteryUIController

- (NSMutableArray <PSSpecifier *> *)setUpBatteryHealthSpecifiers {
    NSMutableArray <PSSpecifier *> *specifiers = [NSMutableArray array];
    PSSpecifier *group = [PSSpecifier groupSpecifierWithID:@"BATTERY_HEALTH_ID"];
    NSString *name = nil;
    Class BUIR = %c(BatteryUIResourceClass);
    if (![BUIR inDemoMode] || _CFPreferencesCopyValueWithContainer(CFSTR("BATTERY_HEALTH"), CFSTR("com.apple.powerlogd"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost, (__bridge CFStringRef)[BUIR containerPath]) == NULL) {
        name = BatteryUILocalization(BUIR, @"BATTERY_HEALTH");
    }
    PSSpecifier *settings = [PSSpecifier preferenceSpecifierNamed:name target:self set:nil get:@selector(getBatteryServiceSuggestion:) detail:%c(BatteryHealthUIController) cell:PSLinkListCell edit:nil];
    [specifiers addObject:group];
    [specifiers addObject:settings];
    return specifiers;
}

%end

%hook BatteryHealthUIController

- (NSMutableArray <PSSpecifier *> *)smartChargingGroupSpecifier {
    NSMutableArray <PSSpecifier *> *specifiers = %orig;
    PSSpecifier *specifier = [specifiers lastObject];
    // NSString *footerText = [specifier propertyForKey:PSFooterTextGroupKey];
    // [specifier setProperty:[footerText stringByReplacingOccurrencesOfString:@"iPhone" withString:(__bridge NSString *)MGCopyAnswer(CFSTR("GSDeviceName"), NULL)] forKey:PSFooterTextGroupKey];
    // You can't toggle Optimized Battery Charging on non-iPhone anyway
    [specifier setProperty:@NO forKey:PSEnabledKey];
    return specifiers;
}

%end

%end

// Courtesy of https://github.com/kliu102/DetailedBatteryUsage
char *bundleLoadedObserver = "BHE";
void BatteryUsageUIBundleLoadedNotificationFired(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (objc_getClass("BatteryUIController") == nil)
        return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(Hooks);
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), bundleLoadedObserver, (__bridge CFStringRef)NSBundleDidLoadNotification, NULL);
    });
}

%ctor {
    @autoreleasepool {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetLocalCenter(),
            bundleLoadedObserver,
            BatteryUsageUIBundleLoadedNotificationFired,
            (__bridge CFStringRef)NSBundleDidLoadNotification,
            (__bridge CFBundleRef)[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/BatteryUsageUI.bundle"],
            CFNotificationSuspensionBehaviorCoalesce);
    }
}