//
//  AppDelegate.m
//  TradingApp
//
//  Main app delegate per gestire lifecycle e OAuth
//

#import <Cocoa/Cocoa.h>
#import "schwabloginmanager.h"
#import "TradingViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) TradingViewController *tradingController;
@property (nonatomic, strong) SchwabLoginManager *oauthManager;

// Menu actions
- (IBAction)authenticateWithSchwab:(id)sender;
- (IBAction)clearCredentials:(id)sender;
- (IBAction)showAbout:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupOAuthManager];
    [self setupMainWindow];
    [self setupMenus];
}

- (void)setupOAuthManager {
    NSString *clientId = @"XVweZPSbC0mMKbZJpGHbds6ueGmLRj1Z";
    NSString *clientSecret = @"enwEqrEQmPZlt7KS";
    NSString *redirectURI = @"https://127.0.0.1"; // CORRECTED: Schwab richiede https
    
    self.oauthManager = [[SchwabLoginManager alloc] ini:clientId
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI];
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
    [appMenu addItemWithTitle:@"Authenticate with Schwab" action:@selector(authenticateWithSchwab:) keyEquivalent:@"a"];
    [appMenu addItemWithTitle:@"Clear Credentials" action:@selector(clearCredentials:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide TradingApp" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [[appMenu itemAtIndex:6] setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagOption];
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit TradingApp" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItemWithTitle:@"Codice Manuale" action:@selector(manualCodeEntry:) keyEquivalent:@""];
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

#pragma mark - OAuth Handling

- (IBAction)manualCodeEntry:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Inserisci Codice Manualmente";
    alert.informativeText = @"Copia il codice dalla URL del browser dopo l'autorizzazione";
    
    NSTextField *codeInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    codeInput.placeholderString = @"Incolla il codice qui...";
    alert.accessoryView = codeInput;
    
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Annulla"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        //[self.oauthManager handleManualAuthorizationCode:codeInput.stringValue];
    }
}

- (IBAction)authenticateWithSchwab:(id)sender {
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    
    [loginManager ensureTokensValidWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSString *accessToken = [loginManager getValidAccessToken];
                
                // Aggiorna il trading controller
                if (self.tradingController) {
                    self.tradingController.accessToken = accessToken;
                    [self.tradingController setupRESTService];
                }
                
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Authentication Successful";
                alert.informativeText = @"You can now access Schwab services.";
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Authentication Failed";
                alert.informativeText = error.localizedDescription;
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            }
        });
    }];
}

// Aggiungi anche questo per clear tokens
- (IBAction)clearCredentials:(id)sender {
    [[SchwabLoginManager sharedManager] clearTokens];
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Credentials Cleared";
    alert.informativeText = @"All authentication tokens have been removed.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (IBAction)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Schwab Trading App";
    alert.informativeText = @"A native macOS application for trading with Charles Schwab API.\n\nVersion 1.0\nBuilt with Objective-C and Cocoa";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

#pragma mark - Menu Forwarding

- (IBAction)newOrder:(id)sender {
    if (self.tradingController) {
        [self.tradingController newOrder:sender];
    }
}

- (IBAction)refreshData:(id)sender {
    if (self.tradingController) {
        [self.tradingController refreshPositions:sender];
        [self.tradingController refreshOrders:sender];
    }
}

#pragma mark - URL Handling for OAuth Callback

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"Received callback URL: %@", urlString);
    
    // Check if this is OAuth callback from Schwab
    if ([url.host isEqualToString:@"127.0.0.1"] || [urlString containsString:@"code="]) {
        [self.oauthManager handleAuthorizationResponse:url];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
