//
//  MCSFishEyeView.m
//
//  Created by Bartosz Ciechanowski on 2/25/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import "MCSFishEyeView.h"
#import "MCSFishEyeViewItem.h"

#import <QuartzCore/QuartzCore.h>

/*
 If an item is within this distance to touch location,
 it will get gradually translated in the direction of expansion,
 so that this item is not obstructed by finger (only if 'evadesFinger' is set to YES)
 */
static const CGFloat FingerTranslationRadius = 100.0;

/*
 Amount of translation applied to items in the direction of expansion
 (only if 'evadesFinger' is set to YES)
 */
static const CGFloat FingerTranslation = 60.0;

/*
 Determines the maxium number of neighbors that get enalrged by expansion function
 */
static const NSInteger MaxExpansionFunctionNeighbors = 3;



@interface MCSFishEyeView()
{
  struct {
    unsigned int willChangeToState:1;
    unsigned int didChangeFromState:1;
    
    unsigned int shouldHighlight:1;
    unsigned int didHighlight:1;
    unsigned int didUnhighlight:1;
    
    unsigned int shouldSelect:1;
    unsigned int didSelect:1;
    unsigned int didDeselect:1;

  } _delegateRespondsTo;
}

@property (nonatomic, strong) NSArray *itemContainers;
@property (nonatomic, strong) NSArray *items;

@property (nonatomic, strong) UIView *transformView;

@property (nonatomic, readwrite) MCSFishEyeState state;
@property (nonatomic) NSInteger expansionsNeighbors;

@property (nonatomic) CGAffineTransform itemTransform;
@property (nonatomic) CGSize transformedItemSize;
@property (nonatomic) CGFloat collapsedItemScale;
@property (nonatomic) CGFloat collapsedItemHeight;

@property (nonatomic) CGFloat startOffset;
@property (nonatomic) CGFloat centeringOffset;

@property (nonatomic, strong) Class itemClass;
@property (nonatomic, strong) UINib *itemNib;

@end

@implementation MCSFishEyeView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit
{
  _itemClass = [MCSFishEyeViewItem class];
  _itemSize = CGSizeMake(100.0f, 100.0f);
  _selectedItemOffset = 50.0f;
  _contentInset = UIEdgeInsetsZero;
  _evadesFinger = YES;
  _expansionDirection = MCSFishEyeExpansionDirectionRight;
  
  _selectedIndex = NSNotFound;
  _highlightedIndex = NSNotFound;
  
  _transformView = [[UIView alloc] init];
  _transformView.backgroundColor = [UIColor clearColor];
  [self addSubview:_transformView];
}

#pragma mark - Setters

- (void)setDelegate:(id<MCSFishEyeViewDelegate>)delegate
{
  _delegate = delegate;
  _delegateRespondsTo.willChangeToState = [delegate respondsToSelector:@selector(fishEyeView:willChangeToState:)];
  _delegateRespondsTo.didChangeFromState = [delegate respondsToSelector:@selector(fishEyeView:didChangeFromState:)];
  
  _delegateRespondsTo.shouldHighlight = [delegate respondsToSelector:@selector(fishEyeView:shouldHighlightItemAtIndex:)];
  _delegateRespondsTo.didHighlight = [delegate respondsToSelector:@selector(fishEyeView:didHighlightItemAtIndex:)];
  _delegateRespondsTo.didUnhighlight = [delegate respondsToSelector:@selector(fishEyeView:didUnhighlightItemAtIndex:)];
  
  _delegateRespondsTo.shouldSelect = [delegate respondsToSelector:@selector(fishEyeView:shouldSelectItemAtIndex:)];
  _delegateRespondsTo.didSelect = [delegate respondsToSelector:@selector(fishEyeView:didSelectItemAtIndex:)];
  _delegateRespondsTo.didDeselect = [delegate respondsToSelector:@selector(fishEyeView:didDeselectItemAtIndex:)];
}

