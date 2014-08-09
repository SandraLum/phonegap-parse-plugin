#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface CDVParsePlugin: CDVPlugin
{
    NSDictionary *pendingNotifications;
    NSString *listenerCallbackId;
}

@property (nonatomic, copy) NSString *listenerCallbackId;
@property (nonatomic, strong) NSDictionary *pendingNotifications;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)initialize: (CDVInvokedUrlCommand*)command;
- (void)getInstallationId: (CDVInvokedUrlCommand*)command;
- (void)getInstallationObjectId: (CDVInvokedUrlCommand*)command;
- (void)getSubscriptions: (CDVInvokedUrlCommand *)command;
- (void)subscribe: (CDVInvokedUrlCommand *)command;
- (void)unsubscribe: (CDVInvokedUrlCommand *)command;
- (void)registerListener: (CDVInvokedUrlCommand *)command;
- (void)flushNotifications: (CDVInvokedUrlCommand *)command;
- (void)flushNotificationToClient;
@end
