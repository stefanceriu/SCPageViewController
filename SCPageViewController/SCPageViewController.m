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

@property (nonatomic, assign) NSUInteger blockedPageIndex;

@property (nonatomic, strong) NSIndexSet *insertionIndexes;

@property (nonatomic, strong) NSNumber *initialPageIndex;

@end

@implementation SCPageViewController

- (void)dealloc
{
    if(self.isContentOffsetBlocked) {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    
    [self.scrollView setDelegate:nil];
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
    
    self.scrollView = [[SCScrollView alloc] init];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.delegate = self;
    self.scrollView.clipsToBounds = NO;
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
    
    [self.scrollView setFrame:self.view.bounds];
    
    // Prevents _adjustContentOffsetIfNecessary from triggering
    UIView *scrollViewWrapper = [[UIView alloc] initWithFrame:self.view.bounds];
    [scrollViewWrapper setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [scrollViewWrapper addSubview:self.scrollView];
    
    [self.view addSubview:scrollViewWrapper];
    
    [self reloadData];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self setLayouter:self.layouter andFocusOnIndex:self.currentPage animated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.isViewVisible = YES;
    [self _tilePages];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.initialPageIndex = nil;
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
         completion:(void(^)(void))completion
{
    [self setLayouter:layouter animated:animated completion:^{
        if(completion) {
            completion();
        }
    }];
    
    if(!self.scrollView.isRunningAnimation) {
        if(animated) {
            [UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
                [self navigateToPageAtIndex:pageIndex animated:NO completion:nil];
            } completion:nil];
        } else {		
            [self navigateToPageAtIndex:pageIndex animated:animated completion:nil];
        }
    }
}

- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
           animated:(BOOL)animated
         completion:(void (^)(void))completion
{
    self.previousLayouter = self.layouter;
    self.layouter = layouter;
    
    if(!self.isViewLoaded) {
        return; // Will attempt tiling on viewDidLoad
    }
    
    void(^updateLayout)(void) = ^{
        [self _blockContentOffsetOnPageAtIndex:self.currentPage];
        [self _updateBoundsAndConstraints];
        [self _unblockContentOffset];
        
        [self _sortSubviewsByZPosition];
        [self _tilePages];
        
        [self.view layoutIfNeeded];
    };
    
    if(animated) {
        self.isAnimatingLayouterChange = YES;
        [UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
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
    if([self.dataSource respondsToSelector:@selector(initialPageInPageViewController:)]) {
        self.initialPageIndex = @([self.dataSource initialPageInPageViewController:self]);
        self.currentPage = self.initialPageIndex.unsignedIntegerValue;
    }
    
    [self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger pageIndex, BOOL *stop) {
        [self _removePageAtIndex:pageIndex];
    }];
    
    NSUInteger oldNumberOfPages = self.numberOfPages;
    self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
    
    [self.pages removeAllObjects];
    for(NSUInteger i = 0; i < self.numberOfPages; i++) {
        [self.pages addObject:[NSNull null]];
    }
    [self.visibleControllers removeAllObjects];
    
    if(oldNumberOfPages >= self.numberOfPages) {
        NSUInteger index = MAX(0, (NSInteger)self.numberOfPages - 1);
        [self navigateToPageAtIndex:index animated:NO completion:nil];
    } else {
        [self _updateBoundsAndConstraints];
        [self _tilePages];
    }
}

- (void)navigateToPageAtIndex:(NSUInteger)pageIndex
                     animated:(BOOL)animated
                   completion:(void(^)(void))completion
{
    NSUInteger previousCurrentPage = self.currentPage;
    
    if(pageIndex >= self.numberOfPages) {
        return;
    }
    
    CGRect frame = CGRectIntegral([self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self]);
    
    CGPoint offset;
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)];
        offset.x -= self.layouterContentInset.left;
    } else {
        offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)];
        offset.y -= self.layouterContentInset.top;
    }
    
    offset = CGPointMake((NSInteger)floor(offset.x), (NSInteger)floor(offset.y));
    
    void(^animationFinishedBlock)(void) = ^{
        
        [self _updateNavigationContraints];
        [self _tilePages];
        
        if(!animated && previousCurrentPage != self.currentPage && [self.delegate respondsToSelector:@selector(pageViewController:didNavigateToPageAtIndex:)]) {
            [self.delegate pageViewController:self didNavigateToPageAtIndex:pageIndex];
        }
        
        if(completion) {
            completion();
        }
    };
    
    [self.scrollView setContentOffset:offset easingFunction:self.easingFunction duration:(animated ? self.animationDuration : 0.0f) completion:animationFinishedBlock];
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

