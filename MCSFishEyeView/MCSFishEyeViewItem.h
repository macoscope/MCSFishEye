//
//  MCSFishEyeViewItem.h
//
//  Created by Bartosz Ciechanowski on 8/29/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import <UIKit/UIKit.h>

// for the sake of pre iOS7 SDK compatibility
#ifndef NS_REQUIRES_SUPER
  #if __has_attribute(objc_requires_super)
    #define NS_REQUIRES_SUPER __attribute__((objc_requires_super))
  #else
    #define NS_REQUIRES_SUPER
  #endif
#endif


@interface MCSFishEyeViewItem : UIView

@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated NS_REQUIRES_SUPER;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated NS_REQUIRES_SUPER;

@end
