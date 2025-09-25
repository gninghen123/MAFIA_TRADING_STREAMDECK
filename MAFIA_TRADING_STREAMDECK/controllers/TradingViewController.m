//
//  TradingViewController.m
//  TradingApp
//
//  Implementazione controller principale
//
#import "SchwabLoginManager.h"  // ✅ AGGIUNGI QUESTO IMPORT

#import "TradingViewController.h"

@interface TradingViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *correlationId;

@end

@implementation TradingViewController

- (void)loadView {
    // Create main view
    NSView *mainView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1200, 800)];
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
    [self setupConstraints];
    [self setupUI];
    [self loadConfiguration];
    [self initializeDataSources];
}
- (void)setupUI {
    // Initial UI state after creation
    self.subscribeButton.enabled = NO;
    self.placeOrderButton.enabled = NO;
    self.refreshButton.enabled = NO;
    self.symbolTextField.stringValue = @"AAPL,TSLA,SPY";
    
    [self appendToLog:@"App avviata - Configurare credenziali API"];
}

#pragma mark - UI Creation

- (void)createUI {
    // Create all UI elements programmatically
    
    // Top toolbar
    NSView *toolbarView = [[NSView alloc] init];
    toolbarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:toolbarView];
    
    // Account popup
    self.accountPopup = [[NSPopUpButton alloc] init];
    self.accountPopup.translatesAutoresizingMaskIntoConstraints = NO;
    [self.accountPopup setTarget:self];
    [self.accountPopup setAction:@selector(accountChanged:)];
    [toolbarView addSubview:self.accountPopup];
    
    // Connect button
    self.connectButton = [[NSButton alloc] init];
    self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.connectButton setTitle:@"Connetti a Schwab"];
    [self.connectButton setTarget:self];
    [self.connectButton setAction:@selector(connectToSchwab:)];
    [self.connectButton setBezelStyle:NSBezelStyleRounded];
    [toolbarView addSubview:self.connectButton];

    // AGGIUNGI QUESTE LINEE:
    self.manualAuthButton = [[NSButton alloc] init];
    self.manualAuthButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.manualAuthButton setTitle:@"Auth Manuale"];
    [self.manualAuthButton setTarget:self];
    [self.manualAuthButton setAction:@selector(manualAuth:)];
    [self.manualAuthButton setBezelStyle:NSBezelStyleRounded];
    [toolbarView addSubview:self.manualAuthButton];
    // Symbol input
    NSTextField *symbolLabel = [[NSTextField alloc] init];
    symbolLabel.translatesAutoresizingMaskIntoConstraints = NO;
    symbolLabel.stringValue = @"Simboli:";
    symbolLabel.editable = NO;
    symbolLabel.bordered = NO;
    symbolLabel.backgroundColor = [NSColor controlColor];
    [toolbarView addSubview:symbolLabel];
    
    self.symbolTextField = [[NSTextField alloc] init];
    self.symbolTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.symbolTextField.placeholderString = @"AAPL,TSLA,SPY";
    [toolbarView addSubview:self.symbolTextField];
    
    // Subscribe button
    self.subscribeButton = [[NSButton alloc] init];
    self.subscribeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subscribeButton setTitle:@"Subscribe"];
    [self.subscribeButton setTarget:self];
    [self.subscribeButton setAction:@selector(subscribeToSymbol:)];
    [self.subscribeButton setBezelStyle:NSBezelStyleRounded];
    [toolbarView addSubview:self.subscribeButton];
    
    // Action buttons
    self.placeOrderButton = [[NSButton alloc] init];
    self.placeOrderButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.placeOrderButton setTitle:@"Nuovo Ordine"];
    [self.placeOrderButton setTarget:self];
    [self.placeOrderButton setAction:@selector(newOrder:)];
    [self.placeOrderButton setBezelStyle:NSBezelStyleRounded];
    [toolbarView addSubview:self.placeOrderButton];
    
    self.refreshButton = [[NSButton alloc] init];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.refreshButton setTitle:@"Refresh"];
    [self.refreshButton setTarget:self];
    [self.refreshButton setAction:@selector(refreshPositions:)];
    [self.refreshButton setBezelStyle:NSBezelStyleRounded];
    [toolbarView addSubview:self.refreshButton];
    
    // Main content area with split view
    NSSplitView *mainSplitView = [[NSSplitView alloc] init];
    mainSplitView.translatesAutoresizingMaskIntoConstraints = NO;
    mainSplitView.vertical = YES;
    mainSplitView.dividerStyle = NSSplitViewDividerStyleThin;
    [self.view addSubview:mainSplitView];
    
    // Left panel - Tables
    NSView *tablesView = [self createTablesView];
    [mainSplitView addSubview:tablesView];
    
    // Right panel - Log
    NSView *logView = [self createLogView];
    [mainSplitView addSubview:logView];
    
    // Store references
    self.mainSplitView = mainSplitView;
    self.toolbarView = toolbarView;
}

