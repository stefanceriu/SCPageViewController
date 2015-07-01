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


@interface SCPageViewControllerPageDetails : NSObject

@property (nonatomic, strong) UIViewController *viewController;

@property (nonatomic, assign) CGFloat visiblePercentage;

@property (nonatomic, assign) NSUInteger zPosition;

@end

@implementation SCPageViewControllerPageDetails

@end


@interface SCPageViewController () <SCPageViewControllerViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) SCScrollView *scrollView;

@property (nonatomic, assign) BOOL isAnimatingLayouterChange;
@property (nonatomic, strong) id<SCPageLayouterProtocol> layouter;
@property (nonatomic, strong) id<SCPageLayouterProtocol> previousLayouter;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) NSUInteger currentPage;

@property (nonatomic, strong) NSMutableArray *visibleControllers;

@property (nonatomic, assign) BOOL isContentOffsetBlocked;

@property (nonatomic, assign) BOOL isViewVisible;

@property (nonatomic, assign) BOOL isRotating;

@property (nonatomic, assign) UIEdgeInsets layouterContentInset;
@property (nonatomic, assign) CGFloat layouterInterItemSpacing;

@end

@implementation SCPageViewController
@dynamic contentOffset;
@dynamic bounces;
@dynamic touchRefusalArea;
@dynamic showsScrollIndicators;
@dynamic minimumNumberOfTouches;
@dynamic maximumNumberOfTouches;
@dynamic scrollEnabled;
@dynamic decelerationRate;

- (void)dealloc
{
	[self _unblockContentOffset];
}

- (instancetype)init
{
	if(self = [super init]) {
		[self _commonSetup];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self _commonSetup];
}

- (void)_commonSetup
{
	self.pages = [NSMutableArray array];
	self.visibleControllers = [NSMutableArray array];
	self.pagingEnabled = YES;
	
	self.easingFunction = [SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeSineEaseInOut];
	self.animationDuration = 0.25f;
	
	self.layouterContentInset = UIEdgeInsetsZero;
	self.layouterInterItemSpacing = 0.0f;
}

- (void)loadView
{
	self.view = [[SCPageViewControllerView alloc] init];
	[(SCPageViewControllerView *)self.view setDelegate:self];
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
	[super viewWillLayoutSubviews];
	
	[self setLayouter:self.layouter andFocusOnIndex:self.currentPage animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.isViewVisible = YES;
	[self _tilePages];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.isViewVisible = NO;
	[self _tilePages];
}

#pragma mark - Public Methods

- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
	andFocusOnIndex:(NSUInteger)pageIndex
		   animated:(BOOL)animated
		 completion:(void(^)())completion
{
	[self setLayouter:layouter animated:animated completion:^{
		if(completion) {
			completion();
		}
	}];
	
	if(animated) {
		[UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			[self navigateToPageAtIndex:pageIndex animated:NO completion:nil];
		} completion:nil];
	} else {
		[self navigateToPageAtIndex:pageIndex animated:animated completion:nil];
	}
}

- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
		   animated:(BOOL)animated
		 completion:(void (^)())completion
{
	self.previousLayouter = self.layouter;
	self.layouter = layouter;
	
	if(!self.isViewLoaded) {
		return; // Will attempt tiling on viewDidLoad
	}
	
	void(^updateLayout)() = ^{
		[self _blockContentOffset];
		[self _updateBoundsAndConstraints];
		[self _unblockContentOffset];
		
		[self _sortSubviewsByZPosition];
		[self _tilePages];
	};
	
	if(animated) {
		self.isAnimatingLayouterChange = YES;
		[UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			updateLayout();
		} completion:^(BOOL finished) {
			self.isAnimatingLayouterChange = NO;
			self.previousLayouter = nil;
			if(completion) {
				completion();
			}
		}];
	} else {
		updateLayout();
		if(completion) {
			completion();
		}
	}
}

