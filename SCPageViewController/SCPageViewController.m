//
//  SCPageViewController.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageViewController.h"
#import "SCPageViewControllerView.h"

#import "SCScrollView.h"
#import "SCEasingFunction.h"
#import "SCPageLayouterProtocol.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface SCPageViewController () <SCPageViewControllerViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) SCScrollView *scrollView;

@property (nonatomic, strong) id<SCPageLayouterProtocol> layouter;

@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) NSUInteger numberOfPages;

@property (nonatomic, strong) NSMutableOrderedSet *loadedControllers;
@property (nonatomic, strong) NSMutableArray *visibleControllers;

@property (nonatomic, strong) NSMutableDictionary *pageIndexes;
@property (nonatomic, strong) NSMutableDictionary *visiblePercentages;

@property (nonatomic, assign) BOOL isContentOffsetBlocked;

@property (nonatomic, assign) BOOL isViewVisible;

@end

@implementation SCPageViewController
@dynamic bounces;
@dynamic touchRefusalArea;
@dynamic showsScrollIndicators;
@dynamic minimumNumberOfTouches;
@dynamic maximumNumberOfTouches;
@dynamic scrollEnabled;
@dynamic decelerationRate;

- (id)init
{
	if(self = [super init]) {
		[self commonInit];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self commonInit];
}

- (void)commonInit
{
	self.loadedControllers = [NSMutableOrderedSet orderedSet];
	self.visibleControllers = [NSMutableArray array];
	self.pageIndexes = [NSMutableDictionary dictionary];
	self.visiblePercentages = [NSMutableDictionary dictionary];
	self.pagingEnabled = YES;
	
	self.easingFunction = [SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeSineEaseInOut];
	self.animationDuration = 0.25f;
}

- (void)loadView
{
	SCPageViewControllerView *view = [[SCPageViewControllerView alloc] init];
	[view setDelegate:self];
	self.view = view;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	
	self.scrollView = [[SCScrollView alloc] initWithFrame:self.view.bounds];
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	self.scrollView.delegate = self;
	self.scrollView.clipsToBounds = NO;
	
	[self.view addSubview:self.scrollView];
	
	[self reloadData];
}

- (void)viewWillLayoutSubviews
{
	[self updateBoundsUsingDefaultContraints];
	[self tilePages];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.isViewVisible = YES;
	[self tilePages];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.isViewVisible = NO;
	[self tilePages];
}

#pragma mark - Public Methods

- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
		   animated:(BOOL)animated
		 completion:(void (^)())completion
{
	if([_layouter isEqual:layouter]) {
		return;
	}
	
	_layouter = layouter;
	
	if(!self.isViewLoaded) {
		return; // Will attempt tiling on viewDidLoad
	}
	
	CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:self.currentPage inPageViewController:self];
	
	[UIView animateWithDuration:(animated ? self.animationDuration : 0.0f) animations:^{
		[self tilePages];
		
		CGPoint offset;
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
			offset = [self nextStepOffsetForFrame:finalFrame velocity:CGPointMake(-1.0f, 0.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-1.0f, 0.0f)];
		} else {
			offset = [self nextStepOffsetForFrame:finalFrame velocity:CGPointMake(0.0f, -1.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-.0f, -1.0f)];
		}
		
		[self.scrollView setContentOffset:offset];
		
	} completion:^(BOOL finished) {
		
		[self updateBoundsUsingDefaultContraints];
		
		if(completion) {
			completion();
		}
	}];
}

- (void)reloadData
{
	for(UIViewController *controller in self.loadedControllers) {
		
		if([self.visibleControllers containsObject:controller]) {
			[controller beginAppearanceTransition:NO animated:NO];
		}
		
		[controller willMoveToParentViewController:nil];
		[controller.view removeFromSuperview];
		[controller removeFromParentViewController];
		
		if([self.visibleControllers containsObject:controller]) {
			[controller endAppearanceTransition];
		}
	}
	
	[self.loadedControllers removeAllObjects];
	[self.visibleControllers removeAllObjects];
	[self.visiblePercentages removeAllObjects];
	[self.pageIndexes removeAllObjects];
	
	
	NSUInteger oldNumberOfPages = self.numberOfPages;
	
	self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
	
	if(oldNumberOfPages >= self.numberOfPages) {
		NSUInteger index = MAX(0, (int)self.numberOfPages-1);
		[self navigateToPageAtIndex:index animated:NO completion:nil];
	} else {
		[self updateBoundsUsingDefaultContraints];
		[self tilePages];
	}
}

- (void)reloadPageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)())completion
{
	[self _reloadPageAtIndex:index animated:animated completion:completion];
}

- (void)insertPageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)())completion
{
	[self _insertPageAtIndex:index animated:animated completion:completion];
}

- (void)deletePageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)())completion
{
	[self _deletePageAtIndex:index animated:animated completion:completion];
}