- (NSView *)createTablesView {
    NSView *containerView = [[NSView alloc] init];
    
    // Tab view for different tables
    NSTabView *tabView = [[NSTabView alloc] init];
    tabView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:tabView];
    
    // Quotes tab
    NSTabViewItem *quotesTab = [[NSTabViewItem alloc] init];
    quotesTab.label = @"Quotazioni";
    quotesTab.view = [self createQuotesTableView];
    [tabView addTabViewItem:quotesTab];
    
    // Positions tab
    NSTabViewItem *positionsTab = [[NSTabViewItem alloc] init];
    positionsTab.label = @"Posizioni";
    positionsTab.view = [self createPositionsTableView];
    [tabView addTabViewItem:positionsTab];
    
    // Orders tab
    NSTabViewItem *ordersTab = [[NSTabViewItem alloc] init];
    ordersTab.label = @"Ordini";
    ordersTab.view = [self createOrdersTableView];
    [tabView addTabViewItem:ordersTab];
    
    // Constraints for tab view
    [NSLayoutConstraint activateConstraints:@[
        [tabView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:10],
        [tabView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10],
        [tabView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10],
        [tabView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-10]
    ]];
    
    return containerView;
}

- (NSView *)createQuotesTableView {
    // Create scroll view
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.autohidesScrollers = NO;
    scrollView.borderType = NSBezelBorder;
    
    // Create table view
    self.quotesTableView = [[NSTableView alloc] init];
    self.quotesTableView.dataSource = self;
    self.quotesTableView.delegate = self;
    self.quotesTableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    
    // Create columns
    NSArray *columnTitles = @[@"Symbol", @"Bid", @"Ask", @"Last", @"Change", @"Volume", @"High", @"Low"];
    NSArray *columnIdentifiers = @[@"symbol", @"bid", @"ask", @"last", @"change", @"volume", @"high", @"low"];
    
    for (NSInteger i = 0; i < columnTitles.count; i++) {
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:columnIdentifiers[i]];
        column.title = columnTitles[i];
        column.width = 80;
        column.minWidth = 60;
        [self.quotesTableView addTableColumn:column];
    }
    
    scrollView.contentView.documentView = self.quotesTableView;
    return scrollView;
}

- (NSView *)createPositionsTableView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.autohidesScrollers = NO;
    scrollView.borderType = NSBezelBorder;
    
    self.positionsTableView = [[NSTableView alloc] init];
    self.positionsTableView.dataSource = self;
    self.positionsTableView.delegate = self;
    self.positionsTableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    
    NSArray *columnTitles = @[@"Symbol", @"Long Qty", @"Short Qty", @"Market Value"];
    NSArray *columnIdentifiers = @[@"symbol", @"longQty", @"shortQty", @"marketValue"];
    
    for (NSInteger i = 0; i < columnTitles.count; i++) {
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:columnIdentifiers[i]];
        column.title = columnTitles[i];
        column.width = 100;
        column.minWidth = 80;
        [self.positionsTableView addTableColumn:column];
    }
    
    scrollView.contentView.documentView = self.positionsTableView;
    return scrollView;
}

- (NSView *)createOrdersTableView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.autohidesScrollers = NO;
    scrollView.borderType = NSBezelBorder;
    
    self.ordersTableView = [[NSTableView alloc] init];
    self.ordersTableView.dataSource = self;
    self.ordersTableView.delegate = self;
    self.ordersTableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    
    NSArray *columnTitles = @[@"Order ID", @"Symbol", @"Quantity", @"Instruction", @"Status"];
    NSArray *columnIdentifiers = @[@"orderId", @"symbol", @"quantity", @"instruction", @"status"];
    
    for (NSInteger i = 0; i < columnTitles.count; i++) {
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:columnIdentifiers[i]];
        column.title = columnTitles[i];
        column.width = 100;
        column.minWidth = 80;
        [self.ordersTableView addTableColumn:column];
    }
    
    scrollView.contentView.documentView = self.ordersTableView;
    return scrollView;
}