- (void)reloadData
{
	[self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger pageIndex, BOOL *stop) {
		[self _removePageAtIndex:pageIndex];
	}];
	
	NSUInteger oldNumberOfPages = self.numberOfPages;
	self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
	
	[self.pages removeAllObjects];
	for(int i = 0; i < self.numberOfPages; i++) {
		[self.pages addObject:[NSNull null]];
	}
	[self.visibleControllers removeAllObjects];
	
	if(oldNumberOfPages >= self.numberOfPages) {
		NSUInteger index = MAX(0, (int)self.numberOfPages-1);
		[self navigateToPageAtIndex:index animated:NO completion:nil];
	} else {
		[self _updateBoundsAndConstraints];
		[self _tilePages];
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
		
		[self _updateNavigationContraints];
		
		if(!animated && [self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
			[self.delegate pageViewController:self didNavigateToPageAtIndex:pageIndex];
		}
		
		if(completion) {
			completion();
		}
	};
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
	
	if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
		CGFloat delta = (CGRectGetHeight(self.view.bounds) - CGRectGetHeight(frame)) / 2.0f;
		[self.scrollView setContentOffset:CGPointMake(0, CGRectGetMinY(frame) - delta)  easingFunction:self.easingFunction duration:(animated ? self.animationDuration : 0.0f) completion:animationFinishedBlock];
	} else {
		CGFloat delta = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(frame)) / 2.0f;
		[self.scrollView setContentOffset:CGPointMake(CGRectGetMinX(frame) - delta, 0)  easingFunction:self.easingFunction duration:(animated ? self.animationDuration : 0.0f) completion:animationFinishedBlock];
	}
}

- (NSArray *)loadedViewControllers
{
	NSMutableArray *array = [NSMutableArray array];
	for(SCPageViewControllerPageDetails *details in self.pages) {
		if(![details isEqual:[NSNull null]]) {
			if(details.viewController) {
				[array addObject:details.viewController];
			}
		}
	}
	
	return array;
}

- (NSArray *)visibleViewControllers
{
	return [self.visibleControllers copy];
}

- (CGFloat)visiblePercentageForViewController:(UIViewController *)viewController
{
	for(SCPageViewControllerPageDetails *pageDetails in self.pages) {
		if([pageDetails isEqual:[NSNull null]]) {
			continue;
		}
		
		if([pageDetails.viewController isEqual:viewController]) {
			return pageDetails.visiblePercentage;
		}
	}
	
	return 0.0f;
}

- (UIViewController *)viewControllerForPageAtIndex:(NSUInteger)pageIndex
{
	if(pageIndex >= self.pages.count) {
		return nil;
	}
	
	SCPageViewControllerPageDetails *pageDetails = [self.pages objectAtIndex:pageIndex];
	
	if([pageDetails isEqual:[NSNull null]]) {
		return nil;
	}
	
	return pageDetails.viewController;
}

- (NSUInteger)pageIndexForViewController:(UIViewController *)viewController
{
	NSUInteger pageIndex = NSNotFound;
	
	for(SCPageViewControllerPageDetails *details in self.pages) {
		if([details isEqual:[NSNull null]]) {
			continue;
		}
		
		if([details.viewController isEqual:viewController]) {
			return [self.pages indexOfObject:details];
		}
	}
	
	return pageIndex;
}

#pragma mark - Navigational Constraints

- (void)_updateBoundsAndConstraints
{
	if([self.layouter respondsToSelector:@selector(contentInsetForPageViewController:)]) {
		self.layouterContentInset = [self.layouter contentInsetForPageViewController:self];
	} else {
		self.layouterContentInset = UIEdgeInsetsZero;
	}
	
	if([self.layouter respondsToSelector:@selector(interItemSpacingForPageViewController:)]) {
		self.layouterInterItemSpacing = roundf([self.layouter interItemSpacingForPageViewController:self]);
	} else {
		self.layouterInterItemSpacing = 0.0f;
	}
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:self.numberOfPages - 1 pageViewController:self];
	if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
		[self.scrollView setContentInset:UIEdgeInsetsMake(self.layouterContentInset.top, 0.0f, self.layouterContentInset.bottom, 0.0f)];
		[self.scrollView setContentSize:CGSizeMake(0, roundf(CGRectGetMaxY(frame)))];
	} else {
		[self.scrollView setContentInset:UIEdgeInsetsMake(0.0f, self.layouterContentInset.left, 0.0f, self.layouterContentInset.right)];
		[self.scrollView setContentSize:CGSizeMake(roundf(CGRectGetMaxX(frame)), 0.0f)];
	}
	
	[self _updateNavigationContraints];
}

