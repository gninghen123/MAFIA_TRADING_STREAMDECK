//
//  SchwabOAuthManager.m
//  TradingApp
//
//  Implementazione OAuth per Schwab API
//

#import "SchwabOAuthManager.h"
#import <Security/Security.h>
#import "Cocoa/Cocoa.h"

@interface SchwabOAuthManager ()
@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *clientSecret;
@property (nonatomic, strong) NSString *redirectURI;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSDate *tokenExpirationDate;
@property (nonatomic, copy) SchwabOAuthCompletionBlock pendingCompletion;
@end

@implementation SchwabOAuthManager

#pragma mark - Initialization

- (instancetype)initWithClientId:(NSString *)clientId
                    clientSecret:(NSString *)clientSecret
                     redirectURI:(NSString *)redirectURI {
    self = [super init];
    if (self) {
        _clientId = clientId;
        _clientSecret = clientSecret;
        _redirectURI = redirectURI;
        
        // Try to load existing token
        _accessToken = [self loadTokenFromKeychain];
    }
    return self;
}

#pragma mark - OAuth Flow

- (void)startAuthorizationFlowWithCompletion:(SchwabOAuthCompletionBlock)completion {
    self.pendingCompletion = completion;
    
    // Check if we have a valid token
    if ([self isTokenValid]) {
        completion(self.accessToken, nil);
        return;
    }
    
    // Start OAuth authorization flow
    NSString *authURL = [self buildAuthorizationURL];
    NSURL *url = [NSURL URLWithString:authURL];
    
    // Open in default browser
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    NSLog(@"Aperta pagina di autorizzazione Schwab nel browser");
}

- (NSString *)buildAuthorizationURL {
    NSString *baseURL = @"https://api.schwabapi.com/v1/oauth/authorize";
    NSString *encodedRedirectURI = [self.redirectURI stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=code&scope=readonly",
            baseURL, self.clientId, encodedRedirectURI];
}

- (void)handleAuthorizationResponse:(NSURL *)responseURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:responseURL resolvingAgainstBaseURL:NO];
    
    // Find authorization code in query parameters
    NSString *authCode = nil;
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"code"]) {
            authCode = item.value;
            break;
        }
    }
    
    if (!authCode) {
        NSError *error = [NSError errorWithDomain:@"SchwabOAuthError"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Authorization code not found"}];
        if (self.pendingCompletion) {
            self.pendingCompletion(nil, error);
            self.pendingCompletion = nil;
        }
        return;
    }
    
    // Exchange authorization code for access token
    [self exchangeCodeForToken:authCode];
}

- (void)exchangeCodeForToken:(NSString *)authCode {
    NSURL *tokenURL = [NSURL URLWithString:@"https://api.schwabapi.com/v1/oauth/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Basic Authentication with client credentials
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", self.clientId, self.clientSecret];
    NSData *credentialsData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Credentials = [credentialsData base64EncodedStringWithOptions:0];
    NSString *authHeader = [NSString stringWithFormat:@"Basic %@", base64Credentials];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    // Create request body
    NSString *bodyString = [NSString stringWithFormat:@"grant_type=authorization_code&code=%@&redirect_uri=%@",
                           authCode,
                           [self.redirectURI stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self handleTokenResponse:data response:response error:error];
    }];
    
    [task resume];
}

- (void)handleTokenResponse:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    if (error) {
        if (self.pendingCompletion) {
            self.pendingCompletion(nil, error);
            self.pendingCompletion = nil;
        }
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200) {
        NSError *httpError = [NSError errorWithDomain:@"SchwabOAuthError"
                                                 code:httpResponse.statusCode
                                             userInfo:@{NSLocalizedDescriptionKey: @"Token request failed"}];
        if (self.pendingCompletion) {
            self.pendingCompletion(nil, httpError);
            self.pendingCompletion = nil;
        }
        return;
    }
    
    NSError *jsonError;
    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        if (self.pendingCompletion) {
            self.pendingCompletion(nil, jsonError);
            self.pendingCompletion = nil;
        }
        return;
    }
    
    // Extract token information
    self.accessToken = tokenData[@"access_token"];
    self.refreshToken = tokenData[@"refresh_token"];
    
    NSNumber *expiresIn = tokenData[@"expires_in"];
    if (expiresIn) {
        self.tokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:expiresIn.doubleValue];
    }
    
    // Save to keychain
    if (self.accessToken) {
        [self saveTokenToKeychain:self.accessToken];
        NSLog(@"Token salvato con successo");
    }
    
    if (self.pendingCompletion) {
        self.pendingCompletion(self.accessToken, nil);
        self.pendingCompletion = nil;
    }
}

