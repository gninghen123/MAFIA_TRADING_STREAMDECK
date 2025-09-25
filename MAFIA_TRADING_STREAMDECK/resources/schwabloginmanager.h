//
//  SchwabLoginManager.h
//  TradingApp
//
//  Gestione separata dell'autenticazione OAuth2 per Schwab
//  AGGIORNATO con getCustomerId
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SchwabLoginManager : NSObject

+ (instancetype)sharedManager;

// Main integration method for SchwabDataSource
- (void)ensureTokensValidWithCompletion:(void (^)(BOOL success, NSError *_Nullable error))completion;

// OAuth2 Flow Methods
- (void)authenticateWithCompletion:(void (^)(BOOL success, NSError *_Nullable error))completion;
- (void)refreshTokenIfNeeded:(void (^)(BOOL success, NSError *_Nullable error))completion;

// Token Management
- (BOOL)hasValidToken;
- (NSString *_Nullable)getValidAccessToken;
- (NSString *_Nullable)getCustomerId;  // ✅ AGGIUNTO
- (void)clearTokens;

// Configuration - auto-loaded from SchwabConfig.plist
@property (nonatomic, strong, readonly) NSString *appKey;
@property (nonatomic, strong, readonly) NSString *appSecret;
@property (nonatomic, strong, readonly) NSString *callbackURL;

@end

NS_ASSUME_NONNULL_END
