//
//  SCRootViewController.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCRootViewController.h"
#import "SCPageViewController.h"
#import "SCMainViewController.h"

#import "SCEasingFunction.h"

#import "SCPageLayouter.h"
#import "SCSlidingPageLayouter.h"
#import "SCParallaxPageLayouter.h"
#import "SCFacebookPaperPageLayouter.h"

#import "UIColor+RandomColors.h"

@interface SCRootViewController () <SCPageViewControllerDataSource, SCPageViewControllerDelegate, SCMainViewControllerDelegate>

@property (nonatomic, strong) SCPageViewController *pageViewController;

@property (nonatomic, assign) SCEasingFunctionType selectedEasingFunctionType;
@property (nonatomic, strong) NSMutableDictionary *viewControllerCache;

@end

@implementation SCRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
    
    [self.pageViewController willMoveToParentViewController:self];
    [self.pageViewController.view setFrame:self.view.bounds];
    [self.view addSubview:self.pageViewController.view];
    [self addChildViewController:self.pageViewController];
    
    [self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
    
    //[self.pageViewController setPagingEnabled:NO];
    
    //[self.pageViewController setContinuousNavigationEnabled:YES];
    
    //[self.pageViewController setDecelerationRate:UIScrollViewDecelerationRateNormal];
    
    //[self.pageViewController setBounces:NO];
    
    //[self.pageViewController setMinimumNumberOfTouches:2];
    //[self.pageViewController setMaximumNumberOfTouches:1];
    
    //[self.pageViewController setTouchRefusalArea:[UIBezierPath bezierPathWithRect:CGRectInset(self.view.bounds, 50, 50)]];
    
    //[self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    //[self.pageViewController setAnimationDuration:1.0f];
    
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController
{
    return 5;
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
    if(self.viewControllerCache == nil) {
        self.viewControllerCache = [NSMutableDictionary dictionary];
    }
    
    SCMainViewController *mainViewController = self.viewControllerCache[@(pageIndex)];
    
    if(mainViewController == nil) {
        mainViewController = [[SCMainViewController alloc] init];
        [mainViewController.view setFrame:self.view.bounds];
        [mainViewController setDelegate:self];
        [mainViewController.view setBackgroundColor:[UIColor randomColor]];
        
        self.viewControllerCache[@(pageIndex)] = mainViewController;
    }
    
    return mainViewController;
}

#pragma mark - SCPageViewControllerDelegate

- (void)pageViewController:(SCPageViewController *)pageViewController didShowViewController:(SCMainViewController *)controller atIndex:(NSUInteger)index
{
    [controller.pageNumberLabel setText:[NSString stringWithFormat:@"Page %ld", (unsigned long)index]];
    
    [controller setEasingFunctionType:self.selectedEasingFunctionType];
    [controller setDuration:self.pageViewController.animationDuration];
    
    static NSDictionary *layouterToType;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        layouterToType = (@{
                            NSStringFromClass([SCPageLayouter class])              : @(SCPageLayouterTypePlain),
                            NSStringFromClass([SCSlidingPageLayouter class])       : @(SCPageLayouterTypeSliding),
                            NSStringFromClass([SCParallaxPageLayouter class])      : @(SCPageLayouterTypeParallax),
                            NSStringFromClass([SCFacebookPaperPageLayouter class]) : @(SCPageLayouterTypeFacebookPaper)
                            });
    });
    
    [controller setLayouterType:(SCPageLayouterType)[layouterToType[NSStringFromClass([self.pageViewController.layouter class])] unsignedIntegerValue]];
}

- (void)pageViewController:(SCPageViewController *)pageViewController didNavigateToOffset:(CGPoint)offset
{
    for(SCMainViewController *menuViewController in pageViewController.visibleViewControllers) {
        [menuViewController.visiblePercentageLabel setText:[NSString stringWithFormat:@"%.2f%%", [pageViewController visiblePercentageForViewController:menuViewController]]];
    }
}

#pragma mark - SCMainViewControllerDelegate

- (void)mainViewControllerDidChangeLayouterType:(SCMainViewController *)mainViewController
{
    static NSDictionary *typeToLayouter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeToLayouter = (@{
                            @(SCPageLayouterTypePlain)          : [SCPageLayouter class],
                            @(SCPageLayouterTypeSliding)        : [SCSlidingPageLayouter class],
                            @(SCPageLayouterTypeParallax)       : [SCParallaxPageLayouter class],
                            @(SCPageLayouterTypeFacebookPaper)  : [SCFacebookPaperPageLayouter class],
                            });
    });
    
    id<SCPageLayouterProtocol> pageLayouter = [[typeToLayouter[@(mainViewController.layouterType)] alloc] init];
    [self.pageViewController setLayouter:pageLayouter animated:YES completion:nil];
}

- (void)mainViewControllerDidChangeAnimationType:(SCMainViewController *)mainViewController
{
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:mainViewController.easingFunctionType]];
    self.selectedEasingFunctionType = mainViewController.easingFunctionType;
}

- (void)mainViewControllerDidChangeAnimationDuration:(SCMainViewController *)mainViewController
{
    [self.pageViewController setAnimationDuration:mainViewController.duration];
}

- (void)mainViewControllerDiDRequestNavigationToNextPage:(SCMainViewController *)mainViewController
{
    [self.pageViewController navigateToPageAtIndex:MIN(self.pageViewController.numberOfPages, self.pageViewController.currentPage + 1) animated:YES completion:nil];
}

- (void)mainViewControllerDidRequestNavigationToPreviousPage:(SCMainViewController *)mainViewController
{
    [self.pageViewController navigateToPageAtIndex:MAX(0, self.pageViewController.currentPage - 1) animated:YES completion:nil];
}

#pragma mark - Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
