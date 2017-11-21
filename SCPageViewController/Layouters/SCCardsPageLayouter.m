//
//  SCCardsPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 23/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCCardsPageLayouter.h"

@implementation SCCardsPageLayouter
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (instancetype)init
{
    if(self = [super init]) {
        
        self.numberOfPagesToPreloadBeforeCurrentPage = 3;
        self.numberOfPagesToPreloadAfterCurrentPage  = 3;
        
        self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
        
        self.pagePercentage = 0.5f;
    }
    
    return self;
}

- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController
{
    CGRect frame = pageViewController.view.bounds;
    CGFloat verticalInset = floor(CGRectGetHeight(frame) - CGRectGetHeight(frame) * self.pagePercentage);
    CGFloat horizontalInset = floor(CGRectGetWidth(frame) - CGRectGetWidth(frame) * self.pagePercentage);
    
    return UIEdgeInsetsMake(verticalInset/2.0f, horizontalInset/2.0f, verticalInset/2.0f, horizontalInset/2.0f);
}

- (CGFloat)interItemSpacingForPageViewController:(SCPageViewController *)pageViewController
{
    switch (self.navigationType) {
        case SCPageLayouterNavigationTypeHorizontal: {
            self.interItemSpacing = floor(CGRectGetWidth(pageViewController.view.bounds)/100.0f);
        }
        case SCPageLayouterNavigationTypeVertical: {
            self.interItemSpacing = floor(CGRectGetHeight(pageViewController.view.bounds)/100.0f);
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

@end
