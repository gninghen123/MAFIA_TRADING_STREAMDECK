//
//  SchwabRESTService.m
//  TradingApp
//
//  Implementazione REST API Service per Schwab
//

#import "SchwabRESTService.h"

@implementation SchwabOrderRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *orderDict = [[NSMutableDictionary alloc] init];
    
    // Order Leg Instruments
    NSMutableDictionary *instrument = [[NSMutableDictionary alloc] init];
    instrument[@"symbol"] = self.symbol;
    instrument[@"assetType"] = @"EQUITY"; // Default to equity
    
    NSMutableDictionary *orderLeg = [[NSMutableDictionary alloc] init];
    orderLeg[@"instruction"] = [self instructionString];
    orderLeg[@"quantity"] = @(self.quantity);
    orderLeg[@"instrument"] = instrument;
    
    orderDict[@"orderLegCollection"] = @[orderLeg];
    
    // Order Type and Session
    orderDict[@"orderType"] = [self orderTypeString];
    orderDict[@"session"] = [self sessionString];
    orderDict[@"duration"] = [self durationString];
    
    // Price fields
    if (self.orderType == SchwabOrderTypeLimit || self.orderType == SchwabOrderTypeStopLimit) {
        if (self.price) {
            orderDict[@"price"] = self.price;
        }
    }
    
    if (self.orderType == SchwabOrderTypeStop || self.orderType == SchwabOrderTypeStopLimit) {
        if (self.stopPrice) {
            orderDict[@"stopPrice"] = self.stopPrice;
        }
    }
    
    return [orderDict copy];
}

- (NSString *)instructionString {
    switch (self.instruction) {
        case SchwabOrderInstructionBuy: return @"BUY";
        case SchwabOrderInstructionSell: return @"SELL";
        case SchwabOrderInstructionBuyToCover: return @"BUY_TO_COVER";
        case SchwabOrderInstructionSellShort: return @"SELL_SHORT";
    }
}

- (NSString *)orderTypeString {
    switch (self.orderType) {
        case SchwabOrderTypeMarket: return @"MARKET";
        case SchwabOrderTypeLimit: return @"LIMIT";
        case SchwabOrderTypeStop: return @"STOP";
        case SchwabOrderTypeStopLimit: return @"STOP_LIMIT";
    }
}

- (NSString *)sessionString {
    switch (self.session) {
        case SchwabOrderSessionNormal: return @"NORMAL";
        case SchwabOrderSessionAM: return @"AM";
        case SchwabOrderSessionPM: return @"PM";
        case SchwabOrderSessionSeamless: return @"SEAMLESS";
    }
}

- (NSString *)durationString {
    switch (self.duration) {
        case SchwabOrderDurationDay: return @"DAY";
        case SchwabOrderDurationGTC: return @"GTC";
        case SchwabOrderDurationFOK: return @"FOK";
        case SchwabOrderDurationIOC: return @"IOC";
    }
}

@end

@interface SchwabRESTService ()
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation SchwabRESTService

#pragma mark - Initialization

- (instancetype)initWithAccessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        _accessToken = accessToken;
        _baseURL = @"https://api.schwabapi.com";
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

#pragma mark - Private Methods

- (NSMutableURLRequest *)requestWithPath:(NSString *)path method:(NSString *)method {
    NSURL *url = [NSURL URLWithString:[self.baseURL stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:method];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
   forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return request;
}

- (void)performRequest:(NSURLRequest *)request completion:(SchwabCompletionBlock)completion {
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self handleResponse:data response:response error:error completion:completion];
    }];
    
    [task resume];
}

- (void)performArrayRequest:(NSURLRequest *)request completion:(SchwabArrayCompletionBlock)completion {
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self handleArrayResponse:data response:response error:error completion:completion];
    }];
    
    [task resume];
}

- (void)handleResponse:(NSData *)data
              response:(NSURLResponse *)response
                 error:(NSError *)error
            completion:(SchwabCompletionBlock)completion {
    
    if (error) {
        completion(nil, error);
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
        NSString *errorMessage = [NSString stringWithFormat:@"HTTP Error %ld", (long)httpResponse.statusCode];
        NSError *httpError = [NSError errorWithDomain:@"SchwabRESTError"
                                                 code:httpResponse.statusCode
                                             userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        completion(nil, httpError);
        return;
    }
    
    if (!data || data.length == 0) {
        completion(@{}, nil);
        return;
    }
    
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        completion((NSDictionary *)jsonObject, nil);
    } else {
        completion(@{@"data": jsonObject}, nil);
    }
}