- (void)_updateNavigationContraints
{
	if(self.continuousNavigationEnabled) {
		return;
	}
	
	UIEdgeInsets insets = UIEdgeInsetsZero;
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage == 0 ? 0 : self.currentPage - 1)  pageViewController:self];
	switch (self.layouter.navigationType) {
		case SCPageLayouterNavigationTypeVertical:
			frame.origin.x = 0.0f;
			frame.origin.y -= self.layouterContentInset.top;
			break;
		case SCPageLayouterNavigationTypeHorizontal:
			frame.origin.y = 0.0f;
			frame.origin.x -= self.layouterContentInset.left;
			break;
		default:
			break;
	}
	
	if(self.layouter.navigationConstraintType & SCPageLayouterNavigationContraintTypeReverse) {
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical: {
				insets.top = -[self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)].y;
				break;
			}
			case SCPageLayouterNavigationTypeHorizontal: {
				insets.left = -[self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)].x;
				break;
			}
		}
	}
	
	frame = [self.layouter finalFrameForPageAtIndex:MIN(self.currentPage + 1, self.numberOfPages - 1) pageViewController:self];
	switch (self.layouter.navigationType) {
		case SCPageLayouterNavigationTypeVertical:
			frame.origin.x = 0.0f;
			frame.origin.y += self.layouterContentInset.top;
			break;
		case SCPageLayouterNavigationTypeHorizontal:
			frame.origin.y = 0.0f;
			frame.origin.x += self.layouterContentInset.left;
			break;
		default:
			break;
	}
	
	if(self.layouter.navigationConstraintType & SCPageLayouterNavigationContraintTypeForward) {
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical: {
				insets.bottom = -(self.scrollView.contentSize.height - ABS([self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, 1.0f)].y));
				break;
			}
			case SCPageLayouterNavigationTypeHorizontal: {
				insets.right = -(self.scrollView.contentSize.width - ABS([self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(1.0f, 0.0f)].x));
				break;
			}
		}
	}
	
	[self.scrollView setContentInset:insets];
}

#pragma mark - Page Management

- (void)_tilePages
{
	if(self.numberOfPages == 0) {
		return;
	}
	
	self.currentPage = [self _calculateCurrentPage];
	
	NSInteger firstNeededPageIndex = self.currentPage - [self.layouter numberOfPagesToPreloadBeforeCurrentPage];
	firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
	
	
	NSInteger lastNeededPageIndex  = self.currentPage + [self.layouter numberOfPagesToPreloadAfterCurrentPage];
	lastNeededPageIndex  = MIN(lastNeededPageIndex, ((NSInteger)self.numberOfPages - 1));
	
	NSMutableSet *removedIndexes = [NSMutableSet set];
	
	[self.pages enumerateObjectsUsingBlock:^(SCPageViewControllerPageDetails *pageDetails, NSUInteger pageIndex, BOOL *stop) {
		
		if([pageDetails isEqual:[NSNull null]]) {
			return;
		}
		
		if (pageIndex < firstNeededPageIndex || pageIndex > lastNeededPageIndex) {
			[removedIndexes addObject:@(pageIndex)];
			[self _removePageAtIndex:pageIndex];
		}
	}];
	
	for(NSNumber *removedIndex in removedIndexes) {
		[self.pages replaceObjectAtIndex:removedIndex.unsignedIntegerValue withObject:[NSNull null]];
	}
	
	for (NSUInteger pageIndex = firstNeededPageIndex; pageIndex <= lastNeededPageIndex; pageIndex++) {
		
		UIViewController *page = [self viewControllerForPageAtIndex:pageIndex];
		if (!page) {
			[UIView performWithoutAnimation:^{
				[self _createAndInsertNewPageAtIndex:pageIndex];
			}];
		}
	}
	
	[self _updateFramesAndTriggerAppearanceCallbacks];
}

#pragma mark Appearance callbacks and framesetting

