//
//  OrderWindowController.m
//  TradingApp
//
//  Implementazione completa controller per finestra ordini - UI Programmatica
//

#import "OrderWindowController.h"

@interface OrderWindowController ()
@property (nonatomic, strong) SchwabOrderRequest *currentOrder;
@end

@implementation OrderWindowController

#pragma mark - Initialization

- (instancetype)initWithRESTService:(SchwabRESTService *)restService accountId:(NSString *)accountId {
    self = [super init];
    if (self) {
        _restService = restService;
        _accountId = accountId;
        [self createWindow];
    }
    return self;
}

- (void)createWindow {
    // Create window programmatically
    NSRect windowFrame = NSMakeRect(100, 100, 600, 500);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                   styleMask:NSWindowStyleMaskTitled |
                                                            NSWindowStyleMaskClosable |
                                                            NSWindowStyleMaskMiniaturizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    window.title = [NSString stringWithFormat:@"Nuovo Ordine - Account: %@", self.accountId];
    window.minSize = NSMakeSize(500, 400);
    self.window = window;
    
    [self createUI];
    [self setupConstraints];
    [self setupPopupButtons];
    [self updateUIForOrderType];
}

#pragma mark - UI Creation

- (void)createUI {
    NSView *contentView = [[NSView alloc] init];
    self.window.contentView = contentView;
    
    // Create form container
    NSView *formView = [[NSView alloc] init];
    formView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:formView];
    
    // Create all labels and store them
    self.symbolLabel = [self createLabel:@"Simbolo:"];
    self.quantityLabel = [self createLabel:@"Quantità:"];
    self.instructionLabel = [self createLabel:@"Istruzione:"];
    self.orderTypeLabel = [self createLabel:@"Tipo Ordine:"];
    self.priceLabel = [self createLabel:@"Prezzo:"];
    self.stopPriceLabel = [self createLabel:@"Prezzo Stop:"];
    self.sessionLabel = [self createLabel:@"Sessione:"];
    self.durationLabel = [self createLabel:@"Durata:"];
    
    [formView addSubview:self.symbolLabel];
    [formView addSubview:self.quantityLabel];
    [formView addSubview:self.instructionLabel];
    [formView addSubview:self.orderTypeLabel];
    [formView addSubview:self.priceLabel];
    [formView addSubview:self.stopPriceLabel];
    [formView addSubview:self.sessionLabel];
    [formView addSubview:self.durationLabel];
    
    // Create all text fields and popups
    self.symbolTextField = [self createTextField:@"AAPL"];
    self.quantityTextField = [self createTextField:@"100"];
    self.priceTextField = [self createTextField:@""];
    self.stopPriceTextField = [self createTextField:@""];
    
    [formView addSubview:self.symbolTextField];
    [formView addSubview:self.quantityTextField];
    [formView addSubview:self.priceTextField];
    [formView addSubview:self.stopPriceTextField];
    
    // Create popups
    self.instructionPopup = [self createPopUpButton];
    self.orderTypePopup = [self createPopUpButton];
    [self.orderTypePopup setTarget:self];
    [self.orderTypePopup setAction:@selector(orderTypeChanged:)];
    self.sessionPopup = [self createPopUpButton];
    self.durationPopup = [self createPopUpButton];
    
    [formView addSubview:self.instructionPopup];
    [formView addSubview:self.orderTypePopup];
    [formView addSubview:self.sessionPopup];
    [formView addSubview:self.durationPopup];
    
    // Preview label and text view
    self.previewLabel = [self createLabel:@"Anteprima Ordine:"];
    self.previewLabel.alignment = NSTextAlignmentLeft;
    [contentView addSubview:self.previewLabel];
    
    NSScrollView *previewScrollView = [[NSScrollView alloc] init];
    previewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    previewScrollView.hasVerticalScroller = YES;
    previewScrollView.borderType = NSBezelBorder;
    [contentView addSubview:previewScrollView];
    
    self.orderPreviewTextView = [[NSTextView alloc] init];
    self.orderPreviewTextView.editable = NO;
    self.orderPreviewTextView.font = [NSFont fontWithName:@"Monaco" size:11];
    self.orderPreviewTextView.string = @"Inserisci i dettagli dell'ordine per vedere l'anteprima";
    previewScrollView.documentView = self.orderPreviewTextView;
    
    // Buttons container
    NSView *buttonView = [[NSView alloc] init];
    buttonView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:buttonView];
    
    self.previewButton = [self createButton:@"Anteprima" action:@selector(previewOrder:)];
    self.submitButton = [self createButton:@"Invia Ordine" action:@selector(submitOrder:)];
    self.cancelButton = [self createButton:@"Annulla" action:@selector(cancelOrder:)];
    self.submitButton.enabled = NO;
    
    [buttonView addSubview:self.previewButton];
    [buttonView addSubview:self.submitButton];
    [buttonView addSubview:self.cancelButton];
    
    // Store references for constraints
    self.formView = formView;
    self.previewScrollView = previewScrollView;
    self.buttonView = buttonView;
}

