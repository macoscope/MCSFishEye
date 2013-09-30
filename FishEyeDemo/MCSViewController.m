//
//  MCSViewController.m
//  FishEyeDemo
//
//  Created by Bartosz Ciechanowski on 8/30/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import "MCSViewController.h"
#import "MCSFishEyeView.h"
#import "MCSDemoFishEyeItem.h"

@interface MCSViewController () <MCSFishEyeViewDataSource, MCSFishEyeViewDelegate>

@property (weak, nonatomic) IBOutlet MCSFishEyeView *leftFishEyeView;
@property (weak, nonatomic) IBOutlet MCSFishEyeView *topFishEyeView;
@property (weak, nonatomic) IBOutlet MCSFishEyeView *rightFishEyeView;
@property (weak, nonatomic) IBOutlet MCSFishEyeView *bottomFishEyeView;

@property (strong, nonatomic) IBOutletCollection(MCSFishEyeView) NSArray *fishEyeViews;

@end

@implementation MCSViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.leftFishEyeView.itemSize = CGSizeMake(120.0, 120.0);
  self.leftFishEyeView.contentInset = UIEdgeInsetsMake(20.0, 5.0, 20.0, 0.0);
  [self.leftFishEyeView registerItemClass:[MCSDemoFishEyeItem class]];
  
  self.rightFishEyeView.itemSize = CGSizeMake(130.0, 130.0);
  self.rightFishEyeView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 20.0, 10.0);
  self.rightFishEyeView.expansionDirection = MCSFishEyeExpansionDirectionLeft;
  self.rightFishEyeView.selectedItemOffset = 80.0f;
  [self.rightFishEyeView registerItemNib:[UINib nibWithNibName:@"MCSDemoXibFishEyeViewItem" bundle:nil]];
  
  self.topFishEyeView.itemSize = CGSizeMake(70.0, 70.0);
  self.topFishEyeView.expansionDirection = MCSFishEyeExpansionDirectionBottom;
  self.topFishEyeView.contentInset = UIEdgeInsetsMake(14.0, 0.0, 0.0, 0.0);
  [self.topFishEyeView registerItemClass:[MCSDemoFishEyeItem class]];
  
  self.bottomFishEyeView.itemSize = CGSizeMake(90.0, 90.0);
  self.bottomFishEyeView.contentInset = UIEdgeInsetsMake(0.0, 40.0, 0.0, 40.0);
  self.bottomFishEyeView.expansionDirection = MCSFishEyeExpansionDirectionTop;
  self.bottomFishEyeView.selectedItemOffset = 40.0f;
  [self.bottomFishEyeView registerItemClass:[MCSDemoFishEyeItem class]];
  
  for (MCSFishEyeView *fishEye in self.fishEyeViews) {
    fishEye.dataSource = self;
    fishEye.delegate = self;
    
    
    [fishEye reloadData];
  }
}

#pragma mark - FishEye Data Source

- (NSUInteger)numberOfItemsInFishEyeView:(MCSFishEyeView *)fishEyeView
{
  return fishEyeView == self.rightFishEyeView ? 4 : 20;
}

- (void)fishEyeView:(MCSFishEyeView *)fishEyeView configureItem:(MCSDemoFishEyeItem *)item atIndex:(NSUInteger)index
{
  if (fishEyeView == self.leftFishEyeView) {
    item.label.text = [@(index + 1) stringValue];
  } else {
    item.label.text = [NSString stringWithFormat:@"%c", 'A' + index];
  }
}

#pragma mark - FishEye Delegate

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  for (MCSFishEyeView *fishEye in self.fishEyeViews) {
    [fishEye deselectSelectedItemAnimated:YES];
  }
}

@end