- (void)handleArrayResponse:(NSData *)data
                   response:(NSURLResponse *)response
                      error:(NSError *)error
                 completion:(SchwabArrayCompletionBlock)completion {
    
    if (error) {
        completion(nil, error);
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
        NSString *errorMessage = [NSString stringWithFormat:@"HTTP Error %ld", (long)httpResponse.statusCode];
        NSError *httpError = [NSError errorWithDomain:@"SchwabRESTError"
                                                 code:httpResponse.statusCode
                                             userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        completion(nil, httpError);
        return;
    }
    
    if (!data || data.length == 0) {
        completion(@[], nil);
        return;
    }
    
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        completion((NSArray *)jsonObject, nil);
    } else {
        completion(@[jsonObject], nil);
    }
}

#pragma mark - Account Information

- (void)getAccountsWithCompletion:(SchwabArrayCompletionBlock)completion {
    NSURLRequest *request = [self requestWithPath:@"/trader/v1/accounts" method:@"GET"];
    [self performArrayRequest:request completion:completion];
}

- (void)getAccountDetails:(NSString *)accountId completion:(SchwabCompletionBlock)completion {
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@", accountId];
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performRequest:request completion:completion];
}

- (void)getPositions:(NSString *)accountId completion:(SchwabArrayCompletionBlock)completion {
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@/positions", accountId];
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performArrayRequest:request completion:completion];
}

#pragma mark - Orders

- (void)getOrders:(NSString *)accountId completion:(SchwabArrayCompletionBlock)completion {
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@/orders", accountId];
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performArrayRequest:request completion:completion];
}

- (void)placeOrder:(NSString *)accountId
      orderRequest:(SchwabOrderRequest *)orderRequest
        completion:(SchwabCompletionBlock)completion {
    
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@/orders", accountId];
    NSMutableURLRequest *request = [self requestWithPath:path method:@"POST"];
    
    NSDictionary *orderDict = [orderRequest toDictionary];
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:orderDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    
    [request setHTTPBody:jsonData];
    [self performRequest:request completion:completion];
}

- (void)cancelOrder:(NSString *)accountId
            orderId:(NSString *)orderId
         completion:(SchwabCompletionBlock)completion {
    
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@/orders/%@", accountId, orderId];
    NSURLRequest *request = [self requestWithPath:path method:@"DELETE"];
    [self performRequest:request completion:completion];
}

- (void)replaceOrder:(NSString *)accountId
             orderId:(NSString *)orderId
        orderRequest:(SchwabOrderRequest *)orderRequest
          completion:(SchwabCompletionBlock)completion {
    
    NSString *path = [NSString stringWithFormat:@"/trader/v1/accounts/%@/orders/%@", accountId, orderId];
    NSMutableURLRequest *request = [self requestWithPath:path method:@"PUT"];
    
    NSDictionary *orderDict = [orderRequest toDictionary];
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:orderDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    
    [request setHTTPBody:jsonData];
    [self performRequest:request completion:completion];
}

#pragma mark - Market Data

- (void)getQuote:(NSString *)symbol completion:(SchwabCompletionBlock)completion {
    NSString *path = [NSString stringWithFormat:@"/marketdata/v1/quotes/%@",
                      [symbol stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performRequest:request completion:completion];
}

- (void)getQuotes:(NSArray<NSString *> *)symbols completion:(SchwabCompletionBlock)completion {
    NSString *symbolsParam = [symbols componentsJoinedByString:@","];
    NSString *encodedSymbols = [symbolsParam stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *path = [NSString stringWithFormat:@"/marketdata/v1/quotes?symbols=%@", encodedSymbols];
    
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performRequest:request completion:completion];
}

- (void)getPriceHistory:(NSString *)symbol
             parameters:(NSDictionary *)parameters
             completion:(SchwabCompletionBlock)completion {
    
    NSMutableString *path = [NSMutableString stringWithFormat:@"/marketdata/v1/pricehistory/%@",
                            [symbol stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    
    if (parameters && parameters.count > 0) {
        [path appendString:@"?"];
        NSMutableArray *queryItems = [[NSMutableArray alloc] init];
        
        for (NSString *key in parameters) {
            NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
            NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [queryItems addObject:[NSString stringWithFormat:@"%@=%@", key, encodedValue]];
        }
        
        [path appendString:[queryItems componentsJoinedByString:@"&"]];
    }
    
    NSURLRequest *request = [self requestWithPath:path method:@"GET"];
    [self performRequest:request completion:completion];
}

#pragma mark - User Preferences

- (void)getUserPreferencesWithCompletion:(SchwabCompletionBlock)completion {
    NSURLRequest *request = [self requestWithPath:@"/trader/v1/userPreference" method:@"GET"];
    [self performRequest:request completion:completion];
}

@end
