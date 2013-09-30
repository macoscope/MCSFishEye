MCSFishEyeView
==========

The fisheye from our [Bubble Browser](http://bubblebrowserapp.com) for iPad.

[![](https://raw.github.com/macoscope/MCSFisheye/master/Screens/fishEye.gif)](https://raw.github.com/macoscope/MCSFisheye/master/Screens/fishEye.gif)


## How To Use

Checkout demo project for some real life action!

### Instantiating

Setup a `dataSource`, an optional `delegate`, add subview and you're done

```
MCSFishEyeView *fisheye = [[MCSFishEyeView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 600.0f)];  
fisheye.dataSource = self;
fisheye.delegate = self;
[self.view addSubview:fisheye];
```

### Items

`MCSFishEyeView` has the notion of items, which are more or less similar to table view cells. Each item should be a subclass of `MCSFishEyeViewItem`, as it already provides convinent methods for setting `highlighted` and `selected` state. You register a class to `MCSFishEyeView` by this one-liner:

```
[fisheye registerItemClass:[MCSExampleFishEyeItem class]];
```
Inside your custom `MCSFishEyeViewItem` subclass you are free to do whatever you want in both
 
 `- (void)setSelected:(BOOL)selected animated:(BOOL)animated` 
 
and

`- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated`

methods, just make sure you call `super` (don't worry, compiler will warn you if you forget to do so).

### States

`MCSFishEyeView` has three different states:



- `MCSFishEyeStateCollapsed` - in this state all the items are collapsed, no item is `highlighted` or `selected`

	 [![](https://raw.github.com/macoscope/MCSFisheye/master/Screens/collapsed.png)](https://raw.github.com/macoscope/MCSFisheye/master/Screens/collapsed.png)

- `MCSFishEyeStateExpandedActive` - items are moving around according to touch location, at most one element is `highlighted`, no elements are `selected`

	 [![](https://raw.github.com/macoscope/MCSFisheye/master/Screens/highlighted.png)](https://raw.github.com/macoscope/MCSFisheye/master/Screens/highlighted.png)
 
- `MCSFishEyeStateExpandedPassive` - in this state a single item is standing out in `selected` state, all the other items are collapsed

 	[![](https://raw.github.com/macoscope/MCSFisheye/master/Screens/selected.png)](https://raw.github.com/macoscope/MCSFisheye/master/Screens/selected.png)


## Detailed explenation

For more detailed description of how `MCSFishEye` works checkout this post on our blog!


## Requirements

- iOS 5.0
- ARC
- QuartzCore framework in your project


## Contact

[Macoscope](http://macoscope.com)

## License

MCSFishEye is released under an MIT license.

Copyright 2013 Macoscope, sp z o.o.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

