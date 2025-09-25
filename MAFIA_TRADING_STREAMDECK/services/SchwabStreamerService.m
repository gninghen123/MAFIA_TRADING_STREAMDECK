//
//  SchwabStreamerService.m
//  TradingApp
//
//  Implementazione WebSocket per Schwab Streamer API
//

#import "SchwabStreamerService.h"

@interface SchwabStreamerService () <NSURLSessionWebSocketDelegate>

@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *correlationId;
@property (nonatomic, assign) NSInteger requestIdCounter;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@end

@implementation SchwabStreamerService

#pragma mark - Initialization

- (instancetype)initWithAccessToken:(NSString *)accessToken
                         customerId:(NSString *)customerId
                      correlationId:(NSString *)correlationId {
    self = [super init];
    if (self) {
        _accessToken = accessToken;
        _customerId = customerId;
        _correlationId = correlationId;
        _requestIdCounter = 0;
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - Connection Management

- (void)connect {
    if (self.webSocketTask && self.webSocketTask.state == NSURLSessionTaskStateRunning) {
        NSLog(@"WebSocket già connesso");
        return;
    }
    
    // URL WebSocket Schwab (da ottenere dalla GET User Preference)
    NSURL *url = [NSURL URLWithString:@"wss://streamer-api.schwab.com/ws"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    self.webSocketTask = [self.session webSocketTaskWithRequest:request];
    [self.webSocketTask resume];
    
    [self receiveMessage];
}

- (void)disconnect {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
    
    if (self.webSocketTask) {
        [self sendLogoutCommand];
        [self.webSocketTask cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure
                                        reason:[@"Client disconnect" dataUsingEncoding:NSUTF8StringEncoding]];
        self.webSocketTask = nil;
    }
}

- (BOOL)isConnected {
    return self.webSocketTask && self.webSocketTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Login/Logout

- (void)sendLoginCommand {
    NSDictionary *loginRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"ADMIN",
            @"command": @"LOGIN",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{
                @"Authorization": self.accessToken,
                @"SchwabClientChannel": @"IO",
                @"SchwabClientFunctionId": @"APIAPP"
            }
        }]
    };
    
    [self sendMessage:loginRequest];
}

- (void)sendLogoutCommand {
    NSDictionary *logoutRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"ADMIN",
            @"command": @"LOGOUT",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{}
        }]
    };
    
    [self sendMessage:logoutRequest];
}

#pragma mark - Subscription Methods

- (void)subscribeToEquities:(NSArray<NSString *> *)symbols fields:(NSArray<NSString *> *)fields {
    NSString *symbolsString = [symbols componentsJoinedByString:@","];
    NSString *fieldsString = [fields componentsJoinedByString:@","];
    
    NSDictionary *subscriptionRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"LEVELONE_EQUITIES",
            @"command": @"SUBS",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{
                @"keys": symbolsString,
                @"fields": fieldsString
            }
        }]
    };
    
    [self sendMessage:subscriptionRequest];
}

- (void)subscribeToOptions:(NSArray<NSString *> *)symbols fields:(NSArray<NSString *> *)fields {
    NSString *symbolsString = [symbols componentsJoinedByString:@","];
    NSString *fieldsString = [fields componentsJoinedByString:@","];
    
    NSDictionary *subscriptionRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"LEVELONE_OPTIONS",
            @"command": @"SUBS",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{
                @"keys": symbolsString,
                @"fields": fieldsString
            }
        }]
    };
    
    [self sendMessage:subscriptionRequest];
}

- (void)subscribeToAccountActivity:(NSString *)accountId {
    NSDictionary *subscriptionRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"ACCT_ACTIVITY",
            @"command": @"SUBS",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{
                @"keys": @"Account Activity",
                @"fields": @"0,1,2,3"
            }
        }]
    };
    
    [self sendMessage:subscriptionRequest];
}

- (void)unsubscribeFromEquities:(NSArray<NSString *> *)symbols {
    NSString *symbolsString = [symbols componentsJoinedByString:@","];
    
    NSDictionary *unsubscriptionRequest = @{
        @"requests": @[@{
            @"requestid": @(++self.requestIdCounter),
            @"service": @"LEVELONE_EQUITIES",
            @"command": @"UNSUBS",
            @"SchwabClientCustomerId": self.customerId,
            @"SchwabClientCorrelId": self.correlationId,
            @"parameters": @{
                @"keys": symbolsString
            }
        }]
    };
    
    [self sendMessage:unsubscriptionRequest];
}

