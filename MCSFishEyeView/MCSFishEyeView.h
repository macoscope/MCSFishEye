//
//  MCSFishEyeView.h
//
//  Created by Bartosz Ciechanowski on 2/25/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCSFishEyeView, MCSFishEyeViewItem;

typedef NS_ENUM(NSInteger, MCSFishEyeState) {
  MCSFishEyeStateCollapsed,       // all elements are docked in
  MCSFishEyeStateExpandedActive,  // touch event happening, elements are moving around
  MCSFishEyeStateExpandedPassive  // single element is out, rest is docked in
};

typedef NS_ENUM(NSInteger, MCSFishEyeExpansionDirection) {
  MCSFishEyeExpansionDirectionRight,
  MCSFishEyeExpansionDirectionLeft,
  MCSFishEyeExpansionDirectionTop,
  MCSFishEyeExpansionDirectionBottom
};

// those methods get called only after reloadData
@protocol MCSFishEyeViewDataSource <NSObject>

- (NSUInteger)numberOfItemsInFishEyeView:(MCSFishEyeView *)fishEyeView;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView configureItem:(MCSFishEyeViewItem *)item atIndex:(NSUInteger)index;

@end

@protocol MCSFishEyeViewDelegate <NSObject>

@optional
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView willChangeToState:(MCSFishEyeState)newState;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView didChangeFromState:(MCSFishEyeState)oldState;

- (BOOL)fishEyeView:(MCSFishEyeView *)fishEyeView shouldHighlightItemAtIndex:(NSUInteger)index;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView didHighlightItemAtIndex:(NSUInteger)index;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView didUnhighlightItemAtIndex:(NSUInteger)index;

- (BOOL)fishEyeView:(MCSFishEyeView *)fishEyeView shouldSelectItemAtIndex:(NSUInteger)index;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView didSelectItemAtIndex:(NSUInteger)index;
- (void)fishEyeView:(MCSFishEyeView *)fishEyeView didDeselectItemAtIndex:(NSUInteger)index;

@end

@interface MCSFishEyeView : UIView

@property (nonatomic, weak) id<MCSFishEyeViewDataSource> dataSource;
@property (nonatomic, weak) id<MCSFishEyeViewDelegate> delegate;

@property (nonatomic, readonly) MCSFishEyeState state;

@property (nonatomic) MCSFishEyeExpansionDirection expansionDirection; // defaults to MCSFishEyeExpansionDirectionRight
@property (nonatomic) BOOL evadesFinger; // if YES, then fisheye's items will get translated in expansion direction, so that they're not overlapped by finger, defaults to YES

@property (nonatomic) CGSize itemSize; // size of fully expanded item, defaults to CGSizeMake(100.0f, 100.0f);
@property (nonatomic) CGFloat selectedItemOffset; // offset of selected item in the direction of expansion, defaults to 50.0f
@property (nonatomic) UIEdgeInsets contentInset; // additional insets applied when layouting items, defaults to UIEdgeInsetsZero

@property (nonatomic, readonly) NSUInteger highlightedIndex; // returns NSNotFound if none is highlighted
@property (nonatomic, readonly) NSUInteger selectedIndex; // returns NSNotFound if none is selected

// the last one used counts
- (void)registerItemNib:(UINib *)nib; // the nib file must contain only one top-level object and that object must be subclass of MCSFishEyeViewItem
- (void)registerItemClass:(Class)itemClass; // itemClass must be subclass of MCSFishEyeViewItem

- (void)reloadData;

- (void)selectItemAtIndex:(NSUInteger)index animated:(BOOL)animated; // will not notify delegate
- (void)deselectSelectedItemAnimated:(BOOL)animated; // will not notify delegate

- (MCSFishEyeViewItem *)itemAtIndex:(NSUInteger)index;
- (NSUInteger)indexForItem:(MCSFishEyeViewItem *)item;

@end