- (NSView *)createLogView {
    NSView *containerView = [[NSView alloc] init];
    
    // Title label
    NSTextField *logTitle = [[NSTextField alloc] init];
    logTitle.translatesAutoresizingMaskIntoConstraints = NO;
    logTitle.stringValue = @"Log Attività";
    logTitle.font = [NSFont boldSystemFontOfSize:14];
    logTitle.editable = NO;
    logTitle.bordered = NO;
    logTitle.backgroundColor = [NSColor controlColor];
    [containerView addSubview:logTitle];
    
    // Log scroll view
    NSScrollView *logScrollView = [[NSScrollView alloc] init];
    logScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    logScrollView.hasVerticalScroller = YES;
    logScrollView.autohidesScrollers = NO;
    logScrollView.borderType = NSBezelBorder;
    
    // Log text view
    self.logTextView = [[NSTextView alloc] init];
    self.logTextView.editable = NO;
    self.logTextView.selectable = YES;
    self.logTextView.font = [NSFont fontWithName:@"Monaco" size:10];
    self.logTextView.backgroundColor = [NSColor textBackgroundColor];
    
    logScrollView.contentView.documentView = self.logTextView;
    [containerView addSubview:logScrollView];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [logTitle.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:10],
        [logTitle.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10],
        [logTitle.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10],
        
        [logScrollView.topAnchor constraintEqualToAnchor:logTitle.bottomAnchor constant:5],
        [logScrollView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10],
        [logScrollView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10],
        [logScrollView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-10]
    ]];
    
    return containerView;
}