- (void)_updateFramesAndTriggerAppearanceCallbacks
{
	NSArray *filteredPages = [self.pages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", [NSNull null]]];
	
	if(filteredPages.count == 0) {
		return;
	}
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"viewController.view" ascending:NO comparator:^NSComparisonResult(id obj1, id obj2) {
		return [@([self.scrollView.subviews indexOfObject:obj1]) compare:@([self.scrollView.subviews indexOfObject:obj2])];
	}];
	
	NSArray *sortedPages = [filteredPages sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	BOOL isReversed = (![filteredPages isEqual:sortedPages]);
	
	__block CGRect remainder = self.scrollView.bounds;
	if(remainder.origin.x < 0.0f || remainder.origin.y < 0.0f) {
		remainder.size.width += remainder.origin.x;
		remainder.size.height += remainder.origin.y;
		remainder.origin.x = 0.0f;
		remainder.origin.y = 0.0f;
	}
	
	CGRectEdge edge = -1;
	SCPageViewControllerPageDetails *firstPage = [sortedPages firstObject];
	switch (self.layouter.navigationType) {
		case SCPageLayouterNavigationTypeVertical: {
			if(isReversed) {
				edge = CGRectMaxYEdge;
				
				CGFloat remainderDelta = CGRectGetMaxY(remainder) - CGRectGetMaxY(firstPage.viewController.view.frame);
				if(remainderDelta > 0) {
					remainder.size.height -= remainderDelta;
				}
				
			} else {
				edge = CGRectMinYEdge;
			}
			
			break;
		}
		case SCPageLayouterNavigationTypeHorizontal: {
			if(isReversed) {
				edge = CGRectMaxXEdge;
				
				CGFloat remainderDelta = CGRectGetMaxX(remainder) - CGRectGetMaxX(firstPage.viewController.view.frame);
				if(remainderDelta > 0) {
					remainder.size.height -= remainderDelta;
				}
				
			} else {
				edge = CGRectMinXEdge;
			}
			
			break;
		}
	}
	
	[sortedPages enumerateObjectsUsingBlock:^(SCPageViewControllerPageDetails *details, NSUInteger idx, BOOL *stop) {
		
		UIViewController *viewController = details.viewController;
		
		if(!viewController) {
			return;
		}
		
		NSUInteger pageIndex = [self.pages indexOfObject:details];
		
		CGRect finalFrame = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
		CGRect nextFrame = finalFrame;
		if([self.layouter respondsToSelector:@selector(currentFrameForPageAtIndex:contentOffset:finalFrame:pageViewController:)]) {
			nextFrame = [self.layouter currentFrameForPageAtIndex:pageIndex
													contentOffset:self.scrollView.contentOffset
													   finalFrame:finalFrame
											   pageViewController:self];
		}
		
		CGRect intersection = CGRectIntersection(remainder, nextFrame);
		// If a view controller's frame does intersect the remainder then it's visible
		BOOL visible = self.layouter.navigationType == SCPageLayouterNavigationTypeVertical ? (CGRectGetHeight(intersection) > 0.0f) : (CGRectGetWidth(intersection) > 0.0f);
		visible = visible && self.isViewVisible;
		
		if(visible) {
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				[details setVisiblePercentage:roundf((CGRectGetHeight(intersection) * 1000) / CGRectGetHeight(nextFrame)) / 1000.0f];
			} else {
				[details setVisiblePercentage:roundf((CGRectGetWidth(intersection) * 1000) / CGRectGetWidth(nextFrame)) / 1000.0f];
			}
		}
		
		remainder = [self _subtractRect:intersection fromRect:remainder withEdge:edge];
		
		[self _setAnimatableSublayerTransform:CATransform3DIdentity forViewController:viewController];
		
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
		
		CATransform3D transform = CATransform3DIdentity;
		if([self.layouter respondsToSelector:@selector(sublayerTransformForPageAtIndex:contentOffset:pageViewController:)]) {
			transform = [self.layouter sublayerTransformForPageAtIndex:pageIndex
														 contentOffset:self.scrollView.contentOffset
													pageViewController:self];
		}
		
		[self _setAnimatableSublayerTransform:transform forViewController:viewController];
	}];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
	return NO;
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
		[self _tilePages];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(decelerate == NO) {
		
		if(self.shouldLayoutPagesOnRest) {
			[self _tilePages];
		}
		
		[self _updateNavigationContraints];
		
		if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
			[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if(self.shouldLayoutPagesOnRest) {
		[self _tilePages];
	}
	
	[self _updateNavigationContraints];
	
	if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
		[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	if(self.shouldLayoutPagesOnRest) {
		[self _tilePages];
	}
	
	[self _updateNavigationContraints];
	
	if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
		[self.delegate pageViewController:self didNavigateToPageAtIndex:self.currentPage];
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	// Bouncing target content offset when fix.
	// When trying to adjust content offset while bouncing the velocity drops down to almost nothing.
	// Seems to be an internal UIScrollView issue
	if(self.scrollView.contentOffset.y < -self.layouterContentInset.top) {
		targetContentOffset->y = -self.layouterContentInset.top;
	} else if(self.scrollView.contentOffset.x < -self.layouterContentInset.left) {
		targetContentOffset->x = -self.layouterContentInset.left;
	} else if(self.scrollView.contentOffset.y > ABS((self.scrollView.contentSize.height + self.layouterContentInset.bottom) - CGRectGetHeight(self.scrollView.bounds))) {
		targetContentOffset->y = (self.scrollView.contentSize.height + self.layouterContentInset.bottom) - CGRectGetHeight(self.scrollView.bounds);
	} else if(self.scrollView.contentOffset.x > ABS((self.scrollView.contentSize.width + self.layouterContentInset.right) - CGRectGetWidth(self.scrollView.bounds))) {
		targetContentOffset->x = (self.scrollView.contentSize.width + self.layouterContentInset.right) - CGRectGetWidth(self.scrollView.bounds);
	}
	// Normal pagination
	else {
		[self _adjustTargetContentOffset:targetContentOffset withVelocity:velocity];
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

#pragma mark - Private - Content Offset Blocking

static NSUInteger oldCurrentPage;
- (void)_blockContentOffset
{
	if(!self.isContentOffsetBlocked) {
		self.isContentOffsetBlocked = YES;
		[self.scrollView setDelegate:nil];
		oldCurrentPage = self.currentPage;
		[self.scrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(self.isContentOffsetBlocked) {
		
		CGRect frame = CGRectIntegral([self.layouter finalFrameForPageAtIndex:oldCurrentPage pageViewController:self]);
		
		CGPoint offset;
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
			offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)];
			offset.x -= self.layouterContentInset.left;
		} else {
			offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)];
			offset.y -= self.layouterContentInset.top;
		}
		
		if((NSInteger)floor(offset.x) != (NSInteger)floor(self.scrollView.contentOffset.x) ||
		   (NSInteger)floor(offset.y) != (NSInteger)floor(self.scrollView.contentOffset.y)) {
			[self.scrollView setContentOffset:offset];
		}
	}
}

- (void)_unblockContentOffset
{
	if(self.isContentOffsetBlocked) {
		[self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
		self.isContentOffsetBlocked = NO;
		[self.scrollView setDelegate:self];
	}
}

#pragma mark Private - Pagination

- (NSUInteger)_calculateCurrentPage
{
	NSMutableArray *pages = [self.pages mutableCopy];
	
	for(NSUInteger i = 0; i < pages.count; i++) {
		SCPageViewControllerPageDetails *details = pages[i];
		
		if([details isEqual:[NSNull null]]) {
			SCPageViewControllerPageDetails *newDetails = [[SCPageViewControllerPageDetails alloc] init];
			NSUInteger zPosition = pages.count - i - 1;
			if([self.layouter respondsToSelector:@selector(zPositionForPageAtIndex:pageViewController:)]) {
				zPosition = [self.layouter zPositionForPageAtIndex:i
												pageViewController:self];
			}
			
			[newDetails setZPosition:zPosition];
			[pages replaceObjectAtIndex:i withObject:newDetails];
		}
	}
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"zPosition" ascending:NO];
	NSArray *sortedPages = [pages sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	for(NSUInteger i = 0; i < sortedPages.count; i++) {
		
		NSUInteger pageIndex = [pages indexOfObject:sortedPages[i]];
		
		CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
		CGPoint centerOffset = [self.view convertPoint:self.view.center toView:self.scrollView];
		
		if(CGRectContainsPoint(frame, centerOffset)) {
			return pageIndex;
		}
	}
	
	return self.currentPage;
}

- (CGPoint)_nextStepOffsetForFrame:(CGRect)finalFrame withVelocity:(CGPoint)velocity
{
	CGPoint nextStepOffset = CGPointZero;
	if(velocity.y > 0.0f) {
		nextStepOffset.y = (NSInteger)CGRectGetMaxY(finalFrame);
	} else if(velocity.x > 0.0f) {
		nextStepOffset.x = (NSInteger)CGRectGetMaxX(finalFrame);
	} else if(velocity.y < 0.0f) {
		nextStepOffset.y = (NSInteger)CGRectGetMinY(finalFrame);
	} else if(velocity.x < 0.0f) {
		nextStepOffset.x = (NSInteger)CGRectGetMinX(finalFrame);
	}
	
	return nextStepOffset;
}

- (void)_adjustTargetContentOffset:(inout CGPoint *)targetContentOffset withVelocity:(CGPoint)velocity
{
	if(!self.pagingEnabled && self.continuousNavigationEnabled) {
		return;
	}
	
	// Enumerate through all the pages and figure out which one contains the targeted offset
	for(NSUInteger pageIndex = 0; pageIndex < self.numberOfPages; pageIndex ++) {
		
		CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
		
		switch (self.layouter.navigationType) {
			case SCPageLayouterNavigationTypeVertical:
				frame.origin.x = 0.0f;
				frame.origin.y -= self.layouterContentInset.top;
				break;
			case SCPageLayouterNavigationTypeHorizontal:
				frame.origin.y = 0.0f;
				frame.origin.x -= self.layouterContentInset.left;
				break;
			default:
				break;
		}
		
		if(CGRectContainsPoint(frame, *targetContentOffset)) {
			
			// If the velocity is zero then jump to the closest navigation step
			if(CGPointEqualToPoint(CGPointZero, velocity)) {
				
				switch (self.layouter.navigationType) {
					case SCPageLayouterNavigationTypeVertical:
					{
						CGPoint previousStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)];
						CGPoint nextStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, 1.0f)];
						
						*targetContentOffset = ABS(targetContentOffset->y - previousStepOffset.y) > ABS(targetContentOffset->y - nextStepOffset.y) ? nextStepOffset : previousStepOffset;
						break;
					}
					case SCPageLayouterNavigationTypeHorizontal:
					{
						CGPoint previousStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)];
						CGPoint nextStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(1.0f, 0.0f)];
						
						*targetContentOffset = ABS(targetContentOffset->x - previousStepOffset.x) > ABS(targetContentOffset->x - nextStepOffset.x) ? nextStepOffset : previousStepOffset;
						break;
					}
				}
				
			} else {
				// Calculate the next step of the pagination (either a navigationStep or a controller edge)
				*targetContentOffset = [self _nextStepOffsetForFrame:frame withVelocity:velocity];
			}
			
			break;
		}
	}
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