- (void)setState:(MCSFishEyeState)newFishEyeState
{
  if (_state == newFishEyeState) {
    return;
  }
  
  MCSFishEyeState oldFishEyeState = _state;
  
  if (_delegateRespondsTo.willChangeToState) {
    [self.delegate fishEyeView:self willChangeToState:newFishEyeState];
  }
  
  _state = newFishEyeState;
  
  if (_delegateRespondsTo.didChangeFromState) {
    [self.delegate fishEyeView:self didChangeFromState:oldFishEyeState];
  }
}

- (void)setItemSize:(CGSize)itemSize
{
  _itemSize = itemSize;
  
  for (MCSFishEyeViewItem *item in self.itemContainers) {
    item.bounds = CGRectMake(0, 0, itemSize.width, itemSize.height);
    item.center = CGPointZero;
  }
  
  [self setNeedsLayout];
}

- (void)setExpansionDirection:(MCSFishEyeExpansionDirection)expansionDirection
{
  _expansionDirection = expansionDirection;
  [self setNeedsLayout];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  _contentInset = contentInset;
  [self setNeedsLayout];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self repositionTransformView];
  [self recalculateDimensions];
  [self layoutWithCurrentState];
}

- (void)setHighlightedIndex:(NSUInteger)highlightedIndex
{
  if (highlightedIndex == _highlightedIndex) {
    return;
  }
  
  if (_highlightedIndex != NSNotFound) {
    [[self itemAtIndex:_highlightedIndex] setHighlighted:NO animated:YES];
    if (_delegateRespondsTo.didUnhighlight) {
      [self.delegate fishEyeView:self didUnhighlightItemAtIndex:_highlightedIndex];
    }
  }
  
  if (_delegateRespondsTo.shouldHighlight && ![self.delegate fishEyeView:self shouldHighlightItemAtIndex:highlightedIndex]) {
    highlightedIndex = NSNotFound; // don't highlight anything
  }
  
  _highlightedIndex = highlightedIndex;
  
  if (_highlightedIndex != NSNotFound) {
    [[self itemAtIndex:_highlightedIndex] setHighlighted:YES animated:YES];
    if (_delegateRespondsTo.didHighlight) {
      [self.delegate fishEyeView:self didHighlightItemAtIndex:_highlightedIndex];
    }
  }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex withDelegateCalls:(BOOL)shouldCallDelegate animated:(BOOL)animated
{
  if (selectedIndex == _selectedIndex) {
    return;
  }
  
  if (_selectedIndex != NSNotFound) {
    [[self itemAtIndex:_selectedIndex] setSelected:NO animated:animated];
    if (shouldCallDelegate && _delegateRespondsTo.didDeselect) {
      [self.delegate fishEyeView:self didDeselectItemAtIndex:_selectedIndex];
    }
  }
  
  if (shouldCallDelegate && _delegateRespondsTo.shouldSelect && ![self.delegate fishEyeView:self shouldSelectItemAtIndex:selectedIndex]) {
    selectedIndex = NSNotFound; // don't select anything
  }
  
  _selectedIndex = selectedIndex;
  
  if (_selectedIndex != NSNotFound) {
    [self bringSubviewToFront:self.itemContainers[_selectedIndex]];
    [[self itemAtIndex:_selectedIndex] setSelected:YES animated:animated];
    if (shouldCallDelegate && _delegateRespondsTo.didSelect) {
      [self.delegate fishEyeView:self didSelectItemAtIndex:_selectedIndex];
    }
  }
}

#pragma mark - Public functions

- (void)registerItemClass:(Class)itemClass
{
  NSParameterAssert(itemClass != nil);
  NSParameterAssert([itemClass isSubclassOfClass:[MCSFishEyeViewItem class]]);

  self.itemClass = itemClass;
  self.itemNib = nil;
}

- (void)registerItemNib:(UINib *)nib
{
  NSParameterAssert(nib != nil);
  
  self.itemClass = nil;
  self.itemNib = nib;
}

- (void)reloadData
{
  [self.items makeObjectsPerformSelector:@selector(removeFromSuperview)];
  
  NSUInteger count = [self.dataSource numberOfItemsInFishEyeView:self];
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:count];
  NSMutableArray *containers = [NSMutableArray arrayWithCapacity:count];
  
  for (int i = 0; i < count; i++) {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor clearColor];
    container.bounds = CGRectMake(0, 0, _itemSize.width, _itemSize.height);
    container.center = CGPointZero;
    
    MCSFishEyeViewItem *item;
    if (self.itemClass) {
      item = [[self.itemClass alloc] init];
    } else if (self.itemNib) {
      NSArray *elements = [self.itemNib instantiateWithOwner:nil options:nil];
      NSAssert(elements.count == 1, @"Instantiated NIB file doesn't have one top level object");
      item = elements[0];
      NSAssert([item isKindOfClass:[MCSFishEyeViewItem class]], @"Instantiated NIB object isn't subclass of MCSFishEyeViewItem");
    }
    
    item.frame = container.bounds;
    item.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    item.highlighted = NO;
    item.selected = NO;

    [self.dataSource fishEyeView:self configureItem:item atIndex:i];
    
    [items addObject:item];
    [containers addObject:container];
    
    [container addSubview:item];
    [self.transformView addSubview:container];
  }
  
  self.items = items;
  self.itemContainers = containers;
  self.state = MCSFishEyeStateCollapsed;
  
  self.expansionsNeighbors = MIN(MaxExpansionFunctionNeighbors, items.count/2);
  
  [self recalculateDimensions];
  [self layoutWithCurrentState];
  [self collapseAnimated:NO notifying:NO];
}

