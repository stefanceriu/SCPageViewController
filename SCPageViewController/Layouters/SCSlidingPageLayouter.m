//
//  SCSlidingPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCSlidingPageLayouter.h"

@implementation SCSlidingPageLayouter
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
        frame.origin.y = MAX(frame.origin.y - frame.size.height, MIN(CGRectGetMaxY(frame) - CGRectGetHeight(frame), CGRectGetHeight(pageViewController.view.bounds) - CGRectGetHeight(frame) + contentOffset.y));
    } else {
        frame.origin.x = MAX(frame.origin.x - frame.size.width, MIN(CGRectGetMaxX(frame) - CGRectGetWidth(frame), CGRectGetWidth(pageViewController.view.bounds) - CGRectGetWidth(frame) + contentOffset.x));
    }
    
    return frame;
}

@end