- (void)_setAnimatableSublayerTransform:(CATransform3D)transform forViewController:(UIViewController *)viewController
{
	for(CALayer *layer in viewController.view.layer.sublayers) {
		[layer setTransform:transform];
	}
}

- (void)_sortSubviewsByZPosition
{
	NSArray *filteredPages = [self.pages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", [NSNull null]]];
	
	[filteredPages enumerateObjectsUsingBlock:^(SCPageViewControllerPageDetails *pageDetails, NSUInteger pageIndex, BOOL *stop) {
		NSUInteger zPosition = self.numberOfPages - [self.pages indexOfObject:pageDetails] - 1;
		if([self.layouter respondsToSelector:@selector(zPositionForPageAtIndex:pageViewController:)]) {
			zPosition = [self.layouter zPositionForPageAtIndex:[self.pages indexOfObject:pageDetails]
											pageViewController:self];
		}
		
		NSAssert(zPosition < (NSInteger)self.numberOfPages, @"Invalid zPosition for page at index %lu", (unsigned long)pageIndex);
		[pageDetails setZPosition:zPosition];
	}];
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"zPosition" ascending:NO];
	NSMutableArray *sortedViews = [[[filteredPages sortedArrayUsingDescriptors:@[sortDescriptor]] valueForKeyPath:@"@unionOfObjects.viewController.view"] mutableCopy];
	
	if(sortedViews.count != self.scrollView.subviews.count) {
		// Keep no longer tracked views (pages being deleted for example) in the same hierarchical position
		for(UIView *view in self.scrollView.subviews) {
			if([sortedViews containsObject:view]) {
				continue;
			}
			
			NSUInteger index = [self.scrollView.subviews indexOfObject:view];
			if(index == 0) {
				[sortedViews addObject:view];
			} else {
				UIView *viewBelow = self.scrollView.subviews[index - 1];
				[sortedViews insertObject:view atIndex:[sortedViews indexOfObject:viewBelow]];
			}
		}
	}
	
	[sortedViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
		[self.scrollView sendSubviewToBack:view];
	}];
}

