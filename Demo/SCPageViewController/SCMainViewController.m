//
//  SCMainViewController.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCMainViewController.h"
#import "UIView+Shadows.h"

@interface SCMainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *pageNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *visiblePercentageLabel;

@property (nonatomic, assign) SCShadowEdge currentShadowEdge;

@end

@implementation SCMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentShadowEdge = SCShadowEdgeAll;
}

- (void)viewWillLayoutSubviews
{
    [self.view castShadowWithPosition:self.currentShadowEdge];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return SCPageLayouterTypeCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    static NSDictionary *typeToString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeToString = (@{
                        @(SCPageLayouterTypePlain)              : @"Plain",
                        @(SCPageLayouterTypeSliding)            : @"Sliding",
                        @(SCPageLayouterTypeParallax)           : @"Parallax",
                        });
    });
    
    [cell.textLabel setText:typeToString[@(indexPath.row)]];
    [cell.textLabel setFont:[UIFont fontWithName:@"Menlo" size:18.0f]];
    [cell setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.20f]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.delegate respondsToSelector:@selector(mainViewController:didSelectLayouter:)]) {
        [self.delegate mainViewController:self didSelectLayouter:indexPath.row];
    }
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.currentShadowEdge = SCShadowEdgeNone;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.currentShadowEdge = SCShadowEdgeAll;
    [self.view setNeedsLayout];
}

@end
