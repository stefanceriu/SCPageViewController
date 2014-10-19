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

#import "SCPageLayouter.h"
#import "SCSlidingPageLayouter.h"
#import "SCParallaxPageLayouter.h"
#import "SCFacebookPaperPageLayouter.h"

@interface SCRootViewController () <SCPageViewControllerDataSource, SCPageViewControllerDelegate, SCMainViewControllerDelegate>

@property (nonatomic, strong) SCPageViewController *pageViewController;

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
    
//    [self.pageViewController setPagingEnabled:NO];
//    [self.pageViewController setContinuousNavigationEnabled:YES];
//    [self.pageViewController setDecelerationRate:UIScrollViewDecelerationRateNormal];
    
    [self mainViewController:nil didSelectLayouter:SCPageLayouterTypePlain];
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController
{
    return 5;
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
    SCMainViewController *mainViewController = [[SCMainViewController alloc] init];
    [mainViewController setDelegate:self];
    return mainViewController;
}

#pragma mark - SCPageViewControllerDelegate

- (void)pageViewController:(SCPageViewController *)pageViewController didShowViewController:(SCMainViewController *)controller atIndex:(NSUInteger)index
{
    [controller.pageNumberLabel setText:[NSString stringWithFormat:@"Page %ld", (unsigned long)index]];
}

- (void)pageViewController:(SCPageViewController *)pageViewController didNavigateToOffset:(CGPoint)offset
{
    for(SCMainViewController *menuViewController in pageViewController.visibleViewControllers) {
        [menuViewController.visiblePercentageLabel setText:[NSString stringWithFormat:@"%.2f%%", [pageViewController visiblePercentageForViewController:menuViewController]]];
    }
}

#pragma mark - SCMainViewControllerDelegate

- (void)mainViewController:(SCMainViewController *)mainViewController didSelectLayouter:(SCPageLayouterType)type
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
    
    id<SCPageLayouterProtocol> pageLayouter = [[typeToLayouter[@(type)] alloc] init];
    [pageLayouter setNavigationType:UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? SCPageLayouterNavigationTypeHorizontal :SCPageLayouterNavigationTypeVertical];
    
    [self.pageViewController setLayouter:pageLayouter animated:YES completion:nil];
}

#pragma mark - Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.pageViewController.layouter setNavigationType:UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? SCPageLayouterNavigationTypeHorizontal :SCPageLayouterNavigationTypeVertical];
}

@end
