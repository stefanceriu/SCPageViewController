//
//  SCPageViewController.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageViewController.h"
#import "SCPageViewControllerScrollView.h"
#import "SCPageLayouterProtocol.h"

@interface SCPageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) SCPageViewControllerScrollView *scrollView;

@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) NSUInteger numberOfPages;

@property (nonatomic, strong) NSMutableOrderedSet *loadedControllers;
@property (nonatomic, strong) NSMutableArray *visibleControllers;

@property (nonatomic, strong) NSMutableDictionary *pageIndexes;
@property (nonatomic, strong) NSMutableDictionary *visiblePercentages;

@end

@implementation SCPageViewController
@dynamic showsScrollIndicators;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    self.scrollView = [[SCPageViewControllerScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
    
    [self.view addSubview:self.scrollView];
    
    [self reloadData];
}

- (void)viewWillLayoutSubviews
{
    [self updateContentSize];
    [self tilePages];
    [self updateFramesAndTriggerAppearanceCallbacks];
}

#pragma mark - Public Methods

- (void)reloadData
{
    for(UIViewController *controller in self.loadedControllers) {
        [controller willMoveToParentViewController:nil];
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
    }
    
    self.loadedControllers = [NSMutableOrderedSet orderedSet];
    self.visibleControllers = [NSMutableArray array];
    self.pageIndexes = [NSMutableDictionary dictionary];
    self.visiblePercentages = [NSMutableDictionary dictionary];
    
    self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
    [self updateContentSize];
    
    [self tilePages];
    [self updateFramesAndTriggerAppearanceCallbacks];
}

- (void)navigateToPageAtIndex:(NSUInteger)pageIndex animated:(BOOL)animated
{
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
        CGPoint contentOffset = CGPointMake(0, pageIndex * self.view.bounds.size.height);
        contentOffset.y = MAX(contentOffset.y, 0);
        contentOffset.y = MIN(contentOffset.y, (self.numberOfPages - 1) * self.view.bounds.size.height);
        [self.scrollView setContentOffset:contentOffset animated:animated];
    } else {
        CGPoint contentOffset = CGPointMake(pageIndex * self.view.bounds.size.width, 0);
        contentOffset.x = MAX(contentOffset.x, 0);
        contentOffset.x = MIN(contentOffset.x, (self.numberOfPages - 1) * self.view.bounds.size.width);
        [self.scrollView setContentOffset:contentOffset animated:animated];
    }
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

#pragma mark - Page Management

- (void)updateContentSize
{
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
        [self.scrollView setContentSize:CGSizeMake(0, self.numberOfPages * CGRectGetHeight(self.view.bounds))];
    } else {
        [self.scrollView setContentSize:CGSizeMake(self.numberOfPages * CGRectGetWidth(self.view.bounds), 0)];
    }
}

- (void)tilePages
{
    self.currentPage = [self calculateCurrentPage];
    
    NSInteger firstNeededPageIndex = self.currentPage - 1;
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    
    
    NSInteger lastNeededPageIndex  = self.currentPage + 1;
    lastNeededPageIndex  = MIN(lastNeededPageIndex, ((int)self.numberOfPages - 1));
    
    NSMutableSet *removedPages = [NSMutableSet set];
    
    for (UIViewController *page in self.loadedControllers) {
        NSUInteger pageIndex = [self.pageIndexes[@(page.hash)] unsignedIntegerValue];
        
        if (pageIndex < firstNeededPageIndex || pageIndex > lastNeededPageIndex) {
            [removedPages addObject:page];
            [self.pageIndexes removeObjectForKey:@(page.hash)];
            
            [page willMoveToParentViewController:nil];
            [page.view removeFromSuperview];
            [page removeFromParentViewController];
        }
    }
    [self.loadedControllers minusSet:removedPages];
    
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        
        if (![self isDisplayingPageForIndex:index]) {
            UIViewController *page = [self.dataSource pageViewController:self viewControllerForPageAtIndex:index];;
            
            [self.loadedControllers addObject:page];
            [self.pageIndexes setObject:@(index) forKey:@(page.hash)];
            
            [page willMoveToParentViewController:self];
            [self addChildViewController:page];
            
            if(index > self.currentPage) {
                [self.scrollView insertSubview:page.view atIndex:0];
            } else {
                [self.scrollView addSubview:page.view];
            }
        }
    }
}

