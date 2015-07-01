//
//  Tests.m
//  Tests
//
//  Created by Stefan Ceriu on 6/21/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SCPageLayouter.h"

@interface SCPageLayouterTests : XCTestCase

@property (nonatomic, strong) SCPageViewController *pageViewController;
@property (nonatomic, strong) SCPageLayouter *pageLayouter;

@end

@implementation SCPageLayouterTests

- (void)setUp
{
	[super setUp];
	
	self.pageViewController = [[SCPageViewController alloc] init];
	[self.pageViewController.view setFrame:CGRectMake(0, 0, 1024, 768)];
	
	self.pageLayouter = [[SCPageLayouter alloc] init];
}

- (void)testHorizontalPageFrame_01
{
	[self.pageLayouter setInterItemSpacing:0.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:0 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(0, 0, CGRectGetWidth(self.pageViewController.view.bounds), CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testHorizontalPageFrame_02
{
	[self.pageLayouter setInterItemSpacing:-100.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:1 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(CGRectGetWidth(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing,
									  0,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testHorizontalPageFrame_03
{
	[self.pageLayouter setInterItemSpacing:10.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:1 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(CGRectGetWidth(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing,
									  0,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testHorizontalPageFrame_04
{
	[self.pageLayouter setInterItemSpacing:123.0f];
	
	NSUInteger pageIndex = 123;
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:123 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake((CGRectGetWidth(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing) * pageIndex,
									  0,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testVerticalPageFrame_01
{
	[self.pageLayouter setNavigationType:SCPageLayouterNavigationTypeVertical];
	[self.pageLayouter setInterItemSpacing:0.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:0 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.pageViewController.view.bounds), CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testVerticalPageFrame_02
{
	[self.pageLayouter setNavigationType:SCPageLayouterNavigationTypeVertical];
	[self.pageLayouter setInterItemSpacing:-100.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:1 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(0.0f,
									  CGRectGetHeight(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testVerticalPageFrame_03
{
	[self.pageLayouter setNavigationType:SCPageLayouterNavigationTypeVertical];
	[self.pageLayouter setInterItemSpacing:10.0f];
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:1 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(0.0f,
									  CGRectGetHeight(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}

- (void)testVerticalPageFrame_04
{
	[self.pageLayouter setNavigationType:SCPageLayouterNavigationTypeVertical];
	[self.pageLayouter setInterItemSpacing:123.0f];
	
	NSUInteger pageIndex = 123;
	
	CGRect finalFrame = [self.pageLayouter finalFrameForPageAtIndex:123 pageViewController:self.pageViewController];
	CGRect expectedFrame = CGRectMake(0.0f,
									  (CGRectGetHeight(self.pageViewController.view.bounds) + self.pageLayouter.interItemSpacing) * pageIndex,
									  CGRectGetWidth(self.pageViewController.view.bounds),
									  CGRectGetHeight(self.pageViewController.view.bounds));
	
	XCTAssert(CGRectEqualToRect(finalFrame, expectedFrame));
}



@end