- (void)setupConstraints {
    NSView *toolbar = self.toolbarView;
    NSView *splitView = self.mainSplitView;
    
    [NSLayoutConstraint activateConstraints:@[
        // Toolbar constraints
        [toolbar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [toolbar.heightAnchor constraintEqualToConstant:80],
        
        // Split view constraints
        [splitView.topAnchor constraintEqualToAnchor:toolbar.bottomAnchor constant:10],
        [splitView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [splitView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [splitView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        
        // Toolbar element constraints
        [self.accountPopup.topAnchor constraintEqualToAnchor:toolbar.topAnchor constant:10],
        [self.accountPopup.leadingAnchor constraintEqualToAnchor:toolbar.leadingAnchor],
        [self.accountPopup.widthAnchor constraintEqualToConstant:200],
        
        [self.connectButton.topAnchor constraintEqualToAnchor:toolbar.topAnchor constant:10],
        [self.connectButton.leadingAnchor constraintEqualToAnchor:self.accountPopup.trailingAnchor constant:20],
        [self.connectButton.widthAnchor constraintEqualToConstant:150],

        // AGGIUNGI QUESTE LINEE:
        [self.manualAuthButton.topAnchor constraintEqualToAnchor:toolbar.topAnchor constant:10],
        [self.manualAuthButton.leadingAnchor constraintEqualToAnchor:self.connectButton.trailingAnchor constant:10],
        [self.manualAuthButton.widthAnchor constraintEqualToConstant:120],
        
        [self.symbolTextField.topAnchor constraintEqualToAnchor:self.accountPopup.bottomAnchor constant:10],
        [self.symbolTextField.leadingAnchor constraintEqualToAnchor:toolbar.leadingAnchor],
        [self.symbolTextField.widthAnchor constraintEqualToConstant:200],
        
        [self.subscribeButton.topAnchor constraintEqualToAnchor:self.connectButton.bottomAnchor constant:10],
        [self.subscribeButton.leadingAnchor constraintEqualToAnchor:self.symbolTextField.trailingAnchor constant:10],
        [self.subscribeButton.widthAnchor constraintEqualToConstant:100],
        
        [self.placeOrderButton.topAnchor constraintEqualToAnchor:self.subscribeButton.topAnchor],
        [self.placeOrderButton.leadingAnchor constraintEqualToAnchor:self.subscribeButton.trailingAnchor constant:10],
        [self.placeOrderButton.widthAnchor constraintEqualToConstant:120],
        
        [self.refreshButton.topAnchor constraintEqualToAnchor:self.placeOrderButton.topAnchor],
        [self.refreshButton.leadingAnchor constraintEqualToAnchor:self.placeOrderButton.trailingAnchor constant:10],
        [self.refreshButton.widthAnchor constraintEqualToConstant:80]
    ]];
}

- (void)initializeDataSources {
    self.quotesData = [[NSMutableArray alloc] init];
    self.positionsData = [[NSMutableArray alloc] init];
    self.ordersData = [[NSMutableArray alloc] init];
    self.accountsData = [[NSMutableArray alloc] init];
}

- (void)loadConfiguration {
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    self.accessToken = [loginManager getValidAccessToken];
    
    // ✅ OTTIENI ANCHE IL CUSTOMER ID
    self.customerId = [loginManager getCustomerId];
    
    if (self.accessToken) {
        NSLog(@"✅ Token trovato, lunghezza: %lu caratteri", (unsigned long)self.accessToken.length);
        [self appendToLog:[NSString stringWithFormat:@"✅ Token trovato (%lu caratteri)", (unsigned long)self.accessToken.length]];
        
        if (self.customerId) {
            [self appendToLog:[NSString stringWithFormat:@"✅ Customer ID: %@", self.customerId]];
        } else {
            [self appendToLog:@"⚠️ Customer ID mancante - WebSocket non disponibile"];
        }
        
        [self setupRESTService];
        self.refreshButton.enabled = YES;
        
    } else {
        NSLog(@"ℹ️ Nessun token salvato - fare login prima");
        [self appendToLog:@"ℹ️ Nessun token - cliccare 'Connetti a Schwab'"];
    }
    
    self.correlationId = [[NSUUID UUID] UUIDString];
}

- (void)setupStreamer {
    if (!self.accessToken || !self.customerId) {
        [self appendToLog:@"❌ Token o Customer ID mancanti per WebSocket"];
        return;
    }
    
    // ✅ AGGIUNGI CONTROLLO PER CUSTOMER ID
    if ([self.customerId isEqualToString:@"YOUR_CUSTOMER_ID_HERE"] || !self.customerId) {
        [self appendToLog:@"⚠️ Customer ID non configurato - WebSocket non disponibile"];
        return;
    }
    
    self.schwabStreamer = [[SchwabStreamerService alloc]
                          initWithAccessToken:self.accessToken
                                   customerId:self.customerId
                                correlationId:self.correlationId];
    self.schwabStreamer.delegate = self;
}

- (void)setupRESTService {
    if (!self.accessToken) {
        [self appendToLog:@"❌ Token mancante per REST API"];
        return;
    }
    
    self.restService = [[SchwabRESTService alloc] initWithAccessToken:self.accessToken];
    [self loadAccounts];
}

- (void)loadAccounts {
    [self appendToLog:@"🔄 Caricamento account..."];
    
    [self.restService getAccountsWithCompletion:^(NSArray *accounts, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self appendToLog:[NSString stringWithFormat:@"❌ Errore caricamento account: %@", error.localizedDescription]];
                return;
            }
            
            [self.accountsData removeAllObjects];
            [self.accountsData addObjectsFromArray:accounts];
            
            [self.accountPopup removeAllItems];
            for (NSDictionary *account in accounts) {
                NSString *accountId = account[@"accountId"];
                NSString *accountType = account[@"type"] ?: @"";
                NSString *displayName = [NSString stringWithFormat:@"%@ (%@)", accountId, accountType];
                [self.accountPopup addItemWithTitle:displayName];
            }
            
            if (accounts.count > 0) {
                self.selectedAccountId = accounts[0][@"accountId"];
                [self.accountPopup selectItemAtIndex:0];
                self.placeOrderButton.enabled = YES;
                self.refreshButton.enabled = YES;
                [self appendToLog:[NSString stringWithFormat:@"✅ Caricati %ld account", accounts.count]];
                
                // Auto-load first account data
                [self refreshPositions:nil];
                [self refreshOrders:nil];
            }
        });
    }];
}
// ✅ AGGIUNGI QUESTO NUOVO ACTION PER IL BOTTONE "Auth Manuale"
- (IBAction)manualAuth:(id)sender {
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    
    // Force a new authentication flow
    [self appendToLog:@"🔐 Avvio autenticazione manuale..."];
    
    [loginManager authenticateWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.accessToken = [loginManager getValidAccessToken];
                [self appendToLog:[NSString stringWithFormat:@"✅ Autenticazione manuale riuscita (%lu caratteri)", (unsigned long)self.accessToken.length]];
                [self setupRESTService];
                self.refreshButton.enabled = YES;
            } else {
                [self appendToLog:[NSString stringWithFormat:@"❌ Autenticazione manuale fallita: %@", error.localizedDescription]];
            }
        });
    }];
}
#pragma mark - Actions

