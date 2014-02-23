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

- (id)init
{
    if(self = [super init]) {
        self.interItemSpacing = 50.0f;
    }
    
    return self;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
              inPageViewController:(SCPageViewController *)pageViewController
{
    CGRect frame = pageViewController.view.bounds;
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        frame.origin.y = index * CGRectGetHeight(pageViewController.view.bounds);
    } else {
        frame.origin.x = index * (CGRectGetWidth(pageViewController.view.bounds) + self.interItemSpacing);
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