- (UIViewController *)_createAndInsertNewPageAtIndex:(NSUInteger)pageIndex
{
	SCPageViewControllerPageDetails *pageDetails = [self.pages objectAtIndex:pageIndex];
	if(![pageDetails isEqual:[NSNull null]] && pageDetails.viewController) {
		return pageDetails.viewController;
	}
	
	UIViewController *page = [self.dataSource pageViewController:self viewControllerForPageAtIndex:pageIndex];
	
	NSAssert(page, @"Trying to insert nil view controller");
	
	SCPageViewControllerPageDetails *details = [[SCPageViewControllerPageDetails alloc] init];
	[details setViewController:page];
	[self.pages replaceObjectAtIndex:pageIndex withObject:details];
	
	[self addChildViewController:page];
	
	[page.view setAutoresizingMask:UIViewAutoresizingNone];
	if(self.isAnimatingLayouterChange) {
		[page.view setFrame:[self.previousLayouter finalFrameForPageAtIndex:pageIndex pageViewController:self]];
	} else {
		[page.view setFrame:[self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self]];
	}
	[self.scrollView addSubview:page.view];
	
	[self _sortSubviewsByZPosition];
	
	[page didMoveToParentViewController:self];
	
	return page;
}

- (void)_removePageAtIndex:(NSUInteger)pageIndex
{
	SCPageViewControllerPageDetails *pageDetails = [self.pages objectAtIndex:pageIndex];
	if([pageDetails isEqual:[NSNull null]]) {
		return;
	}
	
	UIViewController *viewController = pageDetails.viewController;
	if(!viewController) {
		return;
	}
	
	if([self.visibleControllers containsObject:viewController]) {
		[viewController beginAppearanceTransition:NO animated:NO];
	}
	
	[viewController willMoveToParentViewController:nil];
	[viewController.view removeFromSuperview];
	[self _setAnimatableSublayerTransform:CATransform3DIdentity forViewController:viewController];
	[viewController removeFromParentViewController];
	
	if([self.visibleControllers containsObject:viewController]) {
		[viewController endAppearanceTransition];
	}
	
	[self.visibleControllers removeObject:viewController];
}

