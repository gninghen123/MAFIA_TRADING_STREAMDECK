//
//  AppDelegate.m
//  TradingApp
//
//  Main app delegate per gestire lifecycle e OAuth
//

#import "AppDelegate.h"
#import "SchwabLoginManager.h"
#import "TradingViewController.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate ()
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) TradingViewController *tradingController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupMainWindow];
    [self setupMenus];
}

- (void)setupMainWindow {
    // Create main window programmatically
    NSRect windowFrame = NSMakeRect(100, 100, 1200, 800);
    self.window = [[NSWindow alloc] initWithContentRect:windowFrame
                                              styleMask:NSWindowStyleMaskTitled |
                                                       NSWindowStyleMaskClosable |
                                                       NSWindowStyleMaskMiniaturizable |
                                                       NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    self.window.title = @"Schwab Trading App";
    self.window.minSize = NSMakeSize(800, 600);
    
    // Setup trading controller programmatically
    self.tradingController = [[TradingViewController alloc] init];
    
    self.window.contentViewController = self.tradingController;
    [self.window makeKeyAndOrderFront:nil];
    
    // Center window
    [self.window center];
}

- (void)setupMenus {
    // Create application menu
    NSMenu *mainMenu = [[NSMenu alloc] init];
    
    // App menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"TradingApp"];
    
    [appMenu addItemWithTitle:@"About TradingApp" action:@selector(showAbout:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    // OAuth options submenu
    NSMenuItem *oauthMenuItem = [[NSMenuItem alloc] initWithTitle:@"Authentication" action:nil keyEquivalent:@""];
    NSMenu *oauthSubmenu = [[NSMenu alloc] initWithTitle:@"Authentication"];
    
    [oauthSubmenu addItemWithTitle:@"Login to Schwab" action:@selector(authenticateWithSchwab:) keyEquivalent:@"a"];
    [oauthSubmenu addItemWithTitle:@"Manual Code Entry" action:@selector(manualCodeEntry:) keyEquivalent:@"m"];
    [oauthSubmenu addItem:[NSMenuItem separatorItem]];
    [oauthSubmenu addItemWithTitle:@"Clear Credentials" action:@selector(clearCredentials:) keyEquivalent:@""];
    [oauthSubmenu addItemWithTitle:@"Check Token Status" action:@selector(checkTokenStatus:) keyEquivalent:@""];
    
    [oauthMenuItem setSubmenu:oauthSubmenu];
    [appMenu addItem:oauthMenuItem];
    
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide TradingApp" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit TradingApp" action:@selector(terminate:) keyEquivalent:@"q"];
    
    // CORREZIONE: Trova l'item "Hide Others" e imposta il modifier
    for (NSMenuItem *item in appMenu.itemArray) {
        if ([item.title isEqualToString:@"Hide Others"]) {
            [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagOption];
            break;
        }
    }
    
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
    
    // File menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    
    [fileMenu addItemWithTitle:@"New Order" action:@selector(newOrder:) keyEquivalent:@"n"];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItemWithTitle:@"Refresh Data" action:@selector(refreshData:) keyEquivalent:@"r"];
    
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];
    
    // Window menu
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
    
    [windowMenuItem setSubmenu:windowMenu];
    [mainMenu addItem:windowMenuItem];
    
    [NSApp setMainMenu:mainMenu];
}
#pragma mark - OAuth Authentication Methods

- (IBAction)authenticateWithSchwab:(id)sender {
    NSLog(@"🔐 Starting Schwab authentication...");
    
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    
    [loginManager ensureTokensValidWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSString *accessToken = [loginManager getValidAccessToken];
                NSLog(@"✅ Authentication successful, token length: %lu", (unsigned long)accessToken.length);
                
                // Update the trading controller with new token
                if (self.tradingController) {
                    self.tradingController.accessToken = accessToken;
                    [self.tradingController setupRESTService];
                }
                
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Authentication Successful";
                alert.informativeText = @"Successfully authenticated with Schwab. You can now access trading services.";
                [alert addButtonWithTitle:@"OK"];
                alert.alertStyle = NSAlertStyleInformational;
                [alert runModal];
                
            } else {
                NSLog(@"❌ Authentication failed: %@", error.localizedDescription);
                
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Authentication Failed";
                alert.informativeText = [NSString stringWithFormat:@"Could not authenticate with Schwab:\n\n%@\n\nYou can try manual code entry if the web login didn't work.", error.localizedDescription];
                [alert addButtonWithTitle:@"OK"];
                alert.alertStyle = NSAlertStyleWarning;
                [alert runModal];
            }
        });
    }];
}