- (BOOL)visible
{
    return self.isViewVisible;
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
        self.layouterInterItemSpacing = round([self.layouter interItemSpacingForPageViewController:self]);
    } else {
        self.layouterInterItemSpacing = 0.0f;
    }
    
    CGRect frame = [self.layouter finalFrameForPageAtIndex:self.numberOfPages - 1 pageViewController:self];
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
        [self.scrollView setContentInset:UIEdgeInsetsMake(self.layouterContentInset.top, 0.0f, self.layouterContentInset.bottom, 0.0f)];
        [self.scrollView setContentSize:CGSizeMake(0.0f, round(MAX(CGRectGetHeight(self.scrollView.bounds), CGRectGetMaxY(frame))))];
    } else {
        [self.scrollView setContentInset:UIEdgeInsetsMake(0.0f, self.layouterContentInset.left, 0.0f, self.layouterContentInset.right)];
        [self.scrollView setContentSize:CGSizeMake(round(MAX(CGRectGetWidth(self.scrollView.bounds), CGRectGetMaxX(frame))), 0.0f)];
    }
    
    [self _updateNavigationContraints];
}

- (void)_updateNavigationContraints
{
    if(self.continuousNavigationEnabled) {
        return;
    }
    
    if(self.layouter.navigationConstraintType == SCPageLayouterNavigationContraintTypeNone) {
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
    
    if(!self.initialPageIndex) {
        self.currentPage = [self _calculateCurrentPage];
    }
    
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
        
        if([self.insertionIndexes containsIndex:pageIndex]) {
            continue;
        }
        
        UIViewController *page = [self viewControllerForPageAtIndex:pageIndex];
        if (!page) {
            [self _createAndInsertNewPageAtIndex:pageIndex];
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
                [details setVisiblePercentage:round((CGRectGetHeight(intersection) * 1000) / CGRectGetHeight(nextFrame)) / 1000.0f];
            } else {
                [details setVisiblePercentage:round((CGRectGetWidth(intersection) * 1000) / CGRectGetWidth(nextFrame)) / 1000.0f];
            }
        }
        
        remainder = [self _subtractRect:intersection fromRect:remainder withEdge:edge];
        
        CATransform3D previousTransform = viewController.view.layer.transform;
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
        
        if([self.layouter respondsToSelector:@selector(sublayerTransformForPageAtIndex:contentOffset:pageViewController:)]) {
            CATransform3D transform = [self.layouter sublayerTransformForPageAtIndex:pageIndex
                                                                       contentOffset:self.scrollView.contentOffset
                                                                  pageViewController:self];
            
            [self _setAnimatableSublayerTransform:transform forViewController:viewController];
        } else {
            [self _setAnimatableSublayerTransform:previousTransform forViewController:viewController];
        }
    }];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
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