- (IBAction)connectToSchwab:(id)sender {
    // ✅ PRIMA assicurati di avere un token valido
    SchwabLoginManager *loginManager = [SchwabLoginManager sharedManager];
    
    // Disabilita bottone durante il processo
    self.connectButton.enabled = NO;
    self.connectButton.title = @"Autenticando...";
    [self appendToLog:@"🔐 Verifica autenticazione..."];
    
    [loginManager ensureTokensValidWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connectButton.enabled = YES;
            
            if (success) {
                self.accessToken = [loginManager getValidAccessToken];
                NSLog(@"✅ Token ottenuto, lunghezza: %lu", (unsigned long)self.accessToken.length);
                [self appendToLog:[NSString stringWithFormat:@"✅ Autenticazione riuscita (%lu caratteri)", (unsigned long)self.accessToken.length]];
                
                // Setup servizi con token valido
                [self setupRESTService];
                
                // Ora prova a connettersi al WebSocket
                [self setupStreamer];
                if (self.schwabStreamer && !self.schwabStreamer.isConnected) {
                    [self.schwabStreamer connect];
                    self.connectButton.title = @"Disconnetti";
                    self.subscribeButton.enabled = YES;
                    [self appendToLog:@"🌐 Connessione WebSocket in corso..."];
                } else {
                    [self.schwabStreamer disconnect];
                    self.connectButton.title = @"Connetti a Schwab";
                    self.subscribeButton.enabled = NO;
                    [self appendToLog:@"❌ Disconnessione da WebSocket"];
                }
                
            } else {
                NSLog(@"❌ Errore autenticazione: %@", error.localizedDescription);
                [self appendToLog:[NSString stringWithFormat:@"❌ Errore autenticazione: %@", error.localizedDescription]];
                self.connectButton.title = @"Connetti a Schwab";
            }
        });
    }];
}

- (IBAction)subscribeToSymbol:(id)sender {
    if (!self.schwabStreamer.isConnected) {
        [self appendToLog:@"❌ WebSocket non connesso"];
        return;
    }
    
    NSString *symbolsText = self.symbolTextField.stringValue;
    NSArray *symbols = [symbolsText componentsSeparatedByString:@","];
    
    // Pulisci simboli (rimuovi spazi)
    NSMutableArray *cleanedSymbols = [[NSMutableArray alloc] init];
    for (NSString *symbol in symbols) {
        NSString *cleaned = [symbol stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (cleaned.length > 0) {
            [cleanedSymbols addObject:[cleaned uppercaseString]];
        }
    }
    
    if (cleanedSymbols.count == 0) {
        [self appendToLog:@"❌ Nessun simbolo valido"];
        return;
    }
    
    // Campi standard per equities (prezzi, volumi, bid/ask)
    NSArray *fields = @[@"0", @"1", @"2", @"3", @"4", @"5", @"8", @"10", @"11", @"18"];
    
    [self.schwabStreamer subscribeToEquities:cleanedSymbols fields:fields];
    [self appendToLog:[NSString stringWithFormat:@"📊 Sottoscrizione a: %@", [cleanedSymbols componentsJoinedByString:@", "]]];
}



- (IBAction)refreshOrders:(id)sender {
    if (!self.restService) {
        [self appendToLog:@"❌ REST Service non disponibile"];
        return;
    }
    
    if (!self.selectedAccountId) {
        [self appendToLog:@"❌ Nessun account selezionato"];
        return;
    }
    
    [self appendToLog:@"🔄 Caricamento ordini..."];
    
    [self.restService getOrders:self.selectedAccountId completion:^(NSArray *orders, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self appendToLog:[NSString stringWithFormat:@"❌ Errore caricamento ordini: %@", error.localizedDescription]];
                return;
            }
            
            [self.ordersData removeAllObjects];
            [self.ordersData addObjectsFromArray:orders];
            [self.ordersTableView reloadData];
            
            [self appendToLog:[NSString stringWithFormat:@"✅ Caricati %ld ordini", orders.count]];
        });
    }];
}