- (MCSFishEyeViewItem *)itemAtIndex:(NSUInteger)index
{
  return self.items[index];
}

- (NSUInteger)indexForItem:(MCSFishEyeViewItem *)item
{
  return [self.items indexOfObject:item];
}

- (void)selectItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
  [self setState:MCSFishEyeStateExpandedPassive];
  [self setSelectedIndex:index withDelegateCalls:NO animated:animated];
  [self layoutItemsForOffset:[self offsetForIndex:index] withAnimationDuration:animated ? 0.2 : 0.0];
}

- (void)deselectSelectedItemAnimated:(BOOL)animated
{
  [self setSelectedIndex:NSNotFound withDelegateCalls:NO animated:YES];
  [self collapseAnimated:animated notifying:NO];
}

#pragma mark - Calculations

- (void)repositionTransformView
{
  CGRect bounds = self.bounds;
  bounds.origin.x += self.contentInset.left;
  bounds.origin.y += self.contentInset.top;
  bounds.size.width -= (self.contentInset.left + self.contentInset.right);
  bounds.size.height -= (self.contentInset.top + self.contentInset.bottom);
  
  CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  CGAffineTransform viewTransform, itemTransform;
  
  switch (self.expansionDirection) {
    case MCSFishEyeExpansionDirectionRight:
      viewTransform = CGAffineTransformIdentity;
      itemTransform = CGAffineTransformIdentity;
      break;
    case MCSFishEyeExpansionDirectionLeft:
      viewTransform = CGAffineTransformMakeScale(-1.0, 1.0);
      itemTransform = CGAffineTransformMakeScale(-1.0, 1.0);
      break;
    case MCSFishEyeExpansionDirectionTop:
      viewTransform = CGAffineTransformMakeRotation(-M_PI_2);
      itemTransform = CGAffineTransformMakeRotation(M_PI_2);
      bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
      break;
    case MCSFishEyeExpansionDirectionBottom:
      viewTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1.0, 1.0));
      itemTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(-M_PI_2), CGAffineTransformMakeScale(1.0, -1.0));
      bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
      break;
  }
  
  bounds.origin = CGPointZero;
  
  self.transformView.bounds = bounds;
  self.transformView.center = center;
  self.transformView.transform = viewTransform;
  self.itemTransform = itemTransform;
  
  [self layoutWithCurrentState];
}

