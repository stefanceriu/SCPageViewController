//
//  SCPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouter.h"

@interface SCPageLayouter ()

@end

@implementation SCPageLayouter
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (id)init
{
	if(self = [super init]) {
		
		self.navigationType = SCPageLayouterNavigationTypeHorizontal;
		self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 1;
		self.numberOfPagesToPreloadAfterCurrentPage  = 1;
	}
	
	return self;
}

- (CGFloat)interItemSpacingForPageViewController:(SCPageViewController *)pageViewController
{
	return self.interItemSpacing;
}

- (CGRect)finalFrameForPageAtIndex:(NSInteger)index
				pageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	
	if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
		frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
	} else {
		frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
	}
	
	return frame;
}

- (void)animatePageReloadAtIndex:(NSUInteger)index
			   oldViewController:(UIViewController *)oldViewController
			   newViewController:(UIViewController *)newViewController
			  pageViewController:(SCPageViewController *)pageViewController
					  completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index pageViewController:pageViewController];
	
	[newViewController.view setFrame:finalFrame];
	[newViewController.view setAlpha:0.0f];
	[UIView animateWithDuration:0.25f animations:^{
		[oldViewController.view setAlpha:0.0f];
		[newViewController.view setAlpha:1.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)animatePageInsertionAtIndex:(NSInteger)index
					 viewController:(UIViewController *)viewController
				 pageViewController:(SCPageViewController *)pageViewController
						 completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index pageViewController:pageViewController];
	
	[viewController.view setFrame:CGRectOffset(finalFrame, 0.0f, CGRectGetHeight(finalFrame))];
	[viewController.view setAlpha:0.0f];
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:finalFrame];
		[viewController.view setAlpha:1.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)animatePageDeletionAtIndex:(NSInteger)index
					viewController:(UIViewController *)viewController
				pageViewController:(SCPageViewController *)pageViewController
						completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index pageViewController:pageViewController];
	
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:CGRectOffset(finalFrame, 0.0f, CGRectGetHeight(finalFrame))];
		[viewController.view setAlpha:0.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)animatePageMoveFromIndex:(NSUInteger)fromIndex
						 toIndex:(NSUInteger)toIndex
				  viewController:(UIViewController *)viewController
			  pageViewController:(SCPageViewController *)pageViewController
					  completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:toIndex pageViewController:pageViewController];
	
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:finalFrame];
	} completion:^(BOOL finished) {
		completion();
	}];
}

@end