- (IBAction)manualCodeEntry:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Manual Authorization Code Entry";
    alert.informativeText = @"If the web login didn't work, you can manually enter the authorization code:\n\n1. Go to Schwab login page manually\n2. After authorization, copy the 'code' parameter from the callback URL\n3. Paste it here";
    
    // Create text field for code input
    NSTextField *codeInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
    codeInput.placeholderString = @"Paste authorization code here...";
    alert.accessoryView = codeInput;
    
    [alert addButtonWithTitle:@"Authenticate"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleInformational;
    
    NSModalResponse response = [alert runModal];
    
    if (response == NSAlertFirstButtonReturn) {
        NSString *authCode = [codeInput.stringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] ];
        
        if (authCode.length == 0) {
            NSAlert *errorAlert = [[NSAlert alloc] init];
            errorAlert.messageText = @"Error";
            errorAlert.informativeText = @"Please enter a valid authorization code.";
            [errorAlert addButtonWithTitle:@"OK"];
            [errorAlert runModal];
            return;
        }
        
        // Save the code temporarily and use the existing authentication flow
        [[NSUserDefaults standardUserDefaults] setObject:authCode forKey:@"SchwabTempAuthCode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
        [loginManager ensureTokensValidWithCompletion:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    NSString *accessToken = [loginManager getValidAccessToken];
                    
                    if (self.tradingController) {
                        self.tradingController.accessToken = accessToken;
                        [self.tradingController setupRESTService];
                    }
                    
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Authentication Successful";
                    alert.informativeText = @"Manual authentication completed successfully!";
                    [alert addButtonWithTitle:@"OK"];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert runModal];
                    
                } else {
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Authentication Failed";
                    alert.informativeText = [NSString stringWithFormat:@"Manual authentication failed:\n\n%@", error.localizedDescription];
                    [alert addButtonWithTitle:@"OK"];
                    alert.alertStyle = NSAlertStyleWarning;
                    [alert runModal];
                }
            });
        }];
    }
}

- (IBAction)clearCredentials:(id)sender {
    NSLog(@"🗑️ Clearing Schwab credentials...");
    
    [[SchwabLoginManager sharedManager] clearTokens];
    
    // Also clear from trading controller
    if (self.tradingController) {
        self.tradingController.accessToken = nil;
        // Clear any cached data
        [self.tradingController.quotesData removeAllObjects];
        [self.tradingController.positionsData removeAllObjects];
        [self.tradingController.ordersData removeAllObjects];
        [self.tradingController.accountsData removeAllObjects];
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Credentials Cleared";
    alert.informativeText = @"All authentication tokens have been removed. You'll need to authenticate again to access Schwab services.";
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}

- (IBAction)checkTokenStatus:(id)sender {
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    NSString *accessToken = [loginManager getValidAccessToken];
    
    NSAlert *alert = [[NSAlert alloc] init];
    
    if (accessToken) {
        alert.messageText = @"Token Status: Valid";
        alert.informativeText = [NSString stringWithFormat:@"You have a valid access token.\n\nToken length: %lu characters\nToken preview: %@...",
                                (unsigned long)accessToken.length,
                                accessToken.length > 20 ? [accessToken substringToIndex:20] : accessToken];
        alert.alertStyle = NSAlertStyleInformational;
    } else {
        alert.messageText = @"Token Status: Invalid";
        alert.informativeText = @"No valid access token found. Please authenticate with Schwab first.";
        alert.alertStyle = NSAlertStyleWarning;
    }
    
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (IBAction)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Schwab Trading App";
    alert.informativeText = @"A native macOS application for trading with Charles Schwab API.\n\nFeatures:\n• OAuth2 authentication\n• Real-time quotes\n• Portfolio management\n• Order placement\n\nVersion 1.0\nBuilt with Objective-C and Cocoa";
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}

#pragma mark - Menu Forwarding

- (IBAction)newOrder:(id)sender {
    if (self.tradingController) {
        [self.tradingController newOrder:sender];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Not Available";
        alert.informativeText = @"Trading controller not available.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (IBAction)refreshData:(id)sender {
    if (self.tradingController) {
        [self.tradingController refreshPositions:sender];
        [self.tradingController refreshOrders:sender];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Not Available";
        alert.informativeText = @"Trading controller not available.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

#pragma mark - URL Handling (Fallback for OAuth)

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // Register for URL handling as fallback
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"📥 Received callback URL: %@", urlString);
    
    // Check if this is OAuth callback from Schwab
    if ([url.host isEqualToString:@"127.0.0.1"] || [urlString containsString:@"code="]) {
        // Extract code and process it
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"code"]) {
                NSLog(@"🔑 Found authorization code in URL callback");
                
                // Save the code and trigger authentication
                [[NSUserDefaults standardUserDefaults] setObject:item.value forKey:@"SchwabTempAuthCode"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // Process via login manager
                SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
                [loginManager ensureTokensValidWithCompletion:^(BOOL success, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success && self.tradingController) {
                            self.tradingController.accessToken = [loginManager getValidAccessToken];
                            [self.tradingController setupRESTService];
                        }
                    });
                }];
                
                break;
            }
        }
    }
}

- (BOOL)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        NSLog(@"📥 Received URL via openURLs: %@", url.absoluteString);
        
        if ([url.host isEqualToString:@"127.0.0.1"]) {
            [self handleURLEvent:nil withReplyEvent:nil];
            return YES;
        }
    }
    return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
