//
//  SCPageViewControllerTests.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 6/21/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SCPageViewController.h"
#import "SCPageLayouter.h"

static NSUInteger const kDefaultNumberOfPages = 10;

@interface SCPageViewControllerTests : XCTestCase <SCPageViewControllerDataSource>

@property (nonatomic, strong) SCPageViewController *pageViewController;
@property (nonatomic, strong) id<SCPageLayouterProtocol> layouter;
@property (nonatomic, strong) NSMutableArray *viewControllers;

@end

@implementation SCPageViewControllerTests

- (void)setUp
{
	[super setUp];
	
	self.viewControllers = [NSMutableArray array];
	for(int i=0; i<10; i++) {
		[self.viewControllers addObject:[NSNull null]];
	}
	
	self.pageViewController = [[SCPageViewController alloc] init];
	[self.pageViewController setDataSource:self];
	
	self.layouter = [[SCPageLayouter alloc] init];
	[self.pageViewController setLayouter:self.layouter animated:NO completion:nil];
	
	UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	
	[self.pageViewController willMoveToParentViewController:rootViewController];
	
	[rootViewController addChildViewController:self.pageViewController];
	
	[rootViewController.view addSubview:self.pageViewController.view];
	[self.pageViewController.view setFrame:rootViewController.view.bounds];
	
	[self.pageViewController didMoveToParentViewController:rootViewController];
}

- (void)tearDown
{
    [super tearDown];
	
	[self.pageViewController willMoveToParentViewController:nil];
	[self.pageViewController.view removeFromSuperview];
	[self.pageViewController removeFromParentViewController];
}

- (void)testStartupProperties_01
{
	XCTAssert(CGRectEqualToRect(self.pageViewController.view.bounds, [UIScreen mainScreen].bounds));
	XCTAssert(self.pageViewController.numberOfPages == 10);
	XCTAssert(self.pageViewController.currentPage == 0);
	XCTAssert(self.pageViewController.loadedViewControllers.count == 2);
}

- (void)testNavigation_01
{
	[self.pageViewController navigateToPageAtIndex:1 animated:NO completion:nil];
	
	XCTAssert(self.pageViewController.currentPage == 1);
	XCTAssert(self.pageViewController.visibleViewControllers.count == 1);
	XCTAssert([self.pageViewController.visibleViewControllers.firstObject isEqual:self.viewControllers[self.pageViewController.currentPage]]);
	
	[self.pageViewController navigateToPageAtIndex:3 animated:NO completion:nil];
	
	XCTAssert(self.pageViewController.currentPage == 3);
	XCTAssert(self.pageViewController.visibleViewControllers.count == 1);
	XCTAssert([self.pageViewController.visibleViewControllers.firstObject isEqual:self.viewControllers[self.pageViewController.currentPage]]);
	XCTAssert(self.pageViewController.loadedViewControllers.count == 3);
}

- (void)testNavigation_02
{
	[self.pageViewController navigateToPageAtIndex:(self.pageViewController.numberOfPages - 1) animated:NO completion:nil];
	
	XCTAssert(self.pageViewController.currentPage == (self.pageViewController.numberOfPages - 1));
	XCTAssert(self.pageViewController.visibleViewControllers.count == 1);
	XCTAssert([self.pageViewController.visibleViewControllers.firstObject isEqual:self.viewControllers[self.pageViewController.currentPage]]);
	XCTAssert(self.pageViewController.loadedViewControllers.count == 2);
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController
{
	return kDefaultNumberOfPages;
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController
			viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
	UIViewController *viewController = self.viewControllers[pageIndex];
	
	if(!viewController || [viewController isEqual:[NSNull null]]) {
		viewController = [[UIViewController alloc] init];
		[self.viewControllers replaceObjectAtIndex:pageIndex withObject:viewController];
	}
	
	return viewController;
}

@end