// ✅ AGGIUNGI QUESTO METODO MANCANTE
- (IBAction)newOrder:(id)sender {
    if (!self.restService) {
        [self appendToLog:@"❌ REST Service non disponibile"];
        return;
    }
    
    if (!self.selectedAccountId) {
        [self appendToLog:@"❌ Nessun account selezionato"];
        return;
    }
    
    // Crea e mostra la finestra ordini
    self.orderWindowController = [[OrderWindowController alloc] initWithRESTService:self.restService
                                                                           accountId:self.selectedAccountId];
    [self.orderWindowController showWindow:nil];
}

// ✅ AGGIUNGI QUESTO METODO MANCANTE
- (IBAction)accountChanged:(id)sender {
    NSInteger selectedIndex = self.accountPopup.indexOfSelectedItem;
    if (selectedIndex >= 0 && selectedIndex < self.accountsData.count) {
        NSDictionary *selectedAccount = self.accountsData[selectedIndex];
        self.selectedAccountId = selectedAccount[@"accountId"];
        
        [self appendToLog:[NSString stringWithFormat:@"📋 Account selezionato: %@", self.selectedAccountId]];
        
        // Ricarica dati per il nuovo account
        [self refreshPositions:nil];
        [self refreshOrders:nil];
    }
}


- (IBAction)refreshPositions:(id)sender {
    // Placeholder per refresh posizioni via REST API
    [self appendToLog:@"Refresh posizioni non ancora implementato"];
}

#pragma mark - SchwabStreamerDelegate

- (void)streamerDidConnect {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToLog:@"✅ WebSocket connesso"];
        self.subscribeButton.enabled = YES;
        self.connectButton.title = @"Disconnetti";
    });
}

- (void)streamerDidDisconnect:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = error ?
            [NSString stringWithFormat:@"❌ WebSocket disconnesso: %@", error.localizedDescription] :
            @"WebSocket disconnesso";
        [self appendToLog:message];
        
        self.subscribeButton.enabled = NO;
        self.connectButton.title = @"Connetti a Schwab";
    });
}

- (void)streamerDidReceiveData:(NSDictionary *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self processStreamData:data];
    });
}

- (void)streamerDidReceiveError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToLog:[NSString stringWithFormat:@"❌ WebSocket errore: %@", error.localizedDescription]];
    });
}

#pragma mark - Data Processing

- (void)processStreamData:(NSDictionary *)data {
    NSString *service = data[@"service"];
    NSArray *content = data[@"content"];
    
    if ([service isEqualToString:@"LEVELONE_EQUITIES"]) {
        [self processEquityData:content];
    } else if ([service isEqualToString:@"ACCT_ACTIVITY"]) {
        [self processAccountActivity:content];
    }
    
    [self.quotesTableView reloadData];
}

- (void)processEquityData:(NSArray *)equityData {
    for (NSDictionary *quote in equityData) {
        NSString *symbol = quote[@"key"];
        if (!symbol) continue;
        
        // Trova o crea entry per questo simbolo
        NSInteger existingIndex = -1;
        for (NSInteger i = 0; i < self.quotesData.count; i++) {
            if ([self.quotesData[i][@"symbol"] isEqualToString:symbol]) {
                existingIndex = i;
                break;
            }
        }
        
        // Crea dizionario formattato per display
        NSDictionary *formattedQuote = [self formatQuoteData:quote];
        
        if (existingIndex >= 0) {
            // Aggiorna esistente
            [self.quotesData replaceObjectAtIndex:existingIndex withObject:formattedQuote];
        } else {
            // Aggiungi nuovo
            [self.quotesData addObject:formattedQuote];
        }
    }
}