#pragma mark - Private - Incremental Updates

- (void)_reloadPageAtIndex:(NSUInteger)pageIndex animated:(BOOL)animated completion:(void(^)())completion
{
	UIViewController *oldViewController = [self viewControllerForPageAtIndex:pageIndex];
	[oldViewController willMoveToParentViewController:nil];
	if([self.visibleViewControllers containsObject:oldViewController]) {
		[oldViewController beginAppearanceTransition:NO animated:animated];
	}
	
	UIViewController *newViewController = [self _createAndInsertNewPageAtIndex:pageIndex];
	
	if([self.layouter respondsToSelector:@selector(animatePageReloadAtIndex:oldViewController:newViewController:pageViewController:completion:)] && animated) {
		[self.layouter animatePageReloadAtIndex:pageIndex oldViewController:oldViewController newViewController:newViewController pageViewController:self completion:^{
			
			[oldViewController.view removeFromSuperview];
			if([self.visibleViewControllers containsObject:oldViewController]) {
				[oldViewController endAppearanceTransition];
			}
			
			[oldViewController removeFromParentViewController];
			
			[self.pages removeObjectAtIndex:pageIndex];
			[self.visibleControllers removeObject:oldViewController];
			
			[self _updateBoundsAndConstraints];
			[self _tilePages];
		}];
	}
}

- (void)_insertPageAtIndex:(NSInteger)insertionIndex animated:(BOOL)animated completion:(void(^)())completion
{
	NSAssert(insertionIndex <= self.numberOfPages, @"Index out of bounds");
	
	NSInteger oldNumberOfPages = self.numberOfPages;
	self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
	
	NSAssert((self.numberOfPages == oldNumberOfPages + 1), @"The number of pages after insertion is equal to the one before");
	
	[self.pages insertObject:[NSNull null] atIndex:insertionIndex];
	
	dispatch_group_t animationsDispatchGroup = dispatch_group_create();
	
	// Animate page movements
	BOOL shouldAdjustOffset = (insertionIndex < self.currentPage);
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		if(shouldAdjustOffset) {
			for(NSInteger pageIndex = (insertionIndex - 1); pageIndex >= 0; pageIndex--) {
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				
				CGRect frameForAnimation = [self.layouter finalFrameForPageAtIndex:(pageIndex + 1) pageViewController:self];
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
	
	// Insert the new page
	UIViewController *viewController = [self _createAndInsertNewPageAtIndex:insertionIndex];
	
	if(animated && [self.layouter respondsToSelector:@selector(animatePageInsertionAtIndex:viewController:pageViewController:completion:)]) {
		dispatch_group_enter(animationsDispatchGroup);
		[self.layouter animatePageInsertionAtIndex:insertionIndex viewController:viewController pageViewController:self completion:^{
			dispatch_group_leave(animationsDispatchGroup);
		}];
	}
	
	// Update the content offset and pages layout
	void (^updateLayout)() = ^{
		
		self.scrollView.delegate = nil;
		
		if(shouldAdjustOffset) {
			CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage + 1) pageViewController:self];
			
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				CGPoint offset = self.scrollView.contentOffset;
				offset.y += CGRectGetHeight(frame) + self.layouterInterItemSpacing;
				[self.scrollView setContentOffset:offset];
			} else {
				CGPoint offset = self.scrollView.contentOffset;
				offset.x += CGRectGetWidth(frame) + self.layouterInterItemSpacing;
				[self.scrollView setContentOffset:offset];
			}
		}
		
		[self _updateBoundsAndConstraints];
		[self _tilePages];
		
		self.scrollView.delegate = self;
	};
	
	if(animated) {
		dispatch_group_enter(animationsDispatchGroup);
		[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			updateLayout();
		} completion:^(BOOL finished) {
			dispatch_group_leave(animationsDispatchGroup);
		}];
	} else {
		updateLayout();
	}
	
	// Clean up everything and notify of completion
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		if(completion) {
			completion();
		}
	});
}

