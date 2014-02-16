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

- (CGRect)currentFrameForViewController:(UIViewController *)viewController
                              withIndex:(NSUInteger)index
                          contentOffset:(CGPoint)contentOffset
                   inPageViewController:(SCPageViewController *)pageViewController;
{
    CGRect frame = pageViewController.view.bounds;
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        frame.origin.y = index * CGRectGetHeight(pageViewController.view.bounds);
    } else {
        frame.origin.x = index * CGRectGetWidth(pageViewController.view.bounds);
    }
    
    return frame;
}

@end
