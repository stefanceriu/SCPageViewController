//
//  SCPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouter.h"

@implementation SCPageLayouter
@synthesize navigationType;
@synthesize interItemSpacing;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (id)init
{
	if(self = [super init]) {
		self.interItemSpacing = 50.0f;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 1;
		self.numberOfPagesToPreloadAfterCurrentPage  = 1;
		
		self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
	}
	
	return self;
}

- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController
{
	return UIEdgeInsetsZero;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
			  inPageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	
	if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
		frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
	} else {
		frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
	}
	
	return frame;
}

- (CGRect)currentFrameForViewController:(UIViewController *)viewController
							  withIndex:(NSUInteger)index
						  contentOffset:(CGPoint)contentOffset
							 finalFrame:(CGRect)finalFrame
				   inPageViewController:(SCPageViewController *)pageViewController;
{
	return finalFrame;
}

- (void)animatePageReloadAtIndex:(NSUInteger)index
			   oldViewController:(UIViewController *)oldViewController
			   newViewController:(UIViewController *)newViewController
			  pageViewController:(SCPageViewController *)pageViewController
					  completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index inPageViewController:pageViewController];
	
	[newViewController.view setFrame:finalFrame];
	[newViewController.view setAlpha:0.0f];
	[UIView animateWithDuration:0.25f animations:^{
		[oldViewController.view setAlpha:0.0f];
		[newViewController.view setAlpha:1.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)animatePageInsertionAtIndex:(NSUInteger)index
					 viewController:(UIViewController *)viewController
				 pageViewController:(SCPageViewController *)pageViewController
						 completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index inPageViewController:pageViewController];
	
	[viewController.view setFrame:CGRectOffset(finalFrame, 0.0f, CGRectGetHeight(finalFrame))];
	[viewController.view setAlpha:0.0f];
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:finalFrame];
		[viewController.view setAlpha:1.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)animatePageDeletionAtIndex:(NSUInteger)index
					viewController:(UIViewController *)viewController
				pageViewController:(SCPageViewController *)pageViewController
						completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index inPageViewController:pageViewController];
	
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
	CGRect finalFrame = [self finalFrameForPageAtIndex:toIndex inPageViewController:pageViewController];
	
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:finalFrame];
	} completion:^(BOOL finished) {
		completion();
	}];
}

@end
