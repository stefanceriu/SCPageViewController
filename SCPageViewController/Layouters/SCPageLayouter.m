//
//  SCPageLayouter.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouter.h"

@interface SCPageLayouter ()

@end

@implementation SCPageLayouter
@synthesize navigationType;
@synthesize numberOfPagesToPreloadBeforeCurrentPage;
@synthesize numberOfPagesToPreloadAfterCurrentPage;
@synthesize navigationConstraintType;

- (id)init
{
    if(self = [super init]) {
        
        self.navigationType = SCPageLayouterNavigationTypeHorizontal;
        self.navigationConstraintType = SCPageLayouterNavigationContraintTypeForward | SCPageLayouterNavigationContraintTypeReverse;
        
        self.numberOfPagesToPreloadBeforeCurrentPage = 1;
        self.numberOfPagesToPreloadAfterCurrentPage  = 1;
        
        self.interItemSpacing = 50.0f;
    }
    
    return self;
}

- (CGFloat)interItemSpacingForPageViewController:(SCPageViewController *)pageViewController
{
    return self.interItemSpacing;
}

- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
                pageViewController:(SCPageViewController *)pageViewController
{
    CGRect frame = pageViewController.view.bounds;
    
    if(self.navigationType == SCPageLayouterNavigationTypeVertical) {
        frame.origin.y = index * (CGRectGetHeight(frame) + self.interItemSpacing);
    } else {
        frame.origin.x = index * (CGRectGetWidth(frame) + self.interItemSpacing);
    }
    
    return frame;
}

- (void)animatePageReloadAtIndex:(NSUInteger)index
               oldViewController:(UIViewController *)oldViewController
               newViewController:(UIViewController *)newViewController
              pageViewController:(SCPageViewController *)pageViewController
                      completion:(void (^)(void))completion
{
    [newViewController.view setAlpha:0.0f];
    [UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [oldViewController.view setAlpha:0.0f];
        [newViewController.view setAlpha:1.0f];
    } completion:^(BOOL finished) {
        completion();
    }];
}

- (void)animatePageInsertionAtIndex:(NSUInteger)index
                     viewController:(UIViewController *)viewController
                 pageViewController:(SCPageViewController *)pageViewController
                         completion:(void (^)(void))completion
{
    CGRect frame = viewController.view.frame;
    
    if(self.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        [viewController.view setFrame:CGRectOffset(frame, 0.0f, CGRectGetHeight(frame))];
    } else {
        [viewController.view setFrame:CGRectOffset(frame, CGRectGetWidth(frame), 0.0f)];
    }
    
    [viewController.view setAlpha:0.0f];
    
    [UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [viewController.view setFrame:frame];
        [viewController.view setAlpha:1.0f];
    } completion:^(BOOL finished) {
        completion();
    }];
}

- (BOOL)shouldPreserveOffsetForInsertionAtIndex:(NSUInteger)index pageViewController:(SCPageViewController *)pageViewController
{
    return YES;
}

- (void)animatePageDeletionAtIndex:(NSUInteger)index
                    viewController:(UIViewController *)viewController
                pageViewController:(SCPageViewController *)pageViewController
                        completion:(void (^)(void))completion
{
    [UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        if(self.navigationType == SCPageLayouterNavigationTypeHorizontal) {
            [viewController.view setFrame:CGRectOffset(viewController.view.frame, 0.0f, CGRectGetHeight(viewController.view.bounds))];
        } else {
            [viewController.view setFrame:CGRectOffset(viewController.view.frame, CGRectGetWidth(viewController.view.bounds), 0.0f)];
        }
        
        [viewController.view setAlpha:0.0f];
    } completion:^(BOOL finished) {
        completion();
    }];
}

- (void)animatePageMoveFromIndex:(NSUInteger)fromIndex
                         toIndex:(NSUInteger)toIndex
                  viewController:(UIViewController *)viewController
              pageViewController:(SCPageViewController *)pageViewController
                      completion:(void (^)(void))completion
{
    CGRect finalFrame = [self finalFrameForPageAtIndex:toIndex pageViewController:pageViewController];
    
    [UIView animateWithDuration:pageViewController.animationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [viewController.view setFrame:finalFrame];
    } completion:^(BOOL finished) {
        completion();
    }];
}

@end
