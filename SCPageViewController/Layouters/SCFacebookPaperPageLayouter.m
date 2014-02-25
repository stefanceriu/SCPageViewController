//
//  SCFacebookPaperPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 23/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCFacebookPaperPageLayouter.h"

static const CGFloat horizontalInset = 192.0f;
static const CGFloat verticalInset = 256.0f;

@implementation SCFacebookPaperPageLayouter
@synthesize interItemSpacing;
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize contentInsets;
@synthesize navigationConstraintType;


- (id)init
{
    if(self = [super init]) {
        self.interItemSpacing = 20.0f;
        
        self.numberOfPagesToPreloadBeforeCurrentPage = 2;
        self.numberOfPagesToPreloadAfterCurrentPage  = 2;
        
        self.contentInsets = UIEdgeInsetsMake(0, 0, 0, 384);
        
        self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
    }
    
    return self;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
              inPageViewController:(SCPageViewController *)pageViewController
{
    CGRect frame = CGRectInset(pageViewController.view.bounds, horizontalInset, verticalInset);
    frame.origin = CGPointZero;
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
        frame.origin.x = CGRectGetWidth(pageViewController.view.bounds) - CGRectGetWidth(frame);
    } else {
        frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
        frame.origin.y = CGRectGetHeight(pageViewController.view.bounds) - CGRectGetHeight(frame);
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
