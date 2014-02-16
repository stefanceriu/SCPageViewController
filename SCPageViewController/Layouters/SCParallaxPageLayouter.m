//
//  SCParallaxPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCParallaxPageLayouter.h"

@implementation SCParallaxPageLayouter
@synthesize navigationType;

- (CGRect)currentFrameForViewController:(UIViewController *)viewController
                              withIndex:(NSUInteger)index
                          contentOffset:(CGPoint)contentOffset
                   inPageViewController:(SCPageViewController *)pageViewController
{
    CGRect frame = pageViewController.view.bounds;
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        frame.origin.y = index * CGRectGetHeight(pageViewController.view.bounds);
    } else {
        frame.origin.x = index * CGRectGetWidth(pageViewController.view.bounds);
    }
    
    if(index == 0) {
        return frame;
    }
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        CGFloat ratio = 1.0f - (CGRectGetMinY(frame) - contentOffset.y) / (CGRectGetHeight(frame) + CGRectGetHeight(frame)/2);
        frame.origin.y = (CGRectGetMinY(frame) - CGRectGetHeight(frame)) + CGRectGetHeight(frame) * MAX(0.0f, MIN(1.0f, ratio));
    } else {
        CGFloat ratio = 1.0f - (CGRectGetMinX(frame) - contentOffset.x) / (CGRectGetWidth(frame) + CGRectGetWidth(frame)/2);
        frame.origin.x = (CGRectGetMinX(frame) - CGRectGetWidth(frame)) + CGRectGetWidth(frame) * MAX(0.0f, MIN(1.0f, ratio));
    }
    
    return frame;
}

@end