- (void)_deletePageAtIndex:(NSInteger)deletionIndex animated:(BOOL)animated completion:(void(^)())completion
{
	NSAssert(deletionIndex < self.numberOfPages, @"Index out of bounds");
	
	NSInteger oldNumberOfPages = self.numberOfPages;
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
	BOOL shouldAdjustOffset = (deletionIndex < self.currentPage);
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		if(shouldAdjustOffset) {
			for(NSInteger pageIndex = (deletionIndex - 1); pageIndex >= 0; pageIndex--) {
				
				UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
				
				CGRect frameForAnimation = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
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
	[self.pages removeObjectAtIndex:deletionIndex];
	
	// Update the content offset and pages layout
	void (^updateLayout)() = ^{
		
		self.scrollView.delegate = nil;
		
		if(shouldAdjustOffset) {
			
			CGRect frame = [self.layouter finalFrameForPageAtIndex:self.currentPage pageViewController:self];
			
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				CGPoint offset = self.scrollView.contentOffset;
				offset.y -= CGRectGetHeight(frame) + self.layouterInterItemSpacing;
				[self.scrollView setContentOffset:offset];
			} else {
				CGPoint offset = self.scrollView.contentOffset;
				offset.x -= CGRectGetWidth(frame) + self.layouterInterItemSpacing;
				[self.scrollView setContentOffset:offset];
			}
		}
		
		[self _updateBoundsAndConstraints];
		[self _tilePages];
		
		self.scrollView.delegate = self;
	};
	
	if(animated) {
		dispatch_group_enter(animationsDispatchGroup);
		[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			updateLayout();
		} completion:^(BOOL finished) {
			dispatch_group_leave(animationsDispatchGroup);
		}];
	} else {
		updateLayout();
	}
	
	// Cleanup and notify of completion
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		
		[viewController.view removeFromSuperview];
		if([self.visibleViewControllers containsObject:viewController]) {
			[viewController endAppearanceTransition];
		}
		
		[viewController removeFromParentViewController];
		[self.visibleControllers removeObject:viewController];
		
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
	
	SCPageViewControllerPageDetails *pageDetails = [self.pages objectAtIndex:fromIndex];
	[self.pages removeObjectAtIndex:fromIndex];
	[self.pages insertObject:pageDetails atIndex:toIndex];
	
	if(fromIndex < toIndex) {
		for(NSUInteger pageIndex = fromIndex; pageIndex < toIndex; pageIndex++) {
			UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
			if(someController) {
				if(shouldAdjustOffset || !animated || ![self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
					continue;
				}
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:(pageIndex + 1) toIndex:pageIndex viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	} else {
		for(NSInteger pageIndex = fromIndex; pageIndex > toIndex; pageIndex--) {
			UIViewController *someController = [self viewControllerForPageAtIndex:pageIndex];
			if(someController) {
				if(shouldAdjustOffset || !animated || ![self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
					continue;
				}
				
				dispatch_group_enter(animationsDispatchGroup);
				[self.layouter animatePageMoveFromIndex:(pageIndex + 1) toIndex:pageIndex viewController:someController pageViewController:self completion:^{
					dispatch_group_leave(animationsDispatchGroup);
				}];
			}
		}
	}
	
	// Update the scrollView's offset
	if(shouldAdjustOffset) {
		CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage) pageViewController:self];
		
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
			CGPoint offset = self.scrollView.contentOffset;
			offset.y += CGRectGetHeight(frame) + self.layouterInterItemSpacing;
			[self.scrollView setContentOffset:offset];
		} else {
			CGPoint offset = self.scrollView.contentOffset;
			offset.x += CGRectGetWidth(frame) + self.layouterInterItemSpacing;
			[self.scrollView setContentOffset:offset];
		}
	}
	
	if(!viewController) {
		// Force load the missing page
		viewController = [self _createAndInsertNewPageAtIndex:toIndex];
	}
	
	if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
		dispatch_group_enter(animationsDispatchGroup);
		[self.layouter animatePageMoveFromIndex:fromIndex toIndex:toIndex viewController:viewController pageViewController:self completion:^{
			dispatch_group_leave(animationsDispatchGroup);
		}];
	}
	
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		[self _updateBoundsAndConstraints];
		[self _tilePages];
		
		if(completion) {
			completion();
		}
	});
}

@end