- (void)recalculateDimensions
{
  switch (self.expansionDirection) {
    case MCSFishEyeExpansionDirectionRight:
    case MCSFishEyeExpansionDirectionLeft:
      self.transformedItemSize = self.itemSize;
      break;
    case MCSFishEyeExpansionDirectionTop:
    case MCSFishEyeExpansionDirectionBottom:
      self.transformedItemSize = CGSizeMake(self.itemSize.height, self.itemSize.width);
      break;
  }
  
  CGFloat totalHeight = self.transformView.bounds.size.height;
  CGFloat itemHeight = self.transformedItemSize.height;
  
  CGFloat collapsedItemHeight = MIN(totalHeight / self.items.count, itemHeight);
  self.collapsedItemHeight = collapsedItemHeight;
  self.collapsedItemScale = self.collapsedItemHeight / itemHeight;
  
  CGFloat expansionSurplus = 0.0;
  
  for (int i = -self.expansionsNeighbors - 1; i < self.expansionsNeighbors + 1; i++) {
    expansionSurplus += [self scaleForOffsetFromFocusPoint:i * collapsedItemHeight] * itemHeight - collapsedItemHeight;
  }
  
  if (collapsedItemHeight == itemHeight) {
    self.centeringOffset = (totalHeight - self.items.count * collapsedItemHeight)/2.0;
    self.startOffset = 0.0;
  } else {
    self.centeringOffset = 0.0;
    self.startOffset = expansionSurplus/2.0;
  }
}

- (CGFloat)offsetForIndex:(NSUInteger)index
{
  return (index + 0.5) * self.collapsedItemHeight + self.centeringOffset;
}

- (NSUInteger)indexForOffset:(CGFloat)offset
{
  NSInteger index = floorf((offset - self.centeringOffset)/self.collapsedItemHeight);
  
  return (index >= 0 && index < [self.items count]) ? index : NSNotFound;
}

- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset
{
  CGFloat normalizedOffset = fabsf(offset/self.collapsedItemHeight);
  CGFloat scalar = 0.0;
  
  if (normalizedOffset <= 0.5) {
    scalar = 1.0;
  } else if (normalizedOffset < (self.expansionsNeighbors + 0.5)) {
    scalar = ((self.expansionsNeighbors + 0.5) - normalizedOffset)/self.expansionsNeighbors;
  }
  
  CGFloat scaledHeight = self.transformedItemSize.height * scalar + self.collapsedItemHeight * (1.0 - scalar); //lerping
  return scaledHeight/self.transformedItemSize.height;
}

- (CGFloat)translationForOffsetFromFocusPoint:(CGFloat)offset
{
  if (!self.evadesFinger) {
    return 0.0f;
  }
  
  CGFloat normalizedOffset = fabsf(offset/self.collapsedItemHeight);
  CGFloat scalar = 0.0;
  
  const CGFloat NormalizedBottomRange = FingerTranslationRadius/self.collapsedItemHeight;
  
  if (normalizedOffset <= 0.5) {
    scalar = 1.0;
  } else if (normalizedOffset < NormalizedBottomRange) {
    scalar = 1.0 - (normalizedOffset - 0.5)/(NormalizedBottomRange - 0.5);
  }
  
  CGFloat val = scalar*scalar*(3.0 - 2.0*scalar); // ease in out on cubic curve
  

  return (FingerTranslation * val);
}

#pragma mark - Layout