- (void)_blockContentOffsetOnPageAtIndex:(NSUInteger)pageIndex
{
    self.blockedPageIndex = pageIndex;
    
    if(!self.isContentOffsetBlocked) {
        self.isContentOffsetBlocked = YES;
        [self.scrollView setDelegate:nil];
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(self.isContentOffsetBlocked) {
        [self _centerOnPageIndex:self.blockedPageIndex];
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
                zPosition = [self.layouter zPositionForPageAtIndex:i pageViewController:self];
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
        
        CGPoint centerOffset = self.scrollView.contentOffset;
        centerOffset.x += CGRectGetWidth(self.scrollView.bounds) / 2.0f;
        centerOffset.y += CGRectGetHeight(self.scrollView.bounds) / 2.0f;
        
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
    
    CGPoint adjustedOffset = *targetContentOffset;
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        adjustedOffset.x += self.layouterContentInset.left;
    }
    else {
        adjustedOffset.y += self.layouterContentInset.top;
    }
    
    // Enumerate through all the pages and figure out which one contains the targeted offset
    for(NSUInteger pageIndex = 0; pageIndex < self.numberOfPages; pageIndex++) {
        
        CGRect frame = [self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self];
        
        CGRect adjustedFrame = frame;
        if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
            adjustedFrame.origin.x -= self.layouterInterItemSpacing / 2.0f;
            adjustedFrame.size.width += self.layouterInterItemSpacing;
            adjustedFrame.origin.y = 0.0f;
            adjustedFrame.size.height = self.scrollView.bounds.size.height;
        }
        else {
            adjustedFrame.origin.y -= self.layouterInterItemSpacing / 2.0f;
            adjustedFrame.size.height += self.layouterInterItemSpacing;
            adjustedFrame.origin.x = 0.0f;
            adjustedFrame.size.width = self.scrollView.bounds.size.width;
        }
        
        if(CGRectContainsPoint(adjustedFrame, adjustedOffset)) {
            
            // Jump to the closest navigation step if the velocity is zero
            if(CGPointEqualToPoint(CGPointZero, velocity)) {
                if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
                    CGPoint previousStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)];
                    CGPoint nextStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(1.0f, 0.0f)];
                    
                    if(ABS(adjustedOffset.x - previousStepOffset.x) > ABS(adjustedOffset.x - nextStepOffset.x)) {
                        adjustedOffset = nextStepOffset;
                        adjustedOffset.x += self.layouterInterItemSpacing;
                    } else {
                        adjustedOffset = previousStepOffset;
                    }
                } else {
                    CGPoint previousStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)];
                    CGPoint nextStepOffset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, 1.0f)];
                    
                    if(ABS(adjustedOffset.y - previousStepOffset.y) > ABS(adjustedOffset.y - nextStepOffset.y)) {
                        adjustedOffset = nextStepOffset;
                        adjustedOffset.y += self.layouterInterItemSpacing;
                    } else {
                        adjustedOffset = previousStepOffset;
                    }
                }
            } else { // Calculate the next step of the pagination (either a navigationStep or a controller edge)
                adjustedOffset = [self _nextStepOffsetForFrame:frame withVelocity:velocity];
                if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
                    if(velocity.x > 0) {
                        adjustedOffset.x += self.layouterInterItemSpacing;
                    }
                } else {
                    if(velocity.y > 0) {
                        adjustedOffset.y += self.layouterInterItemSpacing;
                    }
                }
            }
            
            break;
        }
    }
    
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        adjustedOffset.y = 0.0f;
        adjustedOffset.x -= self.layouterContentInset.left;
    } else {
        adjustedOffset.x = 0.0f;
        adjustedOffset.y -= self.layouterContentInset.top;
    }
    
    *targetContentOffset = adjustedOffset;
}

#pragma mark - Private

- (CGRect)_subtractRect:(CGRect)r2 fromRect:(CGRect)r1 withEdge:(CGRectEdge)edge
{
    CGRect intersection = CGRectIntersection(r1, r2);
    if (CGRectIsNull(intersection)) {
        return r1;
    }
    
    CGFloat chopAmount = (edge == CGRectMinXEdge || edge == CGRectMaxXEdge) ? CGRectGetWidth(intersection) : CGRectGetHeight(intersection);
    
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

- (void)_centerOnPageIndex:(NSUInteger)pageIndex
{
    CGRect frame = CGRectIntegral([self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self]);
    
    CGPoint offset;
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(-1.0f, 0.0f)];
        offset.x -= self.layouterContentInset.left;
    } else {
        offset = [self _nextStepOffsetForFrame:frame withVelocity:CGPointMake(0.0f, -1.0f)];
        offset.y -= self.layouterContentInset.top;
    }
    
    offset = CGPointMake((NSInteger)floor(offset.x), (NSInteger)floor(offset.y));
    
    if(offset.x != (NSInteger)floor(self.scrollView.contentOffset.x) ||
       offset.y != (NSInteger)floor(self.scrollView.contentOffset.y)) {
        [self.scrollView setContentOffset:offset];
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
    
    SCPageViewControllerPageDetails *details = [[SCPageViewControllerPageDetails alloc] init];
    [details setViewController:page];
    [self.pages replaceObjectAtIndex:pageIndex withObject:details];
    
    if(page) {
        [self addChildViewController:page];
    }
    
    [page.view setAutoresizingMask:UIViewAutoresizingNone];
    [self.scrollView addSubview:page.view];
    
    [UIView performWithoutAnimation:^{
        if(self.isAnimatingLayouterChange) {
            [page.view setFrame:[self.previousLayouter finalFrameForPageAtIndex:pageIndex pageViewController:self]];
        } else {
            [page.view setFrame:[self.layouter finalFrameForPageAtIndex:pageIndex pageViewController:self]];
        }
    }];
    
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
    [viewController removeFromParentViewController];
    
    if([self.visibleControllers containsObject:viewController]) {
        [viewController endAppearanceTransition];
        
        [self.visibleControllers removeObject:viewController];
        
        if([self.delegate respondsToSelector:@selector(pageViewController:didHideViewController:atIndex:)]) {
            [self.delegate pageViewController:self didHideViewController:viewController atIndex:pageIndex];
        }
    }
}

