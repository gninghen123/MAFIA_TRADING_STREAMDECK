//
//  OrderWindowController.h
//  TradingApp
//
//  Window Controller per piazzamento ordini - UI Programmatica
//

#import <Cocoa/Cocoa.h>
#import "SchwabRESTService.h"

NS_ASSUME_NONNULL_BEGIN

@interface OrderWindowController : NSWindowController

// UI Controls - ora strong invece di weak per UI programmatica
@property (nonatomic, strong) NSTextField *symbolTextField;
@property (nonatomic, strong) NSTextField *quantityTextField;
@property (nonatomic, strong) NSTextField *priceTextField;
@property (nonatomic, strong) NSTextField *stopPriceTextField;
@property (nonatomic, strong) NSPopUpButton *instructionPopup;
@property (nonatomic, strong) NSPopUpButton *orderTypePopup;
@property (nonatomic, strong) NSPopUpButton *sessionPopup;
@property (nonatomic, strong) NSPopUpButton *durationPopup;
@property (nonatomic, strong) NSButton *submitButton;
@property (nonatomic, strong) NSButton *previewButton;
@property (nonatomic, strong) NSButton *cancelButton;
@property (nonatomic, strong) NSTextView *orderPreviewTextView;

// Additional UI elements for programmatic layout
@property (nonatomic, strong) NSView *formView;
@property (nonatomic, strong) NSScrollView *previewScrollView;
@property (nonatomic, strong) NSTextField *previewLabel;
@property (nonatomic, strong) NSView *buttonView;
@property (nonatomic, strong) NSTextField *symbolLabel;
@property (nonatomic, strong) NSTextField *quantityLabel;
@property (nonatomic, strong) NSTextField *instructionLabel;
@property (nonatomic, strong) NSTextField *orderTypeLabel;
@property (nonatomic, strong) NSTextField *priceLabel;
@property (nonatomic, strong) NSTextField *stopPriceLabel;
@property (nonatomic, strong) NSTextField *sessionLabel;
@property (nonatomic, strong) NSTextField *durationLabel;

// Services
@property (nonatomic, strong) SchwabRESTService *restService;
@property (nonatomic, strong) NSString *accountId;

// Actions
- (IBAction)orderTypeChanged:(id)sender;
- (IBAction)previewOrder:(id)sender;
- (IBAction)submitOrder:(id)sender;
- (IBAction)cancelOrder:(id)sender;

// Initialize with services
- (instancetype)initWithRESTService:(SchwabRESTService *)restService
                          accountId:(NSString *)accountId;

@end

NS_ASSUME_NONNULL_END
