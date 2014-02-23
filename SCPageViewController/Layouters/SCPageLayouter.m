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
@synthesize contentInsets;
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

@end
