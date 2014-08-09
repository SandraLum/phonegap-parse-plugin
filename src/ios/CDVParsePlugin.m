#import "CDVParsePlugin.h"
#import <Cordova/CDV.h>
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation CDVParsePlugin

@synthesize listenerCallbackId;
@synthesize pendingNotifications;


- (void)initialize: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString *appId = [command.arguments objectAtIndex:0];
    NSString *clientKey = [command.arguments objectAtIndex:1];
    [Parse setApplicationId:appId clientKey:clientKey];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getInstallationId:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        NSString *installationId = currentInstallation.installationId;
        
        NSLog(@"InstallationId: %@",installationId);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:installationId];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getInstallationObjectId:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        NSString *objectId = currentInstallation.objectId;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:objectId];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getSubscriptions: (CDVInvokedUrlCommand *)command
{
    NSArray *channels = [PFInstallation currentInstallation].channels;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:channels];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribe: (CDVInvokedUrlCommand *)command
{
    // Not sure if this is necessary
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeAlert |
        UIRemoteNotificationTypeSound];

    CDVPluginResult* pluginResult = nil;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *channel = [command.arguments objectAtIndex:0];
    [currentInstallation addUniqueObject:channel forKey:@"channels"];
    [currentInstallation saveInBackground];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unsubscribe: (CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *channel = [command.arguments objectAtIndex:0];
    [currentInstallation removeObject:channel forKey:@"channels"];
    [currentInstallation saveInBackground];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)registerListener: (CDVInvokedUrlCommand *)command
{
    NSLog(@"CDVParsePlugin: registerListener");
    
    self.listenerCallbackId = command.callbackId;
	if (pendingNotifications){
		[self flushNotificationToClient];
    }
}

- (void)flushNotifications: (CDVInvokedUrlCommand *)command
{
    [self flushNotificationToClient];
}

-(void)flushNotificationToClient {
    
    NSLog(@"flushNotificationToClient");
    
    if (pendingNotifications && self.listenerCallbackId)
    {
        NSMutableString *jsonStr = [NSMutableString stringWithString:@"{"];
        [self parseDictionary:pendingNotifications intoJSON:jsonStr];
        NSLog(@"Msg: %@", jsonStr);
        
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonStr];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:listenerCallbackId];
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    [results setValue:token forKey:@"deviceToken"];
    
    NSLog(@"Device Token: %@", token);
    
    #if !TARGET_IPHONE_SIMULATOR
    // Store the deviceToken in the current Installation and save it to Parse
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Successfully registered device token %@ to Parse Installation.", token);
        }
        else {
            NSLog(@"Error saving device token %@ to Parse Installation. %@", token, [error localizedDescription]);
        }
    }];
    
    // Get Bundle Info for Remote Registration (handy if you have more than one app)
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"appName"];
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
    
    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(rntypes & UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeAlert) {
        pushAlert = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeSound) {
        pushSound = @"enabled";
    }
    
    [results setValue:pushBadge forKey:@"pushBadge"];
    [results setValue:pushAlert forKey:@"pushAlert"];
    [results setValue:pushSound forKey:@"pushSound"];
    
    // Get the users Device Model, Display Name, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];
    [results setValue:dev.name forKey:@"deviceName"];
    [results setValue:dev.model forKey:@"deviceModel"];
    [results setValue:dev.systemVersion forKey:@"deviceSystemVersion"];
    
    //[self successWithMessage:[NSString stringWithFormat:@"%@", token]];
#endif
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
	//[self failWithMessage:@"" withError:error];
}


// reentrant method to drill down and surface all sub-dictionaries' key/value pairs into the top level json
-(void)parseDictionary:(NSDictionary *)inDictionary intoJSON:(NSMutableString *)jsonString
{
    NSArray         *keys = [inDictionary allKeys];
    NSString        *key;
    
    for (key in keys)
    {
        id thisObject = [inDictionary objectForKey:key];
        
        if ([thisObject isKindOfClass:[NSDictionary class]])
            [self parseDictionary:thisObject intoJSON:jsonString];
        else
            [jsonString appendFormat:@"%@:'%@',", key, [inDictionary objectForKey:key]];
    }
}

@end