- (void)movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated completion:(void(^)())completion
{
	[self _movePageAtIndex:fromIndex toIndex:toIndex animated:animated completion:completion];
}

- (void)navigateToPageAtIndex:(NSUInteger)pageIndex
					 animated:(BOOL)animated
				   completion:(void(^)())completion
{
	if(pageIndex >= self.numberOfPages) {
		return;
	}
	
	void(^animationFinishedBlock)() = ^{
		
		[self updateBoundsUsingNavigationContraints];
		
		if(!animated && [self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
			[self.delegate pageViewController:self didNavigateToPageAtIndex:pageIndex];
		}
		
		if(completion) {
			completion();
		}
	};
	
	CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self];
	
	if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
		CGFloat delta = (CGRectGetHeight(self.view.bounds) - CGRectGetHeight(finalFrame)) / 2.0f;
		[self.scrollView setContentOffset:CGPointMake(0, CGRectGetMinY(finalFrame) - delta)  easingFunction:self.easingFunction duration:(animated ? self.animationDuration : 0.0f) completion:animationFinishedBlock];
	} else {
		CGFloat delta = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(finalFrame)) / 2.0f;
		[self.scrollView setContentOffset:CGPointMake(CGRectGetMinX(finalFrame) - delta, 0)  easingFunction:self.easingFunction duration:(animated ? self.animationDuration : 0.0f) completion:animationFinishedBlock];
	}
}

- (NSArray *)loadedViewControllers
{
	return [self.loadedControllers copy];
}

- (NSArray *)visibleViewControllers
{
	return [self.visibleControllers copy];
}

- (CGFloat)visiblePercentageForViewController:(UIViewController *)viewController
{
	if(![self.visibleControllers containsObject:viewController]) {
		return 0.0f;
	}
	
	return [self.visiblePercentages[@([viewController hash])] floatValue];
}

- (UIViewController *)viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
	__block UIViewController *controller;
	[self.pageIndexes enumerateKeysAndObjectsUsingBlock:^(NSNumber *hash, NSNumber *index, BOOL *stop) {
		if(index.unsignedIntegerValue == pageIndex) {
			
			NSUInteger viewControllerIndex = [self.loadedControllers indexOfObjectPassingTest:^BOOL(UIViewController *obj, NSUInteger idx, BOOL *internalStop) {
				return (obj.hash == hash.unsignedIntegerValue);
			}];
			
			if(viewControllerIndex != NSNotFound) {
				controller = self.loadedControllers[viewControllerIndex];
			}
			
			*stop = YES;
		}
	}];
	
	return controller;
}

#pragma mark - Page Management

- (void)tilePages
{
	if(self.numberOfPages == 0) {
		return;
	}
	
	self.currentPage = [self _calculateCurrentPage];
	
	NSInteger firstNeededPageIndex = self.currentPage - [self.layouter numberOfPagesToPreloadBeforeCurrentPage];
	firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
	
	
	NSInteger lastNeededPageIndex  = self.currentPage + [self.layouter numberOfPagesToPreloadAfterCurrentPage];
	lastNeededPageIndex  = MIN(lastNeededPageIndex, ((int)self.numberOfPages - 1));
	
	NSMutableSet *removedPages = [NSMutableSet set];
	
	for (UIViewController *page in self.loadedControllers) {
		NSUInteger pageIndex = [self.pageIndexes[@(page.hash)] unsignedIntegerValue];
		
		if (pageIndex < firstNeededPageIndex || pageIndex > lastNeededPageIndex) {
			[removedPages addObject:page];
			[self.pageIndexes removeObjectForKey:@(page.hash)];
			
			[self.visibleControllers removeObject:page];
			
			[page willMoveToParentViewController:nil];
			[page beginAppearanceTransition:NO animated:NO];
			[page.view removeFromSuperview];
			[page endAppearanceTransition];
			[page removeFromParentViewController];
		}
	}
	
	[self.loadedControllers minusSet:removedPages];
	
	for (NSUInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
		
		UIViewController *page = [self viewControllerForPageAtIndex:index];
		if (!page) {
			page = [self.dataSource pageViewController:self viewControllerForPageAtIndex:index];
			
			NSAssert(page, @"Trying to insert nil view controller");
			
			[self.loadedControllers addObject:page];
			[self.pageIndexes setObject:@(index) forKey:@(page.hash)];
			
			[page willMoveToParentViewController:self];
			
			if(index > self.currentPage) {
				[self.scrollView insertSubview:page.view atIndex:0];
			} else {
				[self.scrollView addSubview:page.view];
			}
			
			[self addChildViewController:page];
			[page didMoveToParentViewController:self];
		}
	}
	
	[self updateFramesAndTriggerAppearanceCallbacks];
}

#pragma mark Appearance callbacks and framesetting

