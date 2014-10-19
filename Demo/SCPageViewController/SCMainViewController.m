//
//  SCMainViewController.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCMainViewController.h"

@interface SCMainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *pageNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *visiblePercentageLabel;

@end

@implementation SCMainViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view setHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.view setHidden:YES];
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
                        @(SCPageLayouterTypeFacebookPaper)      : @"Facebook/Paper",
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

@end
