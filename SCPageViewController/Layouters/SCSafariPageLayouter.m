//
//  SCSafariPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 6/16/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCSafariPageLayouter.h"

@interface SCSafariPageLayouter ()

@property (nonatomic, assign) CGFloat pagePercentage;

@property (nonatomic, assign) UIEdgeInsets contentInset;

@end

@implementation SCSafariPageLayouter
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (instancetype)init
{
	if(self = [super init]) {

		self.navigationType = SCPageLayouterNavigationTypeVertical;
		self.navigationConstraintType = SCPageLayouterNavigationContraintTypeNone;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 5;
		self.numberOfPagesToPreloadAfterCurrentPage  = 5;
		
		self.pagePercentage = 0.5f;
	}
	
	return self;
}

- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	CGFloat verticalInset = CGRectGetHeight(frame) - CGRectGetHeight(frame) * self.pagePercentage;
	CGFloat horizontalInset = CGRectGetWidth(frame) - CGRectGetWidth(frame) * self.pagePercentage;
	
	self.contentInset = UIEdgeInsetsMake(verticalInset/2.0f, horizontalInset/2.0f, verticalInset/2.0f, horizontalInset/2.0f);
	
	return self.contentInset;
}

- (CGFloat)interItemSpacingForPageViewController:(SCPageViewController *)pageViewController
{
	switch (self.navigationType) {
		case SCPageLayouterNavigationTypeHorizontal: {
			self.interItemSpacing = -CGRectGetWidth(pageViewController.view.bounds)/3.0f;
		}
		case SCPageLayouterNavigationTypeVertical: {
			self.interItemSpacing = -CGRectGetHeight(pageViewController.view.bounds)/3.0f;
		}
	}
	
	return self.interItemSpacing;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
				pageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	frame.size.height = frame.size.height * self.pagePercentage;
	frame.size.width = frame.size.width * self.pagePercentage;
	
	if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
		frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
		frame.origin.x = CGRectGetMidX(pageViewController.view.bounds) - CGRectGetMidX(frame);
	} else {
		frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
		frame.origin.y = CGRectGetMidY(pageViewController.view.bounds) - CGRectGetMidY(frame);
	}
	
	return frame;
}

- (NSUInteger)zPositionForPageAtIndex:(NSUInteger)index
				   pageViewController:(SCPageViewController *)pageViewController
{
	return index;
}

- (CATransform3D)sublayerTransformForPageAtIndex:(NSUInteger)index
								   contentOffset:(CGPoint)contentOffset
							  pageViewController:(SCPageViewController *)pageViewController
{
	return [self _sublayerTransformWithNumberOfPages:pageViewController.numberOfPages andContentOffset:contentOffset];
}

- (void)animatePageInsertionAtIndex:(NSUInteger)index
					 viewController:(UIViewController *)viewController
				 pageViewController:(SCPageViewController *)pageViewController
						 completion:(void (^)())completion
{
	CGRect frame = viewController.view.frame;
	CATransform3D sublayerTransform = [self _sublayerTransformWithNumberOfPages:pageViewController.numberOfPages andContentOffset:CGPointZero];
	
	[viewController.view setFrame:CGRectOffset(frame, 0.0f, CGRectGetHeight(frame))];
	[viewController.view setAlpha:0.0f];
	
	[UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
		[viewController.view setFrame:frame];
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
	[UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
		[viewController.view setFrame:CGRectOffset(viewController.view.frame, -CGRectGetMaxX(viewController.view.bounds), 0.0f)];
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