- (void)updateFramesAndTriggerAppearanceCallbacks
{
	__block CGRect remainder = self.scrollView.bounds;
	
	if(remainder.origin.x < 0.0f || remainder.origin.y < 0.0f) {
		remainder.size.width += remainder.origin.x;
		remainder.size.height += remainder.origin.y;
		remainder.origin.x = 0.0f;
		remainder.origin.y = 0.0f;
	}
	
	NSMutableSet *allPages = [NSMutableSet set];
	[allPages addObjectsFromArray:self.loadedControllers.array];
	
	NSArray *sortedPages = [allPages.allObjects sortedArrayUsingComparator:^NSComparisonResult(UIViewController *obj1, UIViewController *obj2) {
		NSUInteger firstPageIndex = [self.pageIndexes[@(obj1.hash)] unsignedIntegerValue];
		NSUInteger secondPageIndex = [self.pageIndexes[@(obj2.hash)] unsignedIntegerValue];
		
		return [@(firstPageIndex) compare:@(secondPageIndex)];
	}];
	
	[sortedPages enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
		
		NSUInteger pageIndex = [self.pageIndexes[@(viewController.hash)] unsignedIntegerValue];
		
		CGRect nextFrame =  [self.layouter currentFrameForViewController:viewController
															   withIndex:pageIndex
														   contentOffset:self.scrollView.contentOffset
															  finalFrame:[self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self]
													inPageViewController:self];
		
		CGRect intersection = CGRectIntersection(remainder, nextFrame);
		// If a view controller's frame does intersect the remainder then it's visible
		BOOL visible = self.layouter.navigationType == SCPageLayouterNavigationTypeVertical ? (CGRectGetHeight(intersection) > 0.0f) : (CGRectGetWidth(intersection) > 0.0f);
		
		visible = visible && self.isViewVisible;
		
		if(visible) {
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				[self.visiblePercentages setObject:@(roundf((CGRectGetHeight(intersection) * 1000) / CGRectGetHeight(nextFrame))/1000.0f) forKey:@([viewController hash])];
			} else {
				[self.visiblePercentages setObject:@(roundf((CGRectGetWidth(intersection) * 1000) / CGRectGetWidth(nextFrame))/1000.0f) forKey:@([viewController hash])];
			}
		}
		
		CGRectEdge edge = -1;
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical:
				edge = CGRectMinYEdge;
				break;
			case SCPageLayouterNavigationTypeHorizontal:
				edge = CGRectMinXEdge;
				break;
			default:
				break;
		}
		
		remainder = [self _subtractRect:intersection fromRect:remainder withEdge:edge];
		
		// Finally, trigger appearance callbacks and new frame
		if(visible && ![self.visibleControllers containsObject:viewController]) {
			[self.visibleControllers addObject:viewController];
			[viewController beginAppearanceTransition:YES animated:NO];
			[viewController.view setFrame:nextFrame];
			[viewController endAppearanceTransition];
			
			if([self.delegate respondsToSelector:@selector(pageViewController:didShowViewController:atIndex:)]) {
				[self.delegate pageViewController:self didShowViewController:viewController atIndex:pageIndex];
			}
			
		} else if(!visible && [self.visibleControllers containsObject:viewController]) {
			[self.visibleControllers removeObject:viewController];
			[viewController beginAppearanceTransition:NO animated:NO];
			[viewController.view setFrame:nextFrame];
			[viewController endAppearanceTransition];
			
			if([self.delegate respondsToSelector:@selector(pageViewController:didHideViewController:atIndex:)]) {
				[self.delegate pageViewController:self didHideViewController:viewController atIndex:pageIndex];
			}
			
		} else {
			[viewController.view setFrame:nextFrame];
		}
	}];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
	return NO;
}

#pragma mark Pagination

