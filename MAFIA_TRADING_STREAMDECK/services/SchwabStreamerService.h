//
//  SchwabStreamerService.h
//  TradingApp
//
//  Header per gestire connessione WebSocket Schwab
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SchwabStreamerDelegate <NSObject>
- (void)streamerDidConnect;
- (void)streamerDidDisconnect:(NSError * _Nullable)error;
- (void)streamerDidReceiveData:(NSDictionary *)data;
- (void)streamerDidReceiveError:(NSError *)error;
@end

@interface SchwabStreamerService : NSObject

@property (nonatomic, weak) id<SchwabStreamerDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, strong, readonly) NSString *customerId;
@property (nonatomic, strong, readonly) NSString *correlationId;

// Initialization
- (instancetype)initWithAccessToken:(NSString *)accessToken
                         customerId:(NSString *)customerId
                      correlationId:(NSString *)correlationId;

// Connection management
- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;

// Subscription methods
- (void)subscribeToEquities:(NSArray<NSString *> *)symbols fields:(NSArray<NSString *> *)fields;
- (void)subscribeToOptions:(NSArray<NSString *> *)symbols fields:(NSArray<NSString *> *)fields;
- (void)subscribeToAccountActivity:(NSString *)accountId;
- (void)unsubscribeFromEquities:(NSArray<NSString *> *)symbols;

// Utility methods
- (void)sendHeartbeat;

@end

NS_ASSUME_NONNULL_END