#pragma mark - Private - Incremental Updates

- (void)reloadPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion
{
    NSMutableArray *removedViewControllers = [NSMutableArray array];
    
    dispatch_group_t animationsDispatchGroup = dispatch_group_create();
    
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        UIViewController *oldViewController = [self viewControllerForPageAtIndex:pageIndex];
        
        if(oldViewController) {
            [removedViewControllers addObject:oldViewController];
        }
        
        [oldViewController willMoveToParentViewController:nil];
        if([self.visibleViewControllers containsObject:oldViewController]) {
            [oldViewController beginAppearanceTransition:NO animated:animated];
        }
        
        [self.pages replaceObjectAtIndex:pageIndex withObject:[NSNull null]];
        UIViewController *newViewController = [self _createAndInsertNewPageAtIndex:pageIndex];
        
        if([newViewController isEqual:oldViewController]) {
            [removedViewControllers removeObject:newViewController];
        }
        
        if(animated && [self.layouter respondsToSelector:@selector(animatePageReloadAtIndex:oldViewController:newViewController:pageViewController:completion:)]) {
            dispatch_group_enter(animationsDispatchGroup);
            [self.layouter animatePageReloadAtIndex:pageIndex oldViewController:oldViewController newViewController:newViewController pageViewController:self completion:^{
                dispatch_group_leave(animationsDispatchGroup);
            }];
        }
    }];
    
    dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
        
        for(UIViewController *viewController in removedViewControllers) {
            [viewController.view removeFromSuperview];
            if([self.visibleViewControllers containsObject:viewController]) {
                [viewController endAppearanceTransition];
            }
            
            [viewController removeFromParentViewController];
            
            [self.visibleControllers removeObject:viewController];
        }
        
        [self _updateBoundsAndConstraints];
        [self _tilePages];
        
        if(completion) {
            completion();
        }
    });
}

