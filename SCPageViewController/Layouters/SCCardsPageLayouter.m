//
//  SCCardsPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 23/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCCardsPageLayouter.h"

@implementation SCCardsPageLayouter
@synthesize interItemSpacing;
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

static CGFloat const kPageSizePercentage = 0.5f;

- (id)init
{
	if(self = [super init]) {
		self.interItemSpacing = 20.0f;
		
		self.numberOfPagesToPreloadBeforeCurrentPage = 2;
		self.numberOfPagesToPreloadAfterCurrentPage  = 2;
		
		self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
	}
	
	return self;
}

- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	CGFloat verticalInset = CGRectGetHeight(frame) - CGRectGetHeight(frame) * kPageSizePercentage;
	CGFloat horizontalInset = CGRectGetWidth(frame) - CGRectGetWidth(frame) * kPageSizePercentage;
	
	return UIEdgeInsetsMake(verticalInset/2.0f, horizontalInset/2.0f, verticalInset/2.0f, horizontalInset/2.0f);
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
			  inPageViewController:(SCPageViewController *)pageViewController
{
	CGRect frame = pageViewController.view.bounds;
	if(CGSizeEqualToSize(CGSizeZero, self.pageSize)) {
		frame.size.height = frame.size.height * kPageSizePercentage;
		frame.size.width = frame.size.width * kPageSizePercentage;
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

@end
