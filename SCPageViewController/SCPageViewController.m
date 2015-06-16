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

@end

@implementation SCPageViewControllerPageDetails

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %d %@ %f", NSStringFromClass([self class]), [self hash], self.viewController, self.visiblePercentage];
}

@end

@interface SCPageViewController () <SCPageViewControllerViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) SCScrollView *scrollView;

@property (nonatomic, strong) id<SCPageLayouterProtocol> layouter;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) NSUInteger currentPage;

@property (nonatomic, strong) NSMutableArray *visibleControllers;

@property (nonatomic, assign) BOOL isContentOffsetBlocked;

@property (nonatomic, assign) BOOL isViewVisible;

@property (nonatomic, assign) BOOL isRotating;

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
	self.pages = [NSMutableArray array];
	self.visibleControllers = [NSMutableArray array];
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
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:self.currentPage inPageViewController:self];
	
	CGPoint offset;
	if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
		offset = [self nextStepOffsetForFrame:frame velocity:CGPointMake(-1.0f, 0.0f)];
		[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-1.0f, 0.0f)];
	} else {
		offset = [self nextStepOffsetForFrame:frame velocity:CGPointMake(0.0f, -1.0f)];
		[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-.0f, -1.0f)];
	}
	
	[UIView animateWithDuration:(animated ? self.animationDuration : 0.0f) animations:^{
		[self blockContentOffset];
		[self updateBoundsUsingDefaultContraints];
		[self unblockContentOffset];
		[self.scrollView setContentOffset:offset];
	} completion:^(BOOL finished) {
		if(completion) {
			completion();
		}
	}];
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
	
	CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self];
	
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
			[self _createAndInsertNewPageAtIndex:pageIndex];
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
	
	[self.pages enumerateObjectsUsingBlock:^(SCPageViewControllerPageDetails *details, NSUInteger pageIndex, BOOL *stop) {
		
		if([details isEqual:[NSNull null]]) {
			return;
		}
		
		UIViewController *viewController = details.viewController;
		
		if(!viewController) {
			return;
		}
		
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
				[details setVisiblePercentage:roundf((CGRectGetHeight(intersection) * 1000) / CGRectGetHeight(nextFrame)) / 1000.0f];
			} else {
				[details setVisiblePercentage:roundf((CGRectGetWidth(intersection) * 1000) / CGRectGetWidth(nextFrame)) / 1000.0f];
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
		
		if([self.layouter respondsToSelector:@selector(sublayerTransformForViewController:withIndex:contentOffset:finalFrame:inPageViewController:)]) {
			CATransform3D transform = [self.layouter sublayerTransformForViewController:viewController
																			  withIndex:pageIndex
																		  contentOffset:self.scrollView.contentOffset
																			 finalFrame:[self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self]
																   inPageViewController:self];
			[viewController.view.layer setSublayerTransform:transform];
		} else {
			[viewController.view.layer setSublayerTransform:CATransform3DIdentity];
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
	self.isRotating = YES;
	[self blockContentOffset];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	self.isRotating = NO;
	[self unblockContentOffset];
	[self updateBoundsUsingDefaultContraints];
}

#pragma mark - Content Offset Blocking

- (void)blockContentOffset
{
	if(!self.isContentOffsetBlocked) {
		self.isContentOffsetBlocked = YES;
		[self.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(self.isContentOffsetBlocked) {
		
		CGRect frame = [self.layouter finalFrameForPageAtIndex:self.currentPage inPageViewController:self];
		
		CGPoint offset;
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
			offset = [self nextStepOffsetForFrame:frame velocity:CGPointMake(-1.0f, 0.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-1.0f, 0.0f)];
		} else {
			offset = [self nextStepOffsetForFrame:frame velocity:CGPointMake(0.0f, -1.0f)];
			[self adjustTargetContentOffset:&offset withVelocity:CGPointMake(-.0f, -1.0f)];
		}
		
		if(!CGPointEqualToPoint(offset, self.scrollView.contentOffset)) {
			[self.scrollView setContentOffset:offset];
		}
	}
}

- (void)unblockContentOffset
{
	if(self.isContentOffsetBlocked) {
		[self.scrollView setContentOffset:self.scrollView.contentOffset animated:YES];
		[self.scrollView removeObserver:self forKeyPath:@"contentSize"];
		self.isContentOffsetBlocked = NO;
		[self updateBoundsUsingDefaultContraints];
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
	
	NSUInteger zPosition = pageIndex;
	if([self.layouter respondsToSelector:@selector(zPositionForViewController:withIndex:numberOfPages:inPageViewController:)]) {
		zPosition = [self.layouter zPositionForViewController:page
													withIndex:pageIndex
												numberOfPages:self.numberOfPages
										 inPageViewController:self];
	}
	
	NSAssert(zPosition < (NSInteger)self.numberOfPages, @"Invalid zPosition for page at index %d", pageIndex);
	
	NSLog(@"Inserting at page at index %d at position %d", pageIndex, zPosition);
	
	if(zPosition == 0) {
		[self.scrollView insertSubview:page.view atIndex:0];
	} else if(zPosition == self.numberOfPages - 1) {
		[self.scrollView addSubview:page.view];
	} else if([[self.pages objectAtIndex:pageIndex - 1] isEqual:[NSNull null]]) {
		[self.scrollView addSubview:page.view];
	} else if([[self.pages objectAtIndex:pageIndex + 1] isEqual:[NSNull null]]) {
		[self.scrollView insertSubview:page.view atIndex:0];
	} else {
		[self.scrollView insertSubview:page.view atIndex:zPosition];
	}
	
	[self addChildViewController:page];
	[page didMoveToParentViewController:self];
	
	[page.view setFrame:[self.layouter finalFrameForPageAtIndex:pageIndex inPageViewController:self]];
	
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
	[viewController removeFromParentViewController];
	
	if([self.visibleControllers containsObject:viewController]) {
		[viewController endAppearanceTransition];
	}
}

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
	
	[self.pages insertObject:[NSNull null] atIndex:insertionIndex];
	
	dispatch_group_t animationsDispatchGroup = dispatch_group_create();
	
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
		CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage + 1) inPageViewController:self];
		
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
			CGPoint offset = self.scrollView.contentOffset;
			offset.y += CGRectGetHeight(frame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		} else {
			CGPoint offset = self.scrollView.contentOffset;
			offset.x += CGRectGetWidth(frame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
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
	[self.pages removeObjectAtIndex:deletionIndex];
	
	dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
		
		// Update the scrollView's offset
		if(shouldAdjustOffset) {
			CGRect frame = [self.layouter finalFrameForPageAtIndex:self.currentPage inPageViewController:self];
			
			if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
				CGPoint offset = self.scrollView.contentOffset;
				offset.y -= CGRectGetHeight(frame) + self.layouter.interItemSpacing;
				[self.scrollView setContentOffset:offset];
			} else {
				CGPoint offset = self.scrollView.contentOffset;
				offset.x -= CGRectGetWidth(frame) + self.layouter.interItemSpacing;
				[self.scrollView setContentOffset:offset];
			}
		}
		
		[viewController.view removeFromSuperview];
		if([self.visibleViewControllers containsObject:viewController]) {
			[viewController endAppearanceTransition];
		}
		
		[viewController removeFromParentViewController];
		
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
		CGRect frame = [self.layouter finalFrameForPageAtIndex:(self.currentPage) inPageViewController:self];
		
		if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
			CGPoint offset = self.scrollView.contentOffset;
			offset.y += CGRectGetHeight(frame) + self.layouter.interItemSpacing;
			[self.scrollView setContentOffset:offset];
		} else {
			CGPoint offset = self.scrollView.contentOffset;
			offset.x += CGRectGetWidth(frame) + self.layouter.interItemSpacing;
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
		[self updateBoundsUsingDefaultContraints];
		[self tilePages];
		
		if(completion) {
			completion();
		}
	});
}

@end
