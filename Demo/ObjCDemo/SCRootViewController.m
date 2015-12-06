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

#import "UIColor+RandomColors.h"

static const NSUInteger kDefaultNumberOfPages = 5;

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
	
	[self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
	[self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    
	[self addChildViewController:self.pageViewController];
	[self.pageViewController.view setFrame:self.view.bounds];
	[self.view addSubview:self.pageViewController.view];
	[self.pageViewController didMoveToParentViewController:self];
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

- (void)pageViewController:(SCPageViewController *)pageViewController didNavigateToOffset:(CGPoint)offset
{
	[self _updateViewControllerDetails];
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
							@(SCPageLayouterTypeCards)    : [SCCardsPageLayouter class]});
	});
	
	id<SCPageLayouterProtocol> pageLayouter = [[typeToLayouter[@(mainViewController.layouterType)] alloc] init];
	[self.pageViewController setLayouter:pageLayouter animated:YES completion:nil];
	
	[self _updateViewControllerDetails];
}

- (void)mainViewControllerDidChangeAnimationType:(SCMainViewController *)mainViewController
{
	[self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:mainViewController.easingFunctionType]];
	self.selectedEasingFunctionType = mainViewController.easingFunctionType;
	
	[self _updateViewControllerDetails];
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
	[self _insertPagesAtIndexes:[NSIndexSet indexSetWithIndex:[self.viewControllers indexOfObject:mainViewController]]];
	[self _updateViewControllerDetails];
}

- (void)mainViewControllerDidRequestPageDeletion:(SCMainViewController *)mainViewController
{
	[self _deletePagesAtIndexes:[NSIndexSet indexSetWithIndex:[self.viewControllers indexOfObject:mainViewController]]];
	[self _updateViewControllerDetails];
}

#pragma mark - Private

- (void)_reloadPagesAtIndexes:(NSIndexSet *)indexes
{
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[self.viewControllers replaceObjectAtIndex:idx withObject:[NSNull null]];
	}];
	
	[self.pageViewController reloadPagesAtIndexes:indexes animated:YES completion:nil];
}

- (void)_insertPagesAtIndexes:(NSIndexSet *)indexes
{
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[self.viewControllers insertObject:[NSNull null] atIndex:idx];
	}];
	
	[self.pageViewController insertPagesAtIndexes:indexes animated:YES completion:nil];
}

- (void)_deletePagesAtIndexes:(NSIndexSet *)indexes
{
	[indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
		[self.viewControllers removeObjectAtIndex:idx];
	}];
	
	[self.pageViewController deletePagesAtIndexes:indexes animated:YES completion:nil];
}

- (void)_movePageFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
	UIViewController *viewController = [self.viewControllers objectAtIndex:fromIndex];
	[self.viewControllers removeObjectAtIndex:fromIndex];
	[self.viewControllers insertObject:viewController atIndex:toIndex];
	
	[self.pageViewController movePageAtIndex:fromIndex toIndex:toIndex animated:YES completion:nil];
}

- (void)_updateViewControllerDetails
{
	[self.viewControllers enumerateObjectsUsingBlock:^(SCMainViewController *controller, NSUInteger index, BOOL *stop) {
		
		if([controller isEqual:[NSNull null]]) {
			return;
		}
		
		[controller.visiblePercentageLabel setText:[NSString stringWithFormat:@"%.2f%%", [self.pageViewController visiblePercentageForViewController:controller]]];
		
		[controller.pageNumberLabel setText:[NSString stringWithFormat:@"Page %lu of %lu", (unsigned long)index, (unsigned long)self.pageViewController.numberOfPages]];
		
		[controller setEasingFunctionType:self.selectedEasingFunctionType];
		[controller setDuration:self.pageViewController.animationDuration];
		
		static NSDictionary *layouterToType;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			layouterToType = (@{NSStringFromClass([SCPageLayouter class])         : @(SCPageLayouterTypePlain),
								NSStringFromClass([SCSlidingPageLayouter class])  : @(SCPageLayouterTypeSliding),
								NSStringFromClass([SCParallaxPageLayouter class]) : @(SCPageLayouterTypeParallax),
								NSStringFromClass([SCCardsPageLayouter class])    : @(SCPageLayouterTypeCards)});
		});
		
		[controller setLayouterType:(SCPageLayouterType)[layouterToType[NSStringFromClass([self.pageViewController.layouter class])] unsignedIntegerValue]];
	}];
}

@end