- (void)adjustTargetContentOffset:(inout CGPoint *)targetContentOffset withVelocity:(CGPoint)velocity
{
	if(!self.pagingEnabled && self.continuousNavigationEnabled) {
		return;
	}
	
	UIEdgeInsets layouterInsets = [self.layouter contentInsetForPageViewController:self];
	
	// Enumerate through all the pages and figure out which one contains the targeted offset
	for(NSUInteger pageIndex = 0; pageIndex < self.numberOfPages; pageIndex ++) {
		
		CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self];
		CGRect adjustedFrame = CGRectOffset(CGRectInset(frame, -self.layouter.interItemSpacing/2, -self.layouter.interItemSpacing/2), self.layouter.interItemSpacing/2, self.layouter.interItemSpacing/2);
		
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical:
				adjustedFrame.origin.x = 0.0f;
				adjustedFrame.origin.y -= layouterInsets.top;
				break;
			case SCPageLayouterNavigationTypeHorizontal:
				adjustedFrame.origin.y = 0.0f;
				adjustedFrame.origin.x -= layouterInsets.left;
				break;
			default:
				break;
		}
		
		if(CGRectContainsPoint(adjustedFrame, *targetContentOffset)) {
			
			// If the velocity is zero then jump to the closest navigation step
			if(CGPointEqualToPoint(CGPointZero, velocity)) {
				
				switch (self.layouter.navigationType) {
					case SCPageLayouterNavigationTypeVertical:
					{
						CGPoint previousStepOffset = [self nextStepOffsetForFrame:adjustedFrame velocity:CGPointMake(0.0f, -1.0f)];
						CGPoint nextStepOffset = [self nextStepOffsetForFrame:adjustedFrame velocity:CGPointMake(0.0f, 1.0f)];
						
						*targetContentOffset = ABS(targetContentOffset->y - previousStepOffset.y) > ABS(targetContentOffset->y - nextStepOffset.y) ? nextStepOffset : previousStepOffset;
						break;
					}
					case SCPageLayouterNavigationTypeHorizontal:
					{
						CGPoint previousStepOffset = [self nextStepOffsetForFrame:adjustedFrame velocity:CGPointMake(-1.0f, 0.0f)];
						CGPoint nextStepOffset = [self nextStepOffsetForFrame:adjustedFrame velocity:CGPointMake(1.0f, 0.0f)];
						
						*targetContentOffset = ABS(targetContentOffset->x - previousStepOffset.x) > ABS(targetContentOffset->x - nextStepOffset.x) ? nextStepOffset : previousStepOffset;
						break;
					}
				}
				
			} else {
				// Calculate the next step of the pagination (either a navigationStep or a controller edge)
				*targetContentOffset = [self nextStepOffsetForFrame:adjustedFrame velocity:velocity];
			}
			
			// Pagination fix for iOS 5.x
			if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
				targetContentOffset->y += 0.1f;
				targetContentOffset->x += 0.1f;
			}
			
			break;
		}
	}
}

#pragma mark - Navigational Constraints

- (void)updateBoundsUsingDefaultContraints
{
	if(self.isContentOffsetBlocked) {
		[UIView animateWithDuration:self.animationDuration animations:^{
			[self.scrollView setContentSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
		}];
		return;
	}
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:self.numberOfPages - 1 inPageViewController:self];
	UIEdgeInsets insets = [self.layouter contentInsetForPageViewController:self];
	
	if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
		[self.scrollView setContentInset:UIEdgeInsetsMake(insets.top, 0.0f, insets.bottom, 0.0f)];
		[self.scrollView setContentSize:CGSizeMake(0, CGRectGetMaxY(frame))];
	} else {
		[self.scrollView setContentInset:UIEdgeInsetsMake(0.0f, insets.left, 0.0f, insets.right)];
		[self.scrollView setContentSize:CGSizeMake(CGRectGetMaxX(frame), CGRectGetHeight(self.view.bounds))];
	}
	
	[self updateBoundsUsingNavigationContraints];
}

- (void)updateBoundsUsingNavigationContraints
{
	if(self.continuousNavigationEnabled || self.isContentOffsetBlocked) {
		return;
	}
	
	UIEdgeInsets insets = UIEdgeInsetsZero;
	UIEdgeInsets layouterInsets = [self.layouter contentInsetForPageViewController:self];
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage == 0 ? 0 : self.currentPage - 1)  inPageViewController:self];
	switch (self.layouter.navigationType) {
		case SCPageLayouterNavigationTypeVertical:
			frame.origin.x = 0.0f;
			frame.origin.y -= layouterInsets.top;
			break;
		case SCPageLayouterNavigationTypeHorizontal:
			frame.origin.y = 0.0f;
			frame.origin.x -= layouterInsets.left;
			break;
		default:
			break;
	}
	
	if(self.layouter.navigationConstraintType & SCPageLayouterNavigationContraintTypeReverse) {
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical: {
				insets.top = -[self nextStepOffsetForFrame:frame velocity:CGPointMake(0.0f, -1.0f)].y;
				break;
			}
			case SCPageLayouterNavigationTypeHorizontal: {
				insets.left = -[self nextStepOffsetForFrame:frame velocity:CGPointMake(-1.0f, 0.0f)].x;
				break;
			}
		}
	}
	
	frame = [self.layouter finalFrameForPageAtIndex:MIN(self.currentPage + 1, self.numberOfPages - 1) inPageViewController:self];
	switch (self.layouter.navigationType) {
		case SCPageLayouterNavigationTypeVertical:
			frame.origin.x = 0.0f;
			frame.origin.y += layouterInsets.top;
			break;
		case SCPageLayouterNavigationTypeHorizontal:
			frame.origin.y = 0.0f;
			frame.origin.x += layouterInsets.left;
			break;
		default:
			break;
	}
	
	if(self.layouter.navigationConstraintType & SCPageLayouterNavigationContraintTypeForward) {
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical: {
				insets.bottom = -(self.scrollView.contentSize.height - ABS([self nextStepOffsetForFrame:frame velocity:CGPointMake(0.0f, 1.0f)].y));
				break;
			}
			case SCPageLayouterNavigationTypeHorizontal: {
				insets.right = -(self.scrollView.contentSize.width - ABS([self nextStepOffsetForFrame:frame velocity:CGPointMake(1.0f, 0.0f)].x));
				break;
			}
		}
	}
	
	[self.scrollView setContentInset:insets];
}