#pragma mark - Token Management

- (void)refreshTokenWithCompletion:(SchwabOAuthCompletionBlock)completion {
    if (!self.refreshToken) {
        NSError *error = [NSError errorWithDomain:@"SchwabOAuthError"
                                             code:1002
                                         userInfo:@{NSLocalizedDescriptionKey: @"No refresh token available"}];
        completion(nil, error);
        return;
    }
    
    NSURL *tokenURL = [NSURL URLWithString:@"https://api.schwabapi.com/v1/oauth/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Basic Authentication with client credentials
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", self.clientId, self.clientSecret];
    NSData *credentialsData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Credentials = [credentialsData base64EncodedStringWithOptions:0];
    NSString *authHeader = [NSString stringWithFormat:@"Basic %@", base64Credentials];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSString *bodyString = [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@",
                           self.refreshToken];
    
    [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Handle refresh response similar to handleTokenResponse
        [self handleRefreshTokenResponse:data response:response error:error completion:completion];
    }];
    
    [task resume];
}

- (void)handleRefreshTokenResponse:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error completion:(SchwabOAuthCompletionBlock)completion {
    if (error) {
        completion(nil, error);
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200) {
        NSError *httpError = [NSError errorWithDomain:@"SchwabOAuthError"
                                                 code:httpResponse.statusCode
                                             userInfo:@{NSLocalizedDescriptionKey: @"Token refresh failed"}];
        completion(nil, httpError);
        return;
    }
    
    NSError *jsonError;
    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    
    // Update tokens
    self.accessToken = tokenData[@"access_token"];
    if (tokenData[@"refresh_token"]) {
        self.refreshToken = tokenData[@"refresh_token"];
    }
    
    NSNumber *expiresIn = tokenData[@"expires_in"];
    if (expiresIn) {
        self.tokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:expiresIn.doubleValue];
    }
    
    // Save updated token
    if (self.accessToken) {
        [self saveTokenToKeychain:self.accessToken];
    }
    
    completion(self.accessToken, nil);
}

- (BOOL)isTokenValid {
    if (!self.accessToken) return NO;
    if (!self.tokenExpirationDate) return YES; // Assume valid if no expiration
    
    // Check if token expires within next 5 minutes
    NSTimeInterval timeUntilExpiration = [self.tokenExpirationDate timeIntervalSinceNow];
    return timeUntilExpiration > 300; // 5 minutes buffer
}

- (void)clearTokens {
    self.accessToken = nil;
    self.refreshToken = nil;
    self.tokenExpirationDate = nil;
    
    // Remove from keychain
    [self removeTokenFromKeychain];
}

#pragma mark - Keychain Storage

- (void)saveTokenToKeychain:(NSString *)token {
    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: @"SchwabTradingApp",
        (__bridge NSString *)kSecAttrAccount: @"access_token",
        (__bridge NSString *)kSecValueData: tokenData
    };
    
    // Delete existing item first
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    // Add new item
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess) {
        NSLog(@"Errore salvataggio token in keychain: %d", (int)status);
    }
}

- (NSString *)loadTokenFromKeychain {
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: @"SchwabTradingApp",
        (__bridge NSString *)kSecAttrAccount: @"access_token",
        (__bridge NSString *)kSecReturnData: @YES,
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne
    };
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSData *tokenData = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (void)removeTokenFromKeychain {
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: @"SchwabTradingApp",
        (__bridge NSString *)kSecAttrAccount: @"access_token"
    };
    
    SecItemDelete((__bridge CFDictionaryRef)query);
}

@end