- (NSDictionary *)formatQuoteData:(NSDictionary *)rawQuote {
    NSString *symbol = rawQuote[@"key"] ?: @"";
    NSNumber *bidPrice = rawQuote[@"1"];
    NSNumber *askPrice = rawQuote[@"2"];
    NSNumber *lastPrice = rawQuote[@"3"];
    NSNumber *volume = rawQuote[@"8"];
    NSNumber *high = rawQuote[@"10"];
    NSNumber *low = rawQuote[@"11"];
    NSNumber *change = rawQuote[@"18"];
    
    return @{
        @"symbol": symbol,
        @"bid": bidPrice ? [NSString stringWithFormat:@"%.2f", bidPrice.doubleValue] : @"--",
        @"ask": askPrice ? [NSString stringWithFormat:@"%.2f", askPrice.doubleValue] : @"--",
        @"last": lastPrice ? [NSString stringWithFormat:@"%.2f", lastPrice.doubleValue] : @"--",
        @"volume": volume ? [NSString stringWithFormat:@"%ld", volume.longValue] : @"--",
        @"high": high ? [NSString stringWithFormat:@"%.2f", high.doubleValue] : @"--",
        @"low": low ? [NSString stringWithFormat:@"%.2f", low.doubleValue] : @"--",
        @"change": change ? [NSString stringWithFormat:@"%.2f", change.doubleValue] : @"--"
    };
}

- (void)processAccountActivity:(NSArray *)activityData {
    for (NSDictionary *activity in activityData) {
        NSString *message = [NSString stringWithFormat:@"Account Activity: %@", activity];
        [self appendToLog:message];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.quotesTableView) {
        return self.quotesData.count;
    } else if (tableView == self.positionsTableView) {
        return self.positionsData.count;
    } else if (tableView == self.ordersTableView) {
        return self.ordersData.count;
    }
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (tableView == self.quotesTableView && row < self.quotesData.count) {
        NSDictionary *quote = self.quotesData[row];
        NSString *value = quote[tableColumn.identifier] ?: @"--";
        cell.textField.stringValue = value;
        
        // Colora change in base al valore
        if ([tableColumn.identifier isEqualToString:@"change"]) {
            double changeValue = [value doubleValue];
            if (changeValue > 0) {
                cell.textField.textColor = [NSColor systemGreenColor];
            } else if (changeValue < 0) {
                cell.textField.textColor = [NSColor systemRedColor];
            } else {
                cell.textField.textColor = [NSColor labelColor];
            }
        }
    } else if (tableView == self.positionsTableView && row < self.positionsData.count) {
        NSDictionary *position = self.positionsData[row];
        NSString *value = position[tableColumn.identifier] ?: @"--";
        cell.textField.stringValue = value;
        
        // Colora market value
        if ([tableColumn.identifier isEqualToString:@"marketValue"]) {
            NSString *marketValueStr = position[@"marketValue"];
            if ([marketValueStr containsString:@"-"]) {
                cell.textField.textColor = [NSColor systemRedColor];
            } else {
                cell.textField.textColor = [NSColor systemGreenColor];
            }
        }
    } else if (tableView == self.ordersTableView && row < self.ordersData.count) {
        NSDictionary *order = self.ordersData[row];
        NSString *value = order[tableColumn.identifier] ?: @"--";
        cell.textField.stringValue = value;
        
        // Colora status
        if ([tableColumn.identifier isEqualToString:@"status"]) {
            if ([value isEqualToString:@"FILLED"]) {
                cell.textField.textColor = [NSColor systemGreenColor];
            } else if ([value isEqualToString:@"CANCELED"] || [value isEqualToString:@"REJECTED"]) {
                cell.textField.textColor = [NSColor systemRedColor];
            } else if ([value isEqualToString:@"WORKING"] || [value isEqualToString:@"PENDING_ACTIVATION"]) {
                cell.textField.textColor = [NSColor systemOrangeColor];
            } else {
                cell.textField.textColor = [NSColor labelColor];
            }
        }
    }
    
    return cell;
}

#pragma mark - Utility Methods

- (void)appendToLog:(NSString *)message {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *currentText = self.logTextView.string;
        NSString *newText = [currentText stringByAppendingString:logMessage];
        [self.logTextView setString:newText];
        
        // Scroll to bottom
        NSRange range = NSMakeRange(newText.length, 0);
        [self.logTextView scrollRangeToVisible:range];
    });
    
    NSLog(@"%@", message);
}

@end