#pragma mark - Step calculations

- (CGPoint)nextStepOffsetForFrame:(CGRect)finalFrame
						 velocity:(CGPoint)velocity
{
	CGPoint nextStepOffset = CGPointZero;
	if(velocity.y > 0.0f) {
		nextStepOffset.y = CGRectGetMaxY(finalFrame);
	} else if(velocity.x > 0.0f) {
		nextStepOffset.x = CGRectGetMaxX(finalFrame);
	} else if(velocity.y < 0.0f) {
		nextStepOffset.y = CGRectGetMinY(finalFrame);
	} else if(velocity.x < 0.0f) {
		nextStepOffset.x = CGRectGetMinX(finalFrame);
	}

	return nextStepOffset;
}

#pragma mark - Properties and forwarding

- (BOOL)showsScrollIndicators
{
	return [self.scrollView showsHorizontalScrollIndicator] && [self.scrollView showsVerticalScrollIndicator];
}

- (void)setShowsScrollIndicators:(BOOL)showsScrollIndicators
{
	[self.scrollView setShowsHorizontalScrollIndicator:showsScrollIndicators];
	[self.scrollView setShowsVerticalScrollIndicator:showsScrollIndicators];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if([self.scrollView respondsToSelector:aSelector]) {
		return self.scrollView;
	} else if([self.scrollView.panGestureRecognizer respondsToSelector:aSelector]) {
		return self.scrollView.panGestureRecognizer;
	} else {
		[NSException raise:@"SCPageViewControllerUnrecognizedSelectorException" format:@"Unrecognized selector %@", NSStringFromSelector(aSelector)];
		return nil;
	}
}

#pragma mark - SCPageViewControllerViewDelegate

- (void)pageViewControllerViewWillChangeFrame:(SCPageViewControllerView *)pageViewControllerView
{
	[self.scrollView setDelegate:nil];
}

