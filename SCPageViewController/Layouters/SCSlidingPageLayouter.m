//
//  SCSlidingPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCSlidingPageLayouter.h"

@implementation SCSlidingPageLayouter

- (id)init
{
	if(self = [super init]) {
		self.interItemSpacing = 0.0f;
	}
	
	return self;
}

- (CGRect)currentFrameForViewController:(UIViewController *)viewController
							  withIndex:(NSUInteger)index
						  contentOffset:(CGPoint)contentOffset
							 finalFrame:(CGRect)finalFrame
				   inPageViewController:(SCPageViewController *)pageViewController
{
	if(index == 0) {
		return finalFrame;
	}
	
	if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
		finalFrame.origin.y = MAX(finalFrame.origin.y - finalFrame.size.height, MIN(CGRectGetMaxY(finalFrame) - CGRectGetHeight(finalFrame), contentOffset.y));
	} else {
		finalFrame.origin.x = MAX(finalFrame.origin.x - finalFrame.size.width, MIN(CGRectGetMaxX(finalFrame) - CGRectGetWidth(finalFrame), contentOffset.x));
	}
	
	return finalFrame;
}

- (NSUInteger)zPositionForViewController:(UIViewController *)viewController
							   withIndex:(NSUInteger)index
						   numberOfPages:(NSUInteger)numberOfPages
					inPageViewController:(SCPageViewController *)pageViewController
{
	if(numberOfPages == 0) {
		return 0;
	}
	
	return numberOfPages - index - 1;
}

@end