- (void)layoutItemsForOffset:(CGFloat)offset withAnimationDuration:(NSTimeInterval)duration
{
  CGFloat expandedHeight = self.transformedItemSize.height;
  
  CGAffineTransform itemTransform = CGAffineTransformConcat(self.itemTransform,
                                                            CGAffineTransformMakeTranslation(self.transformedItemSize.width/2.0, 0.0)
                                                            );
  
  [UIView animateWithDuration:duration animations:^{
    NSEnumerationOptions options = 0;
    CGFloat sign = 1.0;
    __block CGFloat layoutOffset = -self.startOffset + self.centeringOffset;
    
    if (offset < (self.transformView.bounds.size.height)/2.0) {
      options = NSEnumerationReverse;
      sign = -1.0;
      layoutOffset = self.transformView.bounds.size.height + self.startOffset - self.centeringOffset;
    }
    
    [self.itemContainers enumerateObjectsWithOptions:options usingBlock:^(UIView *container, NSUInteger index, BOOL *stop) {
      CGFloat center = [self offsetForIndex:index];
      CGFloat distance = offset - center;

      CGFloat scale, tx, ty;
      
      if (self.state == MCSFishEyeStateExpandedPassive) {
        if (index != self.selectedIndex) {
          scale = self.collapsedItemScale;
          tx = 0.0;
        } else {
          scale = 1.0f;
          tx = self.selectedItemOffset;
        }
        ty = center;
      } else if (self.state == MCSFishEyeStateExpandedActive) {
        scale = [self scaleForOffsetFromFocusPoint:distance];
        tx = [self translationForOffsetFromFocusPoint:distance];
        ty = layoutOffset + sign * scale * expandedHeight * 0.5;
      } else {
        scale = self.collapsedItemScale;
        tx = 0.0f;
        ty = center;
      }
      
      container.transform = CGAffineTransformConcat(itemTransform, [self transformWithScale:scale translation:CGPointMake(tx, ty)]);
      layoutOffset += sign * scale * expandedHeight;
    }];
  }];
}

- (void)layoutWithCurrentState
{
  CGFloat offset = self.selectedIndex == NSNotFound ? 0.0f : [self offsetForIndex:self.selectedIndex];
  [self layoutItemsForOffset:offset withAnimationDuration:0.2];
}

#pragma mark - Convinience

- (void)collapseAnimated:(BOOL)animated notifying:(BOOL)shouldNotify
{
  self.state = MCSFishEyeStateCollapsed;
  [self layoutItemsForOffset:0.0 withAnimationDuration:animated ? 0.2 : 0.0];
  
  [self setHighlightedIndex:NSNotFound];
  [self setSelectedIndex:NSNotFound withDelegateCalls:YES animated:animated];
}

- (CGAffineTransform)transformWithScale:(CGFloat)scale translation:(CGPoint)translation
{
  CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
  CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translation.x, translation.y);
  
  return CGAffineTransformConcat(scaleTransform, translationTransform);
}

#pragma mark - Touch event handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  CGFloat offset = [self offsetFromTouchSet:touches];
  
  self.state = MCSFishEyeStateExpandedActive;
  
  [self layoutItemsForOffset:offset withAnimationDuration:0.2];
  [self setSelectedIndex:NSNotFound withDelegateCalls:YES animated:NO];
  [self setHighlightedIndex:[self indexForOffset:offset]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  CGFloat offset = [self offsetFromTouchSet:touches];
  
  [self layoutItemsForOffset:offset withAnimationDuration:0.07];
  [self setHighlightedIndex:[self indexForOffset:offset]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  CGFloat offset = [self offsetFromTouchSet:touches];
  NSUInteger index = [self indexForOffset:offset];
  
  if (index != NSNotFound) {
    [self setState:MCSFishEyeStateExpandedPassive];
    [self setHighlightedIndex:NSNotFound];
    [self setSelectedIndex:index withDelegateCalls:YES animated:YES];
    [self layoutItemsForOffset:offset withAnimationDuration:0.2];
  } else {
    [self collapseAnimated:YES notifying:YES];
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self collapseAnimated:YES notifying:YES];
}

- (CGFloat)offsetFromTouchSet:(NSSet *)touches
{
  UITouch *touch = [touches anyObject];
  return [touch locationInView:self.transformView].y;
}

@end