- (void)pageViewControllerViewDidChangeFrame:(SCPageViewControllerView *)pageViewControllerView
{
	[self.scrollView setDelegate:self];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if([self.layouter respondsToSelector:@selector(pageViewController:didNavigateToOffset:)]) {
		[self.layouter pageViewController:self didNavigateToOffset:self.scrollView.contentOffset];
	}
	
	if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToOffset:)]) {
		[self.delegate pageViewController:self didNavigateToOffset:self.scrollView.contentOffset];
	}
	
	if(!self.shouldLayoutPagesOnRest) {
		[self tilePages];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(decelerate == NO) {
		
		if(self.shouldLayoutPagesOnRest) {
			[self tilePages];
		}
		
		[self updateBoundsUsingNavigationContraints];
		
		if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
			[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if(self.shouldLayoutPagesOnRest) {
		[self tilePages];
	}
	
	[self updateBoundsUsingNavigationContraints];
	
	if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
		[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	if(self.shouldLayoutPagesOnRest) {
		[self tilePages];
	}
	
	[self updateBoundsUsingNavigationContraints];
	
	if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
		[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // Bouncing target content offset when fix.
    // When trying to adjust content offset while bouncing the velocity drops down to almost nothing.
    // Seems to be an internal UIScrollView issue
	UIEdgeInsets insets = [self.layouter contentInsetForPageViewController:self];
	if(self.scrollView.contentOffset.y < -insets.top) {
		targetContentOffset->y = -insets.top;
	} else if(self.scrollView.contentOffset.x < -insets.left) {
		targetContentOffset->x = -insets.left;
	} else if(self.scrollView.contentOffset.y > ABS((self.scrollView.contentSize.height + insets.bottom) - CGRectGetHeight(self.scrollView.bounds))) {
		targetContentOffset->y = (self.scrollView.contentSize.height + insets.bottom) - CGRectGetHeight(self.scrollView.bounds);
	} else if(self.scrollView.contentOffset.x > ABS((self.scrollView.contentSize.width + insets.right) - CGRectGetWidth(self.scrollView.bounds))) {
		targetContentOffset->x = (self.scrollView.contentSize.width + insets.right) - CGRectGetWidth(self.scrollView.bounds);
	}
	// Normal pagination
	else {
		[self adjustTargetContentOffset:targetContentOffset withVelocity:velocity];
	}
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self blockContentOffset];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self unblockContentOffset];
}

#pragma mark - Content Offset Blocking

- (void)blockContentOffset
{
	self.isContentOffsetBlocked = YES;
	[self updateBoundsUsingDefaultContraints];
	[self.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(self.isContentOffsetBlocked) {
		
		CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:self.currentPage inPageViewController:self];
		
		CGPoint offset;
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
			offset = [self nextStepOffsetForFrame:finalFrame velocity:CGPointMake(-1.0f, 0.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-1.0f, 0.0f)];
		} else {
			offset = [self nextStepOffsetForFrame:finalFrame velocity:CGPointMake(0.0f, -1.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-.0f, -1.0f)];
		}
		
		[self.scrollView setContentOffset:offset];
	}
}

- (void)unblockContentOffset
{
	[self.scrollView setContentOffset:self.scrollView.contentOffset animated:YES];
	[self.scrollView removeObserver:self forKeyPath:@"contentSize"];
	self.isContentOffsetBlocked = NO;
	
	[self updateBoundsUsingDefaultContraints];
}

#pragma mark - Private

- (CGRect)_subtractRect:(CGRect)r2 fromRect:(CGRect)r1 withEdge:(CGRectEdge)edge
{
	CGRect intersection = CGRectIntersection(r1, r2);
	if (CGRectIsNull(intersection)) {
		return r1;
	}
	
	float chopAmount = (edge == CGRectMinXEdge || edge == CGRectMaxXEdge) ? CGRectGetWidth(intersection) : CGRectGetHeight(intersection);
	
	CGRect remainder, throwaway;
	CGRectDivide(r1, &throwaway, &remainder, chopAmount, edge);
	return remainder;
}

- (NSUInteger)_calculateCurrentPage
{
	for(NSUInteger pageIndex = 0; pageIndex < self.numberOfPages; pageIndex ++) {
		CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self];
		
		CGRect adjustedFrame = CGRectOffset(CGRectInset(frame,-self.layouter.interItemSpacing/2, 0),
											self.layouter.interItemSpacing/2, 0);
		
		CGPoint adjustedOffset = CGPointZero;
		
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical:
				adjustedOffset.y = self.scrollView.contentOffset.y + CGRectGetHeight(self.scrollView.bounds)/2;
				adjustedOffset.x = adjustedFrame.origin.x;
				break;
			case SCPageLayouterNavigationTypeHorizontal:
				adjustedOffset.x = self.scrollView.contentOffset.x + CGRectGetWidth(self.scrollView.bounds)/2;
				adjustedOffset.y = adjustedFrame.origin.y;
				break;
			default:
				break;
		}
		
		if(CGRectContainsPoint(adjustedFrame, adjustedOffset)) {
			return pageIndex;
		}
	}
	
	return self.currentPage;
}

- (void)_reloadPageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)())completion
{
	UIViewController *oldViewController = [self viewControllerForPageAtIndex:index];
	[oldViewController willMoveToParentViewController:nil];
	if([self.visibleViewControllers containsObject:oldViewController]) {
		[oldViewController beginAppearanceTransition:NO animated:animated];
	}
	
	UIViewController *newViewController = [self.dataSource pageViewController:self viewControllerForPageAtIndex:index];
	
	NSAssert(newViewController, @"Trying to insert nil view controller");
	
	[self.loadedControllers addObject:newViewController];
	[self.pageIndexes setObject:@(index) forKey:@(newViewController.hash)];
	
	[newViewController willMoveToParentViewController:self];
	
	if(index > self.currentPage) {
		[self.scrollView insertSubview:newViewController.view atIndex:0];
	} else {
		[self.scrollView addSubview:newViewController.view];
	}

	
	[self addChildViewController:newViewController];
	[newViewController didMoveToParentViewController:self];
	
	if([self.layouter respondsToSelector:@selector(animatePageReloadAtIndex:oldViewController:newViewController:pageViewController:completion:)] && animated) {
		[self.layouter animatePageReloadAtIndex:index oldViewController:oldViewController newViewController:newViewController pageViewController:self completion:^{
			
			[oldViewController.view removeFromSuperview];
			if([self.visibleViewControllers containsObject:oldViewController]) {
				[oldViewController endAppearanceTransition];
			}
			
			[oldViewController removeFromParentViewController];
			
			[self.loadedControllers removeObject:oldViewController];
			[self.visibleControllers removeObject:oldViewController];
			[self.visiblePercentages removeObjectForKey:@([oldViewController hash])];
			[self.pageIndexes removeObjectForKey:@([oldViewController hash])];
			
			[self updateBoundsUsingDefaultContraints];
			[self tilePages];
		}];
	}
}

