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
#import "SCCardsPageLayouter.h"
#import "SCSafariPageLayouter.h"

#import "UIColor+RandomColors.h"

static const NSUInteger kDefaultNumberOfPages = 4;

@interface SCRootViewController () <SCPageViewControllerDataSource, SCPageViewControllerDelegate, SCMainViewControllerDelegate>

@property (nonatomic, strong) SCPageViewController *pageViewController;

@property (nonatomic, assign) SCEasingFunctionType selectedEasingFunctionType;
@property (nonatomic, strong) NSMutableArray *viewControllers;

@end

@implementation SCRootViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.viewControllers = [NSMutableArray array];
	for(int i=0; i < kDefaultNumberOfPages; i++) {
		[self.viewControllers addObject:[NSNull null]];
	}
	
	self.pageViewController = [[SCPageViewController alloc] init];
	[self.pageViewController setDataSource:self];
	[self.pageViewController setDelegate:self];
	
	[self.pageViewController willMoveToParentViewController:self];
	[self.pageViewController.view setFrame:self.view.bounds];
	[self.view addSubview:self.pageViewController.view];
	[self addChildViewController:self.pageViewController];
	
	[self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
	[self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
	
	[self.pageViewController setPagingEnabled:YES];
	[self.pageViewController setContinuousNavigationEnabled:YES];
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController
{
	return self.viewControllers.count;
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
	SCMainViewController *viewController = self.viewControllers[pageIndex];
	
	if([viewController isEqual:[NSNull null]]) {
		viewController = [[SCMainViewController alloc] init];
		[viewController.view setFrame:self.view.bounds];
		[viewController setDelegate:self];
		[viewController.contentView setBackgroundColor:[UIColor randomColor]];
		
		[self.viewControllers replaceObjectAtIndex:pageIndex withObject:viewController];
	}
	
	return viewController;
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
		layouterToType = (@{NSStringFromClass([SCPageLayouter class])         : @(SCPageLayouterTypePlain),
							NSStringFromClass([SCSlidingPageLayouter class])  : @(SCPageLayouterTypeSliding),
							NSStringFromClass([SCParallaxPageLayouter class]) : @(SCPageLayouterTypeParallax),
							NSStringFromClass([SCCardsPageLayouter class])    : @(SCPageLayouterTypeCards),
							NSStringFromClass([SCSafariPageLayouter class])   : @(SCPageLayouterTypeSafari)});
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
		typeToLayouter = (@{@(SCPageLayouterTypePlain)    : [SCPageLayouter class],
							@(SCPageLayouterTypeSliding)  : [SCSlidingPageLayouter class],
							@(SCPageLayouterTypeParallax) : [SCParallaxPageLayouter class],
							@(SCPageLayouterTypeCards)    : [SCCardsPageLayouter class],
							@(SCPageLayouterTypeSafari)   : [SCSafariPageLayouter class]});
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
	[self insertPageAtIndex:[self.viewControllers indexOfObject:mainViewController]];
	
	//	[self movePageFromIndex:self.numberOfPages - 1 toIndex:0];
	//	[self movePageFromIndex:0 toIndex:self.numberOfPages - 1];
}

- (void)mainViewControllerDidRequestPageDeletion:(SCMainViewController *)mainViewController
{
	[self deletePageAtIndex:[self.viewControllers indexOfObject:mainViewController] + 1];
	
	//	[self movePageFromIndex:self.numberOfPages - 1 toIndex:0];
	//	[self movePageFromIndex:0 toIndex:self.numberOfPages - 1];
}

- (void)insertPageAtIndex:(NSUInteger)index
{
	[self.viewControllers insertObject:[NSNull null] atIndex:index];
	[self.pageViewController insertPageAtIndex:index animated:YES completion:nil];
}

- (void)deletePageAtIndex:(NSUInteger)index
{
	[self.viewControllers removeObjectAtIndex:index];
	[self.pageViewController deletePageAtIndex:index animated:YES completion:nil];
}

- (void)movePageFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
	UIViewController *viewController = [self.viewControllers objectAtIndex:fromIndex];
	[self.viewControllers removeObjectAtIndex:fromIndex];
	[self.viewControllers insertObject:viewController atIndex:toIndex];
	
	[self.pageViewController movePageAtIndex:fromIndex toIndex:toIndex animated:YES completion:nil];
}

- (void)reloadPageAtIndex:(NSUInteger)index
{
	[self.viewControllers replaceObjectAtIndex:index withObject:[NSNull null]];
	[self.pageViewController reloadPageAtIndex:index animated:YES completion:nil];
}

#pragma mark - Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
