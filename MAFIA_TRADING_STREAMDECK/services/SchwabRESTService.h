//
//  SchwabRESTService.h
//  TradingApp
//
//  Service per gestire chiamate REST API Schwab
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SchwabCompletionBlock)(NSDictionary * _Nullable response, NSError * _Nullable error);
typedef void(^SchwabArrayCompletionBlock)(NSArray * _Nullable response, NSError * _Nullable error);

typedef NS_ENUM(NSInteger, SchwabOrderInstruction) {
    SchwabOrderInstructionBuy,
    SchwabOrderInstructionSell,
    SchwabOrderInstructionBuyToCover,
    SchwabOrderInstructionSellShort
};

typedef NS_ENUM(NSInteger, SchwabOrderType) {
    SchwabOrderTypeMarket,
    SchwabOrderTypeLimit,
    SchwabOrderTypeStop,
    SchwabOrderTypeStopLimit
};

typedef NS_ENUM(NSInteger, SchwabOrderSession) {
    SchwabOrderSessionNormal,
    SchwabOrderSessionAM,
    SchwabOrderSessionPM,
    SchwabOrderSessionSeamless
};

typedef NS_ENUM(NSInteger, SchwabOrderDuration) {
    SchwabOrderDurationDay,
    SchwabOrderDurationGTC,  // Good Till Canceled
    SchwabOrderDurationFOK,  // Fill Or Kill
    SchwabOrderDurationIOC   // Immediate Or Cancel
};

@interface SchwabOrderRequest : NSObject
@property (nonatomic, strong) NSString *symbol;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, assign) SchwabOrderInstruction instruction;
@property (nonatomic, assign) SchwabOrderType orderType;
@property (nonatomic, assign) SchwabOrderSession session;
@property (nonatomic, assign) SchwabOrderDuration duration;
@property (nonatomic, strong, nullable) NSNumber *price;
@property (nonatomic, strong, nullable) NSNumber *stopPrice;

- (NSDictionary *)toDictionary;
@end

@interface SchwabRESTService : NSObject

@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, strong, readonly) NSString *baseURL;

// Initialization
- (instancetype)initWithAccessToken:(NSString *)accessToken;

// Account Information
- (void)getAccountsWithCompletion:(SchwabArrayCompletionBlock)completion;
- (void)getAccountDetails:(NSString *)accountId completion:(SchwabCompletionBlock)completion;
- (void)getPositions:(NSString *)accountId completion:(SchwabArrayCompletionBlock)completion;

// Orders
- (void)getOrders:(NSString *)accountId completion:(SchwabArrayCompletionBlock)completion;
- (void)placeOrder:(NSString *)accountId
       orderRequest:(SchwabOrderRequest *)orderRequest
         completion:(SchwabCompletionBlock)completion;
- (void)cancelOrder:(NSString *)accountId
            orderId:(NSString *)orderId
         completion:(SchwabCompletionBlock)completion;
- (void)replaceOrder:(NSString *)accountId
             orderId:(NSString *)orderId
        orderRequest:(SchwabOrderRequest *)orderRequest
          completion:(SchwabCompletionBlock)completion;

// Market Data
- (void)getQuote:(NSString *)symbol completion:(SchwabCompletionBlock)completion;
- (void)getQuotes:(NSArray<NSString *> *)symbols completion:(SchwabCompletionBlock)completion;
- (void)getPriceHistory:(NSString *)symbol
             parameters:(NSDictionary *)parameters
             completion:(SchwabCompletionBlock)completion;

// User Preferences (needed for Streamer)
- (void)getUserPreferencesWithCompletion:(SchwabCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