- (NSUInteger)calculateCurrentPage
{
	int page;
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
        page = self.scrollView.contentOffset.y / CGRectGetHeight(self.view.bounds) + 0.5f;
    } else {
        page = self.scrollView.contentOffset.x / CGRectGetWidth(self.view.bounds) + 0.5f;
    }
    
	page = MIN(page, self.numberOfPages - 1);
	page = MAX(page, 0);
    
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (UIViewController *page in self.loadedControllers) {
        
        NSUInteger pageIndex = [self.pageIndexes[@(page.hash)] unsignedIntegerValue];
        if (pageIndex == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

#pragma mark Appearance callbacks and framesetting

- (void)updateFramesAndTriggerAppearanceCallbacks
{
    __block CGRect remainder = self.scrollView.bounds;
    
    NSArray *sortedPages = [self.loadedControllers sortedArrayUsingComparator:^NSComparisonResult(UIViewController *obj1, UIViewController *obj2) {
        NSUInteger firstPageIndex = [self.pageIndexes[@(obj1.hash)] unsignedIntegerValue];
        NSUInteger secondPageIndex = [self.pageIndexes[@(obj2.hash)] unsignedIntegerValue];
        
        return [@(firstPageIndex) compare:@(secondPageIndex)];
    }];
    
    [sortedPages enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        
        NSUInteger pageIndex = [self.pageIndexes[@(viewController.hash)] unsignedIntegerValue];
        
        CGRect nextFrame =  [self.layouter currentFrameForViewController:viewController
                                                               withIndex:pageIndex
                                                           contentOffset:self.scrollView.contentOffset
                                                    inPageViewController:self];
        
        CGRect intersection = CGRectIntersection(remainder, nextFrame);
        // If a view controller's frame does intersect the remainder then it's visible
        BOOL visible = self.layouter.navigationType == SCPageLayouterNavigationTypeVertical ? (CGRectGetHeight(intersection) > 0.0f) : (CGRectGetWidth(intersection) > 0.0f);
        
        if(visible) {
            if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
                [self.visiblePercentages setObject:@(roundf((CGRectGetHeight(intersection) * 1000) / CGRectGetHeight(nextFrame))/1000.0f) forKey:@([viewController hash])];
            } else {
                [self.visiblePercentages setObject:@(roundf((CGRectGetWidth(intersection) * 1000) / CGRectGetWidth(nextFrame))/1000.0f) forKey:@([viewController hash])];
            }
        }
        
        remainder = [self subtractRect:intersection fromRect:remainder withEdge:[self edgeFromOffset:self.scrollView.contentOffset]];
        
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

// Forward touchRefusalArea, bounces, scrollEnabled, pagingEnabled, minimum and maximum numberOfTouches
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if([self.scrollView respondsToSelector:aSelector]) {
        return self.scrollView;
    } else if([self.scrollView.panGestureRecognizer respondsToSelector:aSelector]) {
        return self.scrollView.panGestureRecognizer;
    }
    
    return self;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePages];
    [self updateFramesAndTriggerAppearanceCallbacks];
    
    if([self.delegate respondsToSelector:@selector(pageViewController:didNavigateToOffset:)]) {
        [self.delegate pageViewController:self didNavigateToOffset:self.scrollView.contentOffset];
    }
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self.scrollView setContentOffset:CGPointMake(self.view.bounds.size.width * self.currentPage, 0) animated:YES];
}

#pragma mark - Helpers

- (CGRect)subtractRect:(CGRect)r2 fromRect:(CGRect)r1 withEdge:(CGRectEdge)edge
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

- (CGRectEdge)edgeFromOffset:(CGPoint)offset
{
    CGRectEdge edge = -1;
    
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeHorizontal) {
        if(offset.x >= 0.0f) {
            edge = CGRectMinXEdge;
        } else if(offset.x < 0.0f) {
            edge = CGRectMaxXEdge;
        }
    }
    
    if(self.layouter.navigationType == SCPageLayouterNavigationTypeVertical) {
        if(offset.y >= 0.0f) {
            edge = CGRectMinYEdge;
        } else if(offset.y < 0.0f) {
            edge = CGRectMaxYEdge;
        }
    }
    
    return edge;
}

@end