- (void)_insertPageAtIndex:(NSUInteger)insertionIndex animated:(BOOL)animated completion:(void(^)())completion
{
	NSAssert(insertionIndex < self.numberOfPages, @"Index out of bounds");
	
	NSUInteger oldNumberOfPages = self.numberOfPages;
	self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
	
	NSAssert((self.numberOfPages == oldNumberOfPages + 1), @"The number of pages after insertion is equal to the one before");
	
	dispatch_group_t animationsDispatchGroup = dispatch_group_create();
	
	// Update page indexes
	for(NSInteger pageIndex = (NSInteger)(oldNumberOfPages - 1); pageIndex >= (NSInteger)insertionIndex; pageIndex--) {
		UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
		if(someController) {
			[self.pageIndexes setObject:@(pageIndex+1) forKey:@([someController hash])];
		}
	}
	
	// Animate page movements
	BOOL shouldAdjustOffset = (insertionIndex <= self.currentPage);
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		if(shouldAdjustOffset) {
			for(NSInteger pageIndex = (NSInteger)(insertionIndex - 1); pageIndex >= 0; pageIndex--) {
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				
				CGRect frameForAnimation = [self.layouter finalFrameForPageAtIndex:(pageIndex + 1) inPageViewController:self];
				[someController.view setFrame:frameForAnimation];
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:(pageIndex + 1) toIndex:pageIndex viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		} else {
			for(NSInteger pageIndex = oldNumberOfPages; pageIndex >= insertionIndex; pageIndex--) {
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:(pageIndex - 1) toIndex:pageIndex viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	}
	
	// Update the scrollView's offset
	if(shouldAdjustOffset) {
		CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:(self.currentPage + 1) inPageViewController:self];
		
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
			CGPoint offset = self.scrollView.contentOffset;
			offset.y += CGRectGetHeight(finalFrame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		} else {
			CGPoint offset = self.scrollView.contentOffset;
			offset.x += CGRectGetWidth(finalFrame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		}
	}
	
	// Insert the new page
	UIViewController *viewController = [self.dataSource pageViewController:self viewControllerForPageAtIndex:insertionIndex];
	
	NSAssert(viewController, @"Trying to insert nil view controller");
	
	[self.loadedControllers addObject:viewController];
	[self.pageIndexes setObject:@(insertionIndex) forKey:@(viewController.hash)];
	
	[viewController willMoveToParentViewController:self];
	
	if(insertionIndex > self.currentPage) {
		[self.scrollView insertSubview:viewController.view atIndex:0];
	} else {
		[self.scrollView addSubview:viewController.view];
	}
	
	[self addChildViewController:viewController];
	[viewController didMoveToParentViewController:self];
	
	if(animated && [self.layouter respondsToSelector:@selector(animatePageInsertionAtIndex:viewController:pageViewController:completion:)]) {
		dispatch_group_enter(animationsDispatchGroup);
		[self.layouter animatePageInsertionAtIndex:insertionIndex viewController:viewController pageViewController:self completion:^{
			dispatch_group_leave(animationsDispatchGroup);
		}];
	}
	
	// Clean up everything and notify of completion
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		
		[self updateBoundsUsingDefaultContraints];
		[self tilePages];
		
		if(completion) {
			completion();
		}
	});
}

- (void)_deletePageAtIndex:(NSUInteger)deletionIndex animated:(BOOL)animated completion:(void(^)())completion
{
	NSAssert(deletionIndex < self.numberOfPages, @"Index out of bounds");
	
	NSUInteger oldNumberOfPages = self.numberOfPages;
	self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
	
	NSAssert((self.numberOfPages == oldNumberOfPages - 1), @"The number of pages after removal is equal to the one before");
	
	dispatch_group_t animationsDispatchGroup = dispatch_group_create();
	
	UIViewController *viewController = [self viewControllerForPageAtIndex:deletionIndex];
	[viewController willMoveToParentViewController:nil];
	if([self.visibleViewControllers containsObject:viewController]) {
		[viewController beginAppearanceTransition:NO animated:animated];
	}
	
	// Animate the deletion
	if(animated && [self.layouter respondsToSelector:@selector(animatePageDeletionAtIndex:viewController:pageViewController:completion:)]) {
		dispatch_group_enter(animationsDispatchGroup);
		
		[self.layouter animatePageDeletionAtIndex:deletionIndex viewController:viewController pageViewController:self completion:^{
			dispatch_group_leave(animationsDispatchGroup);
		}];
	}
	
	// Animate page movements
	BOOL shouldAdjustOffset = (deletionIndex <= self.currentPage);
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		if(shouldAdjustOffset) {
			for(NSInteger pageIndex = (NSInteger)(deletionIndex - 1); (NSInteger)pageIndex >= 0; pageIndex--) {
				
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				
				CGRect frameForAnimation = [self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self];
				[someController.view setFrame:frameForAnimation];
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:pageIndex toIndex:pageIndex + 1 viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		} else {
			for(NSUInteger pageIndex = deletionIndex + 1; pageIndex < oldNumberOfPages; pageIndex++) {
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:pageIndex toIndex:(pageIndex - 1) viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	}
	
	// Update page indexes
	for(NSUInteger pageIndex = deletionIndex + 1; pageIndex < oldNumberOfPages; pageIndex++) {
		UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
		if(someController) {
			[self.pageIndexes setObject:@(pageIndex-1) forKey:@([someController hash])];
		}
	}
	
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		
		// Update the scrollView's offset
		if(shouldAdjustOffset) {
			CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:(self.currentPage - 1) inPageViewController:self];
			
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				CGPoint offset = self.scrollView.contentOffset;
				offset.y -= CGRectGetHeight(finalFrame) + self.layouter.interItemSpacing;
				[self.scrollView setContentOffset:offset];
			} else {
				CGPoint offset = self.scrollView.contentOffset;
				offset.x -= CGRectGetWidth(finalFrame) + self.layouter.interItemSpacing;
				[self.scrollView setContentOffset:offset];
			}
		}
		
		[viewController.view removeFromSuperview];
		if([self.visibleViewControllers containsObject:viewController]) {
			[viewController endAppearanceTransition];
		}
		
		[viewController removeFromParentViewController];
		
		[self.loadedControllers removeObject:viewController];
		[self.visibleControllers removeObject:viewController];
		[self.visiblePercentages removeObjectForKey:@([viewController hash])];
		[self.pageIndexes removeObjectForKey:@([viewController hash])];
		
		[self updateBoundsUsingDefaultContraints];
		[self tilePages];
		
		if(completion) {
			completion();
		}
	});
}

