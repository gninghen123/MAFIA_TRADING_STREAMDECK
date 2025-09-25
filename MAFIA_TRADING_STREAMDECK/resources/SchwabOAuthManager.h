//
//  SchwabOAuthManager.h
//  TradingApp
//
//  OAuth Manager per autenticazione Schwab
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SchwabOAuthCompletionBlock)(NSString * _Nullable accessToken, NSError * _Nullable error);

@interface SchwabOAuthManager : NSObject

@property (nonatomic, strong, readonly) NSString *clientId;
@property (nonatomic, strong, readonly) NSString *redirectURI;
@property (nonatomic, strong, readonly) NSString *accessToken;
// Manual Code Entry
- (void)handleManualAuthorizationCode:(NSString *)authCode;

// Initialization
- (instancetype)initWithClientId:(NSString *)clientId
                    clientSecret:(NSString *)clientSecret
                     redirectURI:(NSString *)redirectURI;
// OAuth Flow
- (void)startAuthorizationFlowWithCompletion:(SchwabOAuthCompletionBlock)completion;
- (void)handleAuthorizationResponse:(NSURL *)responseURL;

// Token Management
- (void)refreshTokenWithCompletion:(SchwabOAuthCompletionBlock)completion;
- (BOOL)isTokenValid;
- (void)clearTokens;

// Keychain Storage
- (void)saveTokenToKeychain:(NSString *)token;
- (NSString * _Nullable)loadTokenFromKeychain;

@end

NS_ASSUME_NONNULL_END
