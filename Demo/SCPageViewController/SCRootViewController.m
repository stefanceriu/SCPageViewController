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

@property (nonatomic, assign) NSUInteger numberOfPages;

@end

@implementation SCRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.numberOfPages = 1;
    
    self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
    
    [self.pageViewController willMoveToParentViewController:self];
    [self.pageViewController.view setFrame:self.view.bounds];
    [self.view addSubview:self.pageViewController.view];
    [self addChildViewController:self.pageViewController];
    
    [self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController
{
    return self.numberOfPages;
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
    [controller.pageNumberLabel setText:[NSString stringWithFormat:@"Page %lu of %lu", (unsigned long)index + 1, (unsigned long)pageViewController.numberOfPages]];
    
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

- (void)mainViewControllerDidRequestNavigationToNextPage:(SCMainViewController *)mainViewController
{
    [self.pageViewController navigateToPageAtIndex:MIN(self.pageViewController.numberOfPages, self.pageViewController.currentPage + 1) animated:YES completion:nil];
}

- (void)mainViewControllerDidRequestNavigationToPreviousPage:(SCMainViewController *)mainViewController
{
    [self.pageViewController navigateToPageAtIndex:MAX(0, self.pageViewController.currentPage - 1) animated:YES completion:nil];
}

- (void)mainViewControllerDidRequestPageInsertion:(SCMainViewController *)mainViewController
{
	__block id key;
	[self.viewControllerCache.allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([[self.viewControllerCache objectForKey:obj] isEqual:mainViewController]) {
			key = obj;
			*stop = YES;
		}
	}];
	
	[self insertPageAtIndex:[key unsignedIntegerValue]];
}

- (void)mainViewControllerDidRequestPageDeletion:(SCMainViewController *)mainViewController
{
	__block id key;
	[self.viewControllerCache.allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([[self.viewControllerCache objectForKey:obj] isEqual:mainViewController]) {
			key = obj;
			*stop = YES;
		}
	}];
	
	[self removePageAtIndex:[key unsignedIntegerValue]];
}

- (void)insertPageAtIndex:(NSUInteger)index
{
	for(NSInteger i = self.numberOfPages - 1; i >= (NSInteger)index; i--) {
		UIViewController *viewController = self.viewControllerCache[@(i)];
		if(viewController) {
			[self.viewControllerCache removeObjectForKey:@(i)];
			[self.viewControllerCache setObject:viewController forKey:@(i+1)];
		}
	}
	
	self.numberOfPages++;
	
	[self.pageViewController insertPageAtIndex:index animated:YES completion:nil] ;
}

- (void)removePageAtIndex:(NSUInteger)index
{
	[self.viewControllerCache removeObjectForKey:@(index)];
	
	for(NSUInteger i = index + 1; i < self.numberOfPages; i++) {
		UIViewController *viewController = self.viewControllerCache[@(i)];
		if(viewController) {
			[self.viewControllerCache removeObjectForKey:@(i)];
			[self.viewControllerCache setObject:viewController forKey:@(i-1)];
		}
	}
	
	self.numberOfPages--;
	
	[self.pageViewController removePageAtIndex:index animated:YES completion:nil];
}

- (void)movePageFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
	UIViewController *viewController = [self.viewControllerCache objectForKey:@(fromIndex)];
	[self.viewControllerCache removeObjectForKey:@(fromIndex)];
	
	for(NSUInteger i = fromIndex + 1; i <= toIndex; i++) {
		UIViewController *viewController = self.viewControllerCache[@(i)];
		if(viewController) {
			[self.viewControllerCache removeObjectForKey:@(i)];
			[self.viewControllerCache setObject:viewController forKey:@(i-1)];
		}
	}
	
	[self.viewControllerCache setObject:viewController forKey:@(toIndex)];
	
	[self.pageViewController movePageAtIndex:fromIndex toIndex:toIndex animated:YES completion:nil];
}

- (void)reloadPageAtIndex:(NSUInteger)index
{
	[self.viewControllerCache removeObjectForKey:@(index)];
	
	for(NSUInteger i = index + 1; i < self.numberOfPages; i++) {
		UIViewController *viewController = self.viewControllerCache[@(i)];
		if(viewController) {
			[self.viewControllerCache removeObjectForKey:@(i)];
			[self.viewControllerCache setObject:viewController forKey:@(i-1)];
		}
	}
	
	[self.pageViewController reloadPageAtIndex:index animated:YES completion:nil];
}

#pragma mark - Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