- (NSTextField *)createLabel:(NSString *)text {
    NSTextField *label = [[NSTextField alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.stringValue = text;
    label.editable = NO;
    label.bordered = NO;
    label.backgroundColor = [NSColor controlColor];
    label.alignment = NSTextAlignmentRight;
    return label;
}

- (NSTextField *)createTextField:(NSString *)placeholder {
    NSTextField *textField = [[NSTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.stringValue = placeholder;
    return textField;
}

- (NSPopUpButton *)createPopUpButton {
    NSPopUpButton *popup = [[NSPopUpButton alloc] init];
    popup.translatesAutoresizingMaskIntoConstraints = NO;
    return popup;
}

- (NSButton *)createButton:(NSString *)title action:(SEL)action {
    NSButton *button = [[NSButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title];
    [button setTarget:self];
    [button setAction:action];
    [button setBezelStyle:NSBezelStyleRounded];
    return button;
}

#pragma mark - Constraints Setup

- (void)setupConstraints {
    NSView *contentView = self.window.contentView;
    NSView *formView = self.formView;
    NSScrollView *previewScrollView = self.previewScrollView;
    NSTextField *previewLabel = self.previewLabel;
    NSView *buttonView = self.buttonView;
    
    // Main layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Form view
        [formView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:20],
        [formView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [formView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [formView.heightAnchor constraintEqualToConstant:240],
        
        // Preview label
        [previewLabel.topAnchor constraintEqualToAnchor:formView.bottomAnchor constant:15],
        [previewLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [previewLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        
        // Preview scroll view
        [previewScrollView.topAnchor constraintEqualToAnchor:previewLabel.bottomAnchor constant:5],
        [previewScrollView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [previewScrollView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [previewScrollView.heightAnchor constraintEqualToConstant:100],
        
        // Button view
        [buttonView.topAnchor constraintEqualToAnchor:previewScrollView.bottomAnchor constant:15],
        [buttonView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [buttonView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [buttonView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-20],
        [buttonView.heightAnchor constraintEqualToConstant:40]
    ]];
    
    // Form grid layout - 8 rows, single column
    NSArray *labels = @[self.symbolLabel, self.quantityLabel, self.instructionLabel, self.orderTypeLabel,
                       self.priceLabel, self.stopPriceLabel, self.sessionLabel, self.durationLabel];
    NSArray *controls = @[self.symbolTextField, self.quantityTextField, self.instructionPopup, self.orderTypePopup,
                         self.priceTextField, self.stopPriceTextField, self.sessionPopup, self.durationPopup];
    
    for (NSInteger i = 0; i < labels.count; i++) {
        NSTextField *label = labels[i];
        NSView *control = controls[i];
        NSInteger row = i;  // One per row, 8 rows total
        
        [NSLayoutConstraint activateConstraints:@[
            // Label constraints
            [label.topAnchor constraintEqualToAnchor:formView.topAnchor constant:row * 30 + 5],
            [label.leadingAnchor constraintEqualToAnchor:formView.leadingAnchor],
            [label.widthAnchor constraintEqualToConstant:120],
            [label.heightAnchor constraintEqualToConstant:20],
            
            // Control constraints
            [control.topAnchor constraintEqualToAnchor:label.topAnchor],
            [control.leadingAnchor constraintEqualToAnchor:label.trailingAnchor constant:10],
            [control.widthAnchor constraintEqualToConstant:200],
            [control.heightAnchor constraintEqualToConstant:20]
        ]];
    }
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.previewButton.centerYAnchor constraintEqualToAnchor:buttonView.centerYAnchor],
        [self.previewButton.trailingAnchor constraintEqualToAnchor:self.submitButton.leadingAnchor constant:-10],
        [self.previewButton.widthAnchor constraintEqualToConstant:100],
        
        [self.submitButton.centerYAnchor constraintEqualToAnchor:buttonView.centerYAnchor],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.cancelButton.leadingAnchor constant:-10],
        [self.submitButton.widthAnchor constraintEqualToConstant:120],
        
        [self.cancelButton.centerYAnchor constraintEqualToAnchor:buttonView.centerYAnchor],
        [self.cancelButton.trailingAnchor constraintEqualToAnchor:buttonView.trailingAnchor],
        [self.cancelButton.widthAnchor constraintEqualToConstant:80]
    ]];
}

#pragma mark - Setup Methods

- (void)setupPopupButtons {
    // Instruction popup
    [self.instructionPopup removeAllItems];
    [self.instructionPopup addItemsWithTitles:@[@"Buy", @"Sell", @"Buy to Cover", @"Sell Short"]];
    
    // Order Type popup
    [self.orderTypePopup removeAllItems];
    [self.orderTypePopup addItemsWithTitles:@[@"Market", @"Limit", @"Stop", @"Stop Limit"]];
    
    // Session popup
    [self.sessionPopup removeAllItems];
    [self.sessionPopup addItemsWithTitles:@[@"Normal", @"Pre-Market", @"After-Hours", @"Seamless"]];
    
    // Duration popup
    [self.durationPopup removeAllItems];
    [self.durationPopup addItemsWithTitles:@[@"Day", @"Good Till Canceled", @"Fill or Kill", @"Immediate or Cancel"]];
    
    // Set default selections
    [self.instructionPopup selectItemAtIndex:0];
    [self.orderTypePopup selectItemAtIndex:0];
    [self.sessionPopup selectItemAtIndex:0];
    [self.durationPopup selectItemAtIndex:0];
}

- (void)updateUIForOrderType {
    NSInteger selectedType = self.orderTypePopup.indexOfSelectedItem;
    
    // Reset field states
    self.priceTextField.enabled = NO;
    self.stopPriceTextField.enabled = NO;
    
    switch (selectedType) {
        case 0: // Market
            // No price fields needed
            break;
        case 1: // Limit
            self.priceTextField.enabled = YES;
            break;
        case 2: // Stop
            self.stopPriceTextField.enabled = YES;
            break;
        case 3: // Stop Limit
            self.priceTextField.enabled = YES;
            self.stopPriceTextField.enabled = YES;
            break;
    }
}

#pragma mark - Actions

- (IBAction)orderTypeChanged:(id)sender {
    [self updateUIForOrderType];
    [self updateOrderPreview];
}

- (IBAction)previewOrder:(id)sender {
    if ([self validateOrderInputs]) {
        self.currentOrder = [self buildOrderRequest];
        [self updateOrderPreview];
        self.submitButton.enabled = YES;
    } else {
        self.submitButton.enabled = NO;
    }
}

- (IBAction)submitOrder:(id)sender {
    if (!self.currentOrder) {
        [self showAlert:@"Errore" message:@"Prima genera l'anteprima dell'ordine"];
        return;
    }
    
    // Conferma ordine
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Conferma Ordine";
    alert.informativeText = @"Sei sicuro di voler inviare questo ordine?";
    [alert addButtonWithTitle:@"Invia Ordine"];
    [alert addButtonWithTitle:@"Annulla"];
    alert.alertStyle = NSAlertStyleWarning;
    
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            [self executeOrder];
        }
    }];
}

- (IBAction)cancelOrder:(id)sender {
    [self.window close];
}

#pragma mark - Order Processing

- (BOOL)validateOrderInputs {
    // Validate symbol
    if (self.symbolTextField.stringValue.length == 0) {
        [self showAlert:@"Errore" message:@"Inserisci un simbolo valido"];
        return NO;
    }
    
    // Validate quantity
    NSInteger quantity = self.quantityTextField.integerValue;
    if (quantity <= 0) {
        [self showAlert:@"Errore" message:@"La quantità deve essere maggiore di 0"];
        return NO;
    }
    
    // Validate price fields based on order type
    NSInteger orderType = self.orderTypePopup.indexOfSelectedItem;
    
    if (orderType == 1 || orderType == 3) { // Limit or Stop Limit
        if (self.priceTextField.doubleValue <= 0) {
            [self showAlert:@"Errore" message:@"Inserisci un prezzo valido"];
            return NO;
        }
    }
    
    if (orderType == 2 || orderType == 3) { // Stop or Stop Limit
        if (self.stopPriceTextField.doubleValue <= 0) {
            [self showAlert:@"Errore" message:@"Inserisci un prezzo di stop valido"];
            return NO;
        }
    }
    
    return YES;
}

- (SchwabOrderRequest *)buildOrderRequest {
    SchwabOrderRequest *order = [[SchwabOrderRequest alloc] init];
    
    order.symbol = [self.symbolTextField.stringValue uppercaseString];
    order.quantity = self.quantityTextField.integerValue;
    
    // Instruction
    order.instruction = (SchwabOrderInstruction)self.instructionPopup.indexOfSelectedItem;
    
    // Order Type
    order.orderType = (SchwabOrderType)self.orderTypePopup.indexOfSelectedItem;
    
    // Session
    order.session = (SchwabOrderSession)self.sessionPopup.indexOfSelectedItem;
    
    // Duration
    order.duration = (SchwabOrderDuration)self.durationPopup.indexOfSelectedItem;
    
    // Prices
    if (order.orderType == SchwabOrderTypeLimit || order.orderType == SchwabOrderTypeStopLimit) {
        order.price = @(self.priceTextField.doubleValue);
    }
    
    if (order.orderType == SchwabOrderTypeStop || order.orderType == SchwabOrderTypeStopLimit) {
        order.stopPrice = @(self.stopPriceTextField.doubleValue);
    }
    
    return order;
}

- (void)updateOrderPreview {
    if (!self.currentOrder) {
        self.orderPreviewTextView.string = @"Genera anteprima per vedere i dettagli dell'ordine";
        return;
    }
    
    NSMutableString *preview = [[NSMutableString alloc] init];
    
    [preview appendFormat:@"ANTEPRIMA ORDINE\n"];
    [preview appendFormat:@"==================\n\n"];
    [preview appendFormat:@"Simbolo: %@\n", self.currentOrder.symbol];
    [preview appendFormat:@"Quantità: %ld azioni\n", (long)self.currentOrder.quantity];
    [preview appendFormat:@"Istruzione: %@\n", [self.instructionPopup selectedItem].title];
    [preview appendFormat:@"Tipo: %@\n", [self.orderTypePopup selectedItem].title];
    [preview appendFormat:@"Sessione: %@\n", [self.sessionPopup selectedItem].title];
    [preview appendFormat:@"Durata: %@\n", [self.durationPopup selectedItem].title];
    
    if (self.currentOrder.price) {
        [preview appendFormat:@"Prezzo: $%.2f\n", self.currentOrder.price.doubleValue];
    }
    
    if (self.currentOrder.stopPrice) {
        [preview appendFormat:@"Prezzo Stop: $%.2f\n", self.currentOrder.stopPrice.doubleValue];
    }
    
    // Estimate total value
    if (self.currentOrder.price) {
        double totalValue = self.currentOrder.price.doubleValue * self.currentOrder.quantity;
        [preview appendFormat:@"\nValore Stimato: $%.2f\n", totalValue];
    }
    
    [preview appendString:@"\n⚠️ QUESTA È SOLO UN'ANTEPRIMA"];
    [preview appendString:@"\nVerifica tutti i dettagli prima di inviare"];
    
    self.orderPreviewTextView.string = preview;
}

- (void)executeOrder {
    self.submitButton.enabled = NO;
    self.submitButton.title = @"Inviando...";
    
    [self.restService placeOrder:self.accountId
                    orderRequest:self.currentOrder
                      completion:^(NSDictionary *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.submitButton.enabled = YES;
            self.submitButton.title = @"Invia Ordine";
            
            if (error) {
                [self showAlert:@"Errore Ordine"
                        message:[NSString stringWithFormat:@"Impossibile inviare l'ordine: %@", error.localizedDescription]];
            } else {
                [self showOrderSuccess:response];
            }
        });
    }];
}

- (void)showOrderSuccess:(NSDictionary *)response {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Ordine Inviato";
    alert.informativeText = [NSString stringWithFormat:@"L'ordine è stato inviato con successo per %@", self.currentOrder.symbol];
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleInformational;
    
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        [self.window close];
    }];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleWarning;
    [alert runModal];
}

@end
