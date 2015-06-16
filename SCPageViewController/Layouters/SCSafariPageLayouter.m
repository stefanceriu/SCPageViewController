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

- (id)init
{
	if(self = [super init]) {
		self.interItemSpacing = - 300.0f;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 3;
		self.numberOfPagesToPreloadAfterCurrentPage  = 3;
		
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
		
		return UIEdgeInsetsMake(verticalInset/2.0f, horizontalInset/2.0f, verticalInset/2.0f, horizontalInset/2.0f);
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

- (CATransform3D)sublayerTransformForViewController:(UIViewController *)viewController
										  withIndex:(NSUInteger)index
									  contentOffset:(CGPoint)contentOffset
										 finalFrame:(CGRect)finalFrame
							   inPageViewController:(SCPageViewController *)pageViewController
{
	CATransform3D transform = CATransform3DIdentity;
	transform.m34 = 0.00035f;
	
	CGFloat visiblePercentage = [pageViewController visiblePercentageForViewController:viewController];
	CGFloat angle = (30.0f - visiblePercentage * 30.0f) * M_PI / 60.0f;
	transform = CATransform3DRotate(transform, angle, 1.0f, 0.0f, 0.0f);
	
	return transform;
}

@end
