//
//  MAFIA_TRADING_STREAMDECKUITestsLaunchTests.m
//  MAFIA_TRADING_STREAMDECKUITests
//
//  Created by fabio gattone on 25/09/25.
//

#import <XCTest/XCTest.h>

@interface MAFIA_TRADING_STREAMDECKUITestsLaunchTests : XCTestCase

@end

@implementation MAFIA_TRADING_STREAMDECKUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
    return YES;
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testLaunch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app

    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = @"Launch Screen";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end
