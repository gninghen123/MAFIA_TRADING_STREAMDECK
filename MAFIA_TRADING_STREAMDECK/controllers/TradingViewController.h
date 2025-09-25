//
//  TradingViewController.h
//  TradingApp
//
//  Controller principale per gestire trading e streaming - AGGIORNATO
//

#import <Cocoa/Cocoa.h>
#import "SchwabStreamerService.h"
#import "SchwabRESTService.h"
#import "OrderWindowController.h"
#import "SchwabLoginManager.h"  // ✅ AGGIUNGI QUESTO IMPORT

NS_ASSUME_NONNULL_BEGIN

@interface TradingViewController : NSViewController <SchwabStreamerDelegate>

// UI Properties
@property (nonatomic, strong) NSTableView *positionsTableView;
@property (nonatomic, strong) NSTableView *quotesTableView;
@property (nonatomic, strong) NSTableView *ordersTableView;
@property (nonatomic, strong) NSTextField *symbolTextField;
@property (nonatomic, strong) NSButton *subscribeButton;
@property (nonatomic, strong) NSButton *connectButton;
@property (nonatomic, strong) NSButton *placeOrderButton;
@property (nonatomic, strong) NSButton *refreshButton;
@property (nonatomic, strong) NSPopUpButton *accountPopup;
@property (nonatomic, strong) NSTextView *logTextView;
@property (nonatomic, strong) NSSplitView *mainSplitView;
@property (nonatomic, strong) NSView *toolbarView;
@property (nonatomic, strong) NSButton *manualAuthButton;  // ✅ CONFERMATO

// Services
@property (nonatomic, strong) SchwabStreamerService *schwabStreamer;
@property (nonatomic, strong) SchwabRESTService *restService;

// Configuration
@property (nonatomic, strong) NSString *accessToken;

// Data Sources
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *quotesData;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *positionsData;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *ordersData;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *accountsData;

// State
@property (nonatomic, strong) NSString *selectedAccountId;
@property (nonatomic, strong) OrderWindowController *orderWindowController;

// Actions
- (IBAction)connectToSchwab:(id)sender;
- (IBAction)subscribeToSymbol:(id)sender;
- (IBAction)refreshPositions:(id)sender;
- (IBAction)refreshOrders:(id)sender;          // ✅ AGGIUNTO
- (IBAction)newOrder:(id)sender;
- (IBAction)accountChanged:(id)sender;
- (IBAction)manualAuth:(id)sender;             // ✅ AGGIUNTO

// Configuration
- (void)setupStreamer;
- (void)setupRESTService;
- (void)loadConfiguration;
- (void)loadAccounts;

@end

NS_ASSUME_NONNULL_END