- (void)insertPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion
{
    NSInteger oldNumberOfPages = self.numberOfPages;
    self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
    
    NSAssert((self.numberOfPages == oldNumberOfPages + indexes.count), @"Invalid number of pages after insertion. Expecting %lu and received %lu", (unsigned long)(oldNumberOfPages + indexes.count), (unsigned long)self.numberOfPages);
    
    self.insertionIndexes = indexes;
    
    dispatch_group_t animationsDispatchGroup = dispatch_group_create();
    
    __block BOOL shouldAdjustOffset = NO;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        
        BOOL shouldKeepCurrentPage = YES;
        if([self.layouter respondsToSelector:@selector(shouldPreserveOffsetForInsertionAtIndex:pageViewController:)]) {
            shouldKeepCurrentPage = [self.layouter shouldPreserveOffsetForInsertionAtIndex:pageIndex pageViewController:self];
        }
        
        if((shouldKeepCurrentPage && pageIndex <= self.currentPage) || (!shouldKeepCurrentPage && pageIndex < self.currentPage)) {
            shouldAdjustOffset = YES;
            *stop = YES;
        }
    }];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        
        // Insert the new page
        [self.pages insertObject:[NSNull null] atIndex:pageIndex];
        
        // Animate page movements
        if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
            if(shouldAdjustOffset) {
                for(NSInteger index = ((NSInteger)pageIndex - 1); index >= 0; index--) {
                    UIViewController *someController = [self viewControllerForPageAtIndex:index];
                    dispatch_group_enter(animationsDispatchGroup);
                    [self.layouter animatePageMoveFromIndex:(index + 1) toIndex:index viewController:someController pageViewController:self completion:^{
                        dispatch_group_leave(animationsDispatchGroup);
                    }];
                }
            } else {
                for(NSInteger index = (NSInteger)oldNumberOfPages; index >= (NSInteger)pageIndex; index--) {
                    UIViewController *someController = [self viewControllerForPageAtIndex:index];
                    dispatch_group_enter(animationsDispatchGroup);
                    [self.layouter animatePageMoveFromIndex:(index - 1) toIndex:index viewController:someController pageViewController:self completion:^{
                        dispatch_group_leave(animationsDispatchGroup);
                    }];
                }
            }
        }
    }];
    
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        
        UIViewController *viewController = [self _createAndInsertNewPageAtIndex:pageIndex];
        
        // Animate the page insertion
        if(animated && [self.layouter respondsToSelector:@selector(animatePageInsertionAtIndex:viewController:pageViewController:completion:)]) {
            
            if(shouldAdjustOffset) {
                [UIView performWithoutAnimation:^{
                    CGRect frame = viewController.view.frame;
                    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
                        frame.origin.x -= CGRectGetWidth(viewController.view.bounds) * indexes.count;
                    } else {
                        frame.origin.y -= CGRectGetHeight(viewController.view.bounds) * indexes.count;
                    }
                    viewController.view.frame = frame;
                }];
            }
            
            dispatch_group_enter(animationsDispatchGroup);
            [self.layouter animatePageInsertionAtIndex:pageIndex viewController:viewController pageViewController:self completion:^{
                dispatch_group_leave(animationsDispatchGroup);
            }];
        }
    }];
    
    void(^updateLayout)(void) = ^{
        if(shouldAdjustOffset) {
            [self _blockContentOffsetOnPageAtIndex:(self.currentPage + indexes.count)];
        }
        [self _updateBoundsAndConstraints];
        [self _tilePages];
        [self _unblockContentOffset];
    };
    
    if(animated) {
        dispatch_group_enter(animationsDispatchGroup);
        [UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
            updateLayout();
        } completion:^(BOOL finished) {
            dispatch_group_leave(animationsDispatchGroup);
        }];
    } else {
        updateLayout();
    }
    
    dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
        
        self.insertionIndexes = nil;
        [self _tilePages];
        
        if(completion) {
            completion();
        }
    });
}

