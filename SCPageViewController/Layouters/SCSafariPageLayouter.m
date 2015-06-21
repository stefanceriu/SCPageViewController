//
//  SCSafariPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 6/16/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCSafariPageLayouter.h"

@implementation SCSafariPageLayouter
@synthesize interItemSpacing;
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (instancetype)init
{
	if(self = [super init]) {
		self.interItemSpacing = -300.0f;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 5;
		self.numberOfPagesToPreloadAfterCurrentPage  = 5;
		
		self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
		
		self.pagePercentage = 0.5f;
		
		self.navigationType = SCPageLayouterNavigationTypeVertical;
	}
	
	return self;
}

- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController
{
	if(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, self.contentInset)) {
		CGRect frame = pageViewController.view.bounds;
		CGFloat verticalInset = CGRectGetHeight(frame) - CGRectGetHeight(frame) * self.pagePercentage;
		CGFloat horizontalInset = CGRectGetWidth(frame) - CGRectGetWidth(frame) * self.pagePercentage;
		
		self.contentInset = UIEdgeInsetsMake(verticalInset/2.0f, horizontalInset/2.0f, verticalInset/2.0f, horizontalInset/2.0f);
	}
	
	return self.contentInset;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
			  inPageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	if(CGSizeEqualToSize(CGSizeZero, self.pageSize)) {
		frame.size.height = frame.size.height * self.pagePercentage;
		frame.size.width = frame.size.width * self.pagePercentage;
	} else {
		frame.size = self.pageSize;
	}
	
	if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
		frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
		frame.origin.x = CGRectGetMidX(pageViewController.view.bounds) - CGRectGetMidX(frame);
	} else {
		frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
		frame.origin.y = CGRectGetMidY(pageViewController.view.bounds) - CGRectGetMidY(frame);
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

- (NSUInteger)zPositionForViewController:(UIViewController *)viewController
							   withIndex:(NSUInteger)index
					inPageViewController:(SCPageViewController *)pageViewController
{
	return index;
}

- (CATransform3D)sublayerTransformForViewController:(UIViewController *)viewController
										  withIndex:(NSUInteger)index
									  contentOffset:(CGPoint)contentOffset
										 finalFrame:(CGRect)finalFrame
							   inPageViewController:(SCPageViewController *)pageViewController
{
	return [self _sublayerTransformWithNumberOfPages:pageViewController.numberOfPages andContentOffset:contentOffset];
}

- (void)animatePageInsertionAtIndex:(NSUInteger)index
					 viewController:(UIViewController *)viewController
				 pageViewController:(SCPageViewController *)pageViewController
						 completion:(void (^)())completion
{
	CGRect finalFrame = [self finalFrameForPageAtIndex:index inPageViewController:pageViewController];
	CATransform3D sublayerTransform = [self _sublayerTransformWithNumberOfPages:pageViewController.numberOfPages andContentOffset:CGPointZero];
	
	[viewController.view setFrame:CGRectOffset(finalFrame, 0.0f, CGRectGetHeight(finalFrame))];
	[viewController.view setAlpha:0.0f];
	
	[UIView animateWithDuration:0.25f animations:^{
		[viewController.view setFrame:finalFrame];
		[viewController.view setAlpha:1.0f];
		[(CALayer *)viewController.view.layer.sublayers.firstObject setTransform:sublayerTransform];
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
		[viewController.view setFrame:CGRectOffset(finalFrame, -CGRectGetMaxX(finalFrame), 0.0f)];
		[viewController.view setAlpha:0.0f];
	} completion:^(BOOL finished) {
		completion();
	}];
}

#pragma mark - Private

- (CATransform3D)_sublayerTransformWithNumberOfPages:(NSUInteger)numberOfPages andContentOffset:(CGPoint)contentOffset
{
	CATransform3D transform = CATransform3DIdentity;
	transform.m34 = 1.0 / 995;
	
	CGFloat angle = MIN(numberOfPages * 10.0f, 60.0f);
	if(contentOffset.y < -self.contentInset.top) {
		angle += (ABS(contentOffset.y) - self.contentInset.top) / 10.0f;
	}
	
	transform = CATransform3DRotate(transform, (angle * M_PI / 180.0f), 1.0f, 0.0f, 0.0f);
	
	return transform;
}

@end
