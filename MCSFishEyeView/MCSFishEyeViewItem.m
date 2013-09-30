//
//  MCSFishEyeViewItem.m
//
//  Created by Bartosz Ciechanowski on 8/29/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import "MCSFishEyeViewItem.h"

@implementation MCSFishEyeViewItem


- (void)setSelected:(BOOL)selected
{
  [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  _selected = selected;
}

- (void)setHighlighted:(BOOL)highlighted
{
  [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
  _highlighted = highlighted;
}

@end