- (void)deletePagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion
{
    NSInteger oldNumberOfPages = self.numberOfPages;
    self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
    NSAssert((self.numberOfPages == oldNumberOfPages - indexes.count), @"Invalid number of pages after removal. Expecting %lu and received %lu", (unsigned long)(oldNumberOfPages - indexes.count), (unsigned long)self.numberOfPages);
    
    __block BOOL shouldAdjustOffset = NO;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        if(pageIndex < self.currentPage) {
            shouldAdjustOffset = YES;
            *stop = YES;
        }
    }];
    
    dispatch_group_t animationsDispatchGroup = dispatch_group_create();
    
    NSMutableArray *removedViewControllers = [NSMutableArray array];
    
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger pageIndex, BOOL *stop) {
        
        UIViewController *viewController = [self viewControllerForPageAtIndex:pageIndex];
        
        if(viewController) {
            [removedViewControllers addObject:viewController];
        }
        
        [viewController willMoveToParentViewController:nil];
        if([self.visibleViewControllers containsObject:viewController]) {
            [viewController beginAppearanceTransition:NO animated:animated];
        }
        
        // Animate the deletion
        if(animated && [self.layouter respondsToSelector:@selector(animatePageDeletionAtIndex:viewController:pageViewController:completion:)]) {
            dispatch_group_enter(animationsDispatchGroup);
            
            NSInteger animationIndex = (shouldAdjustOffset ? pageIndex - 1 : pageIndex);
            [self.layouter animatePageDeletionAtIndex:animationIndex viewController:viewController pageViewController:self completion:^{
                dispatch_group_leave(animationsDispatchGroup);
            }];
            
            if(shouldAdjustOffset) {
                dispatch_group_enter(animationsDispatchGroup);
                [UIView animateWithDuration:self.animationDuration animations:^{
                    
                    CGRect frame = viewController.view.frame;
                    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
                        frame.origin.x -= CGRectGetWidth(viewController.view.bounds) * indexes.count;
                    } else {
                        frame.origin.y -= CGRectGetHeight(viewController.view.bounds) * indexes.count;
                    }
                    viewController.view.frame = frame;
                } completion:^(BOOL finished) {
                    dispatch_group_leave(animationsDispatchGroup);
                }];
            }
        } else {
            [viewController.view removeFromSuperview];
        }
        
        // Update page indexes
        [self.pages removeObjectAtIndex:pageIndex];
    }];
    
    // Update the content offset and pages layout
    void (^updateLayout)(void) = ^{
        if(shouldAdjustOffset) {
            [self _blockContentOffsetOnPageAtIndex:(self.currentPage - indexes.count)];
        }
        
        [self _updateBoundsAndConstraints];
        [self _tilePages];
        [self _unblockContentOffset];
    };
    
    if(animated) {
        dispatch_group_enter(animationsDispatchGroup);
        [UIView animateWithDuration:self.animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
            updateLayout();
        } completion:^(BOOL finished) {
            dispatch_group_leave(animationsDispatchGroup);
        }];
    } else {
        updateLayout();
    }
    
    // Cleanup and notify of completion
    dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
        
        for(UIViewController *viewController in removedViewControllers) {
            [viewController.view removeFromSuperview];
            if([self.visibleViewControllers containsObject:viewController]) {
                [viewController endAppearanceTransition];
            }
            
            [viewController removeFromParentViewController];
            [self.visibleControllers removeObject:viewController];
        }
        
        [self _tilePages];
        
        if(completion) {
            completion();
        }
    });
}

- (void)movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated completion:(void(^)(void))completion
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
    
    BOOL shouldAdjustOffset = (fromIndex < self.currentPage && toIndex > self.currentPage) || (fromIndex > self.currentPage && toIndex < self.currentPage);
    
    UIViewController *viewController = [self viewControllerForPageAtIndex:fromIndex];
    
    dispatch_group_t animationsDispatchGroup = dispatch_group_create();
    
    SCPageViewControllerPageDetails *pageDetails = [self.pages objectAtIndex:fromIndex];
    [self.pages removeObjectAtIndex:fromIndex];
    [self.pages insertObject:pageDetails atIndex:toIndex];
    
    if(fromIndex < toIndex) {
        for(NSInteger pageIndex = (NSInteger)fromIndex; pageIndex < (NSInteger)toIndex; pageIndex++) {
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
        for(NSInteger pageIndex = (NSInteger)fromIndex; pageIndex >= (NSInteger)toIndex; pageIndex--) {
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
        [self _blockContentOffsetOnPageAtIndex:self.currentPage];
    }
    
    if(!viewController) {
        // Force load the missing page
        viewController = [self _createAndInsertNewPageAtIndex:toIndex];
        [viewController.view setFrame:[self.layouter finalFrameForPageAtIndex:fromIndex pageViewController:self]];
    }
    
    if(animated && [self.layouter respondsToSelector:@selector(animatePageMoveFromIndex:toIndex:viewController:pageViewController:completion:)]) {
        dispatch_group_enter(animationsDispatchGroup);
        [self.layouter animatePageMoveFromIndex:fromIndex toIndex:toIndex viewController:viewController pageViewController:self completion:^{
            dispatch_group_leave(animationsDispatchGroup);
        }];
    }
    
    dispatch_group_notify(animationsDispatchGroup, dispatch_get_main_queue(), ^{
        
        if(shouldAdjustOffset) {
            if(fromIndex < toIndex) {
                [self _blockContentOffsetOnPageAtIndex:(self.currentPage - 1)];
            } else {
                [self _blockContentOffsetOnPageAtIndex:(self.currentPage + 1)];
            }
        }
        
        [self _updateBoundsAndConstraints];
        [self _tilePages];
        
        [self _unblockContentOffset];
        
        if(completion) {
            completion();
        }
    });
}

@end