- (void)_movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated completion:(void(^)())completion
{
	NSAssert(fromIndex < self.numberOfPages, @"Index out of bounds");
	NSAssert(toIndex < self.numberOfPages, @"Index out of bounds");
	NSAssert(self.numberOfPages > 1, @"Not enough pages in the page view controller");
	
	if(fromIndex == toIndex) {
		if(completion) {
			completion();
		}
		
		return;
	}
	
	BOOL shouldAdjustOffset = (![self.visibleViewControllers containsObject:[self viewControllerForPageAtIndex:fromIndex]] &&
							   ![self.visibleViewControllers containsObject:[self viewControllerForPageAtIndex:toIndex]]);
	
	UIViewController *viewController = [self viewControllerForPageAtIndex:fromIndex];
	
	dispatch_group_t animationsDispatchGroup = dispatch_group_create();
	
	if(fromIndex < toIndex) {
		for(NSUInteger pageIndex = fromIndex + 1; pageIndex <= toIndex; pageIndex++) {
			UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
			if(someController) {
				[self.pageIndexes setObject:@(pageIndex-1) forKey:@([someController hash])];
				
				if(shouldAdjustOffset || !animated || ![self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
					continue;
				}
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:pageIndex toIndex:pageIndex-1 viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	} else {
		for(NSInteger pageIndex = (NSInteger)fromIndex - 1; pageIndex >= (NSInteger)toIndex; pageIndex--) {
			UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
			if(someController) {
				[self.pageIndexes setObject:@(pageIndex+1) forKey:@([someController hash])];
				
				if(shouldAdjustOffset || !animated || ![self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
					continue;
				}
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:pageIndex toIndex:pageIndex+1 viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	}
	
	// Update the scrollView's offset
	if(shouldAdjustOffset) {
		CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:(self.currentPage) inPageViewController:self];
		
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
			CGPoint offset = self.scrollView.contentOffset;
			offset.y += CGRectGetHeight(finalFrame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		} else {
			CGPoint offset = self.scrollView.contentOffset;
			offset.x += CGRectGetWidth(finalFrame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		}
	}
	
	if(!viewController) {
		// Force load the missing page
		viewController = [self.dataSource pageViewController:self viewControllerForPageAtIndex:toIndex];
		
		NSAssert(viewController, @"Trying to insert nil view controller");
		
		[self.loadedControllers addObject:viewController];
		[self.pageIndexes setObject:@(toIndex) forKey:@(viewController.hash)];
		
		[viewController willMoveToParentViewController:self];
		
		if(toIndex > self.currentPage) {
			[self.scrollView insertSubview:viewController.view atIndex:0];
		} else {
			[self.scrollView addSubview:viewController.view];
		}
		
		[viewController.view setFrame:[self.layouter finalFrameForPageAtIndex:fromIndex inPageViewController:self]];
		
		[self addChildViewController:viewController];
		[viewController didMoveToParentViewController:self];
	} else {
		[self.pageIndexes setObject:@(toIndex) forKey:@(viewController.hash)];
	}
	
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		dispatch_group_enter(animationsDispatchGroup);
		[self.layouter animatePageMoveFromIndex:fromIndex toIndex:toIndex viewController:viewController pageViewController:self completion:^{
			dispatch_group_leave(animationsDispatchGroup);
		}];
	}
	
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		[self updateBoundsUsingDefaultContraints];
		[self tilePages];
		
		if(completion) {
			completion();
		}
	});
}

@end