#pragma mark - Utility Methods

- (void)sendHeartbeat {
    // Schwab invia automaticamente heartbeat, ma possiamo rispondere se necessario
}

- (void)startHeartbeatTimer {
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                           target:self
                                                         selector:@selector(sendHeartbeat)
                                                         userInfo:nil
                                                          repeats:YES];
}

#pragma mark - Message Handling

- (void)sendMessage:(NSDictionary *)message {
    if (!self.isConnected) {
        NSError *error = [NSError errorWithDomain:@"SchwabStreamerError"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"WebSocket non connesso"}];
        [self.delegate streamerDidReceiveError:error];
        return;
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                       options:0
                                                         error:&jsonError];
    
    if (jsonError) {
        [self.delegate streamerDidReceiveError:jsonError];
        return;
    }
    
    NSURLSessionWebSocketMessage *wsMessage =
        [[NSURLSessionWebSocketMessage alloc] initWithData:jsonData];
    
    [self.webSocketTask sendMessage:wsMessage completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Errore invio messaggio: %@", error.localizedDescription);
            [self.delegate streamerDidReceiveError:error];
        }
    }];
}

- (void)receiveMessage {
    [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        if (error) {
            [self.delegate streamerDidReceiveError:error];
            return;
        }
        
        if (message.type == NSURLSessionWebSocketMessageTypeData) {
            [self processReceivedData:message.data];
        } else if (message.type == NSURLSessionWebSocketMessageTypeString) {
            NSData *data = [message.string dataUsingEncoding:NSUTF8StringEncoding];
            [self processReceivedData:data];
        }
        
        // Continua ad ascoltare
        [self receiveMessage];
    }];
}

- (void)processReceivedData:(NSData *)data {
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&jsonError];
    
    if (jsonError) {
        [self.delegate streamerDidReceiveError:jsonError];
        return;
    }
    
    // Gestisci diversi tipi di risposta
    if (json[@"response"]) {
        [self handleResponseMessage:json[@"response"]];
    } else if (json[@"notify"]) {
        [self handleNotifyMessage:json[@"notify"]];
    } else if (json[@"data"]) {
        [self handleDataMessage:json[@"data"]];
    }
}

- (void)handleResponseMessage:(NSArray *)responses {
    for (NSDictionary *response in responses) {
        NSString *service = response[@"service"];
        NSString *command = response[@"command"];
        NSDictionary *content = response[@"content"];
        
        if ([service isEqualToString:@"ADMIN"] && [command isEqualToString:@"LOGIN"]) {
            NSInteger code = [content[@"code"] integerValue];
            if (code == 0) {
                NSLog(@"Login successful: %@", content[@"msg"]);
                [self startHeartbeatTimer];
                [self.delegate streamerDidConnect];
            } else {
                NSError *loginError = [NSError errorWithDomain:@"SchwabStreamerError"
                                                          code:code
                                                      userInfo:@{NSLocalizedDescriptionKey: content[@"msg"]}];
                [self.delegate streamerDidReceiveError:loginError];
            }
        }
    }
}

- (void)handleNotifyMessage:(NSArray *)notifications {
    for (NSDictionary *notification in notifications) {
        if (notification[@"heartbeat"]) {
            NSLog(@"Heartbeat ricevuto: %@", notification[@"heartbeat"]);
        }
    }
}

- (void)handleDataMessage:(NSArray *)dataMessages {
    for (NSDictionary *dataMessage in dataMessages) {
        [self.delegate streamerDidReceiveData:dataMessage];
    }
}

#pragma mark - NSURLSessionWebSocketDelegate

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
    NSLog(@"WebSocket connesso con protocollo: %@", protocol);
    [self sendLoginCommand];
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
    NSString *reasonString = [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding];
    NSLog(@"WebSocket disconnesso - Code: %ld, Reason: %@", (long)closeCode, reasonString);
    
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
    
    NSError *disconnectError = [NSError errorWithDomain:@"SchwabStreamerError"
                                                   code:closeCode
                                               userInfo:@{NSLocalizedDescriptionKey: reasonString ?: @"Connection closed"}];
    [self.delegate streamerDidDisconnect:disconnectError];
}

- (void)dealloc {
    [self disconnect];
}

@end
