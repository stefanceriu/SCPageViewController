//
//  SCParallaxPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCParallaxPageLayouter.h"

@implementation SCParallaxPageLayouter

- (id)init
{
    if(self = [super init]) {
        self.interItemSpacing = 0.0f;
    }
    
    return self;
}

- (CGRect)currentFrameForPageAtIndex:(NSUInteger)index
                       contentOffset:(CGPoint)contentOffset
                          finalFrame:(CGRect)finalFrame
                  pageViewController:(SCPageViewController *)pageViewController
{
    if(index == 0) {
        return finalFrame;
    }
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        CGFloat ratio = 1.0f - (CGRectGetMinY(finalFrame) - contentOffset.y) / (CGRectGetHeight(finalFrame) + CGRectGetHeight(finalFrame)/2);
        finalFrame.origin.y = (CGRectGetMinY(finalFrame) - CGRectGetHeight(finalFrame)) + CGRectGetHeight(finalFrame) * MAX(0.0f, MIN(1.0f, ratio));
    } else {
        CGFloat ratio = 1.0f - (CGRectGetMinX(finalFrame) - contentOffset.x) / (CGRectGetWidth(finalFrame) + CGRectGetWidth(finalFrame)/2);
        finalFrame.origin.x = (CGRectGetMinX(finalFrame) - CGRectGetWidth(finalFrame)) + CGRectGetWidth(finalFrame) * MAX(0.0f, MIN(1.0f, ratio));
    }
    
    return finalFrame;
}

@end
