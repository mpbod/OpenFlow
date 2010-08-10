/**
 * Copyright (c) 2009 Alex Fajkowski, Apparent Logic LLC
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
#import "AFOpenFlowView.h"
#import "AFOpenFlowConstants.h"
#import "AFUIImageReflection.h"



@interface AFOpenFlowView (hidden)

- (void)resetDataState;
- (void)setUpInitialState;
- (AFItemView *)coverForIndex:(NSInteger)coverIndex;
- (void)updateCoverImage:(AFItemView *)aCover;
- (AFItemView *)dequeueReusableCover;
- (void)layoutCovers:(int)selected fromCover:(NSInteger)lowerBound toCover:(NSInteger)upperBound;
- (void)layoutCover:(AFItemView *)aCover 
		 inPosition:(NSInteger)position 
	  selectedCover:(NSInteger)selectedIndex 
		   animated:(Boolean)animated;
- (AFItemView *)findCoverOnscreen:(CALayer *)targetLayer;

@end

@implementation AFOpenFlowView

const static CGFloat kReflectionFraction = REFLECTION_FRACTION;

@synthesize dataSource; 
@synthesize viewDelegate;
@synthesize continousLoop; 

@synthesize numberOfImages; 
@synthesize defaultImage;
@synthesize selectedCoverView;

@synthesize offScreenCovers;
@synthesize onScreenCovers;
@synthesize coverImages;
@synthesize coverImageHeights;

#pragma mark Utility Methods 

NS_INLINE NSRange NSMakeRangeToIndex(NSUInteger loc, NSUInteger loc2) {
    NSRange r;
    r.location = loc;
    r.length = loc2 + 1 - loc;
    return r;
}

- (void)dealloc {
	self.dataSource = nil; 
	self.viewDelegate = nil; 
	self.defaultImage = nil; 
	self.selectedCoverView = nil; 
	
	self.offScreenCovers = nil; 
	self.onScreenCovers = nil;
	self.coverImages = nil; 
	self.coverImageHeights = nil; 
	
	//[flipViewShown release];
	
	[super dealloc];
}

#pragma mark Accessor 

- (void) setDataSource:(id <AFOpenFlowViewDataSource>)ds {
	if (ds != dataSource) {
		[ds retain]; 
		[dataSource release];
		dataSource = ds; 
		[self reloadData];
	}
	
	//not sure why the layer is being left on the screen temp fix. 
	for (UIView *view in self.subviews) {
		if ([view isKindOfClass:[AFItemView class]]) {
			if (view.frame.origin.x + view.frame.size.width > 10.0) {
				view.frame = CGRectZero;
			}
		}
	}
}

#pragma mark Hidden Implementation details

- (void)resetDataState {
	// Set up the default image for the coverflow.
	self.defaultImage = [self.dataSource defaultImage];
	
	// Create data holders for onscreen & offscreen covers & UIImage objects.
	self.coverImages = [[[NSMutableDictionary alloc] init] autorelease];
	self.coverImageHeights = [[[NSMutableDictionary alloc] init] autorelease];
	
	if (self.offScreenCovers == nil) {
		self.offScreenCovers = [[[NSMutableSet alloc] init] autorelease];
	}
	
	if (self.onScreenCovers == nil) {
		self.onScreenCovers = [[[NSMutableDictionary alloc] init] autorelease];
	} else {
		for (AFItemView *cover in [self.onScreenCovers allValues]) {
			[cover removeFromSuperview]; 
			[self.offScreenCovers addObject:cover];
		}
		[self.onScreenCovers removeAllObjects];
	}
		
	
}

- (void)setUpInitialState {
	[self resetDataState]; 
	
	self.multipleTouchEnabled = NO;
	self.userInteractionEnabled = YES;
	self.autoresizesSubviews = YES;
	self.layer.position = CGPointMake(self.frame.origin.x + self.frame.size.width / 2, 
									  self.frame.origin.y + self.frame.size.height / 2);
	
	// Initialize the visible and selected cover range.
	selectedCoverView = nil;
	
	// Set up the cover's left & right transforms.
	leftTransform = CATransform3DIdentity;
	leftTransform = CATransform3DRotate(leftTransform, SIDE_COVER_ANGLE, 0.0f, 1.0f, 0.0f);
	rightTransform = CATransform3DIdentity;
	rightTransform = CATransform3DRotate(rightTransform, SIDE_COVER_ANGLE, 0.0f, -1.0f, 0.0f);
	
	// Set some perspective
	CATransform3D sublayerTransform = CATransform3DIdentity;
	sublayerTransform.m34 = -0.01;
	[self.layer setSublayerTransform:sublayerTransform];
	
	[self setBounds:self.frame];
}

- (AFItemView *)coverForIndex:(NSInteger)coverIndex {
	AFItemView *coverView = [self dequeueReusableCover];
	NSLog(@"Creating cover %d", coverIndex);
	if (!coverView) {
		coverView = [[[AFItemView alloc] initWithFrame:CGRectZero] autorelease];
	}
	
	coverView.backgroundColor = self.backgroundColor;
	coverView.number = coverIndex;
	return coverView;
}

- (void)updateCoverImage:(AFItemView *)aCover {
	NSLog(@"Updating Cover image: %d", aCover.number);
	NSNumber *coverNumber = [NSNumber numberWithInt:aCover.number];
	UIImage *coverImage = (UIImage *)[coverImages objectForKey:coverNumber];
	if (coverImage) {
		NSNumber *coverImageHeightNumber = (NSNumber *)[coverImageHeights objectForKey:coverNumber];
		if (coverImageHeightNumber) {
			[aCover setImage:coverImage originalImageHeight:[coverImageHeightNumber floatValue] reflectionFraction:kReflectionFraction];
		}
	} else {
		[aCover setImage:defaultImage originalImageHeight:defaultImageHeight reflectionFraction:kReflectionFraction];
		[self.dataSource openFlowView:self requestImageForIndex:aCover.number];
	}
}

#pragma mark Cover Layout Code!

- (void)layoutCovers:(NSInteger)selected fromCover:(NSInteger)lowerBound toCover:(NSInteger)upperBound {
	AFItemView *cover;
	NSNumber *coverNumber;
	for (NSInteger i = lowerBound; i <= upperBound; i++) {
		if (i < 0) {
			coverNumber = [NSNumber numberWithInt:i + [onScreenCovers count]];
		} else if (i > [onScreenCovers count] - 1) {
			coverNumber = [NSNumber numberWithInt:i - [onScreenCovers count]];
		} else {
			coverNumber = [NSNumber numberWithInt:i];
		}
		
		cover = (AFItemView *)[onScreenCovers objectForKey:coverNumber];
		[self layoutCover:cover inPosition:i selectedCover:selected animated:YES];
	}
}

- (void)layoutCover:(AFItemView *)aCover 
		 inPosition:(NSInteger)position 
	  selectedCover:(NSInteger)selectedIndex 
		   animated:(Boolean)animated {
	
	CATransform3D newTransform;
	CGFloat newZPosition = SIDE_COVER_ZPOSITION;
	CGPoint newPosition;
	
	newPosition.x = (self.bounds.size.width / 2) + dragOffset;
	newPosition.y = (self.bounds.size.height / 2) + aCover.verticalPosition;
	
	NSInteger numberFromCover = position - selectedIndex; 
	NSLog(@"Laying out cover %d in slot %d", aCover.number, numberFromCover);
	newPosition.x += numberFromCover * CENTER_COVER_OFFSET; 
	
	if (position < selectedIndex) {
		newTransform = leftTransform; 
	} else if (selectedIndex < position) {
		newTransform = rightTransform;
	} else {
		newZPosition = 0;
		newTransform = CATransform3DIdentity;
	}
	
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	
	NSLog(@"New position (%d): %0.1f:%0.1f:%0.1f", aCover.number ,newPosition.x, newPosition.y, newZPosition);
	
	aCover.opaque = NO; 
	aCover.layer.transform = newTransform;
	aCover.layer.zPosition = newZPosition;
	aCover.layer.position = newPosition;
	
	if (animated) {
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(layoutCoverAnimationDidStop:finished:context:)];
		[UIView commitAnimations];
	}
}


- (AFItemView *)dequeueReusableCover {
	AFItemView *aCover = [offScreenCovers anyObject];
	if (aCover) {
		[[aCover retain] autorelease];
		[offScreenCovers removeObject:aCover];
	}
	return aCover;
}

- (AFItemView *)findCoverOnscreen:(CALayer *)targetLayer {
	// See if this layer is one of our covers.
	NSEnumerator *coverEnumerator = [onScreenCovers objectEnumerator];
	AFItemView *aCover = nil;
	
	while (aCover = (AFItemView *)[coverEnumerator nextObject]) {
		if ([[aCover.imageView layer] isEqual:targetLayer]) {
			return aCover;
		}
	}
	
	return nil; 
}

#pragma mark View Management 

- (void)awakeFromNib {
	
	[self setUpInitialState];
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setUpInitialState];
	}
	
	return self;
}

- (void) layoutSubviews {	
	if (self.continousLoop) {
		[self layoutCovers:self.selectedCoverView.number 
				 fromCover:self.selectedCoverView.number - COVER_BUFFER 
				   toCover:self.selectedCoverView.number + COVER_BUFFER];
	} else {
		NSInteger lowerBound = MAX(0, self.selectedCoverView.number - COVER_BUFFER);
		NSInteger upperBound = MIN(self.numberOfImages - 1, self.selectedCoverView.number + COVER_BUFFER);
		[self layoutCovers:self.selectedCoverView.number fromCover:lowerBound toCover:upperBound];	
	}
	
	int i = 0; 
	for (CALayer *layer in [self.layer sublayers]) {
		NSLog(@"%d Sub Layers - %0.0f:%0.0f:%0.0f", i++, layer.position.x, layer.position.y, layer.zPosition);
	}
}	

- (void)setNumberOfImages:(NSInteger)newNumberOfImages {
	numberOfImages = newNumberOfImages;

	NSInteger lowerBound = MAX(0, selectedCoverView.number - COVER_BUFFER);
	NSInteger upperBound = MIN(self.numberOfImages - 1, selectedCoverView.number + COVER_BUFFER);
	
	if (selectedCoverView) {
		[self layoutCovers:selectedCoverView.number fromCover:lowerBound toCover:upperBound];
	} else {
		[self setSelectedCover:0];
	}
}

- (void)setDefaultImage:(UIImage *)newDefaultImage {
	[defaultImage release];
	defaultImageHeight = newDefaultImage.size.height;
	defaultImage = [[newDefaultImage addImageReflection:kReflectionFraction] retain];
}

- (void)setImage:(UIImage *)image forIndex:(NSInteger)index {
	// Create a reflection for this image.
	UIImage *imageWithReflection = [image addImageReflection:kReflectionFraction];
	NSNumber *coverNumber = [NSNumber numberWithInt:index];
	[coverImages setObject:imageWithReflection forKey:coverNumber];
	[coverImageHeights setObject:[NSNumber numberWithFloat:image.size.height] forKey:coverNumber];
	
	// If this cover is onscreen, set its image and call layoutCover.
	AFItemView *aCover = (AFItemView *)[onScreenCovers objectForKey:[NSNumber numberWithInt:index]];
	if (aCover) {
		[aCover setImage:imageWithReflection originalImageHeight:image.size.height reflectionFraction:kReflectionFraction];
		[self layoutCover:aCover inPosition:aCover.number selectedCover:selectedCoverView.number animated:NO];
	}
}

#pragma mark Touch management 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	startPoint = [[touches anyObject] locationInView:self];
	
	isDraggingACover = NO;
	
	// Which cover did the user tap?
	CALayer *targetLayer = (CALayer *)[self.layer hitTest:startPoint];
	AFItemView *targetCover = [self findCoverOnscreen:targetLayer];
	isDraggingACover = (targetCover != nil);

	beginningCover = selectedCoverView.number;

	isSingleTap = ([touches count] == 1);
	
	selectedCoverAtDragStart = selectedCoverView.number;

    if ([self.viewDelegate respondsToSelector:@selector(openFlowViewScrollingDidBegin:)]) {
        [self.viewDelegate openFlowViewScrollingDidBegin:self];
	}
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	isSingleTap = NO;
	isDoubleTap = NO;
	
	CGPoint movedPoint = [[touches anyObject] locationInView:self];
	dragOffset = (movedPoint.x - startPoint.x);  // / DRAG_DIVISOR; //Ignore the drag divisor for the moment. 

	NSInteger newCoverDiff = (dragOffset * -1) / COVER_SPACING;
	
	dragOffset = dragOffset + (newCoverDiff * COVER_SPACING); 
	
	if (newCoverDiff != 0) { 
		NSInteger newSelectedCover = selectedCoverAtDragStart + newCoverDiff;//TODO: Calculate from the original cover selected!
		if (newSelectedCover < 0) {
			[self setSelectedCover:0];
		} else if (newSelectedCover >= self.numberOfImages) {
			[self setSelectedCover:self.numberOfImages - 1];
		} else {
			[self setSelectedCover:newSelectedCover];
		}
	}
	
	//NEED to move the covers. 
	[self layoutSubviews];
	
    if ([self.viewDelegate respondsToSelector:@selector(openFlowViewAnimationDidBegin:)]) {
        [self.viewDelegate openFlowViewAnimationDidBegin:self];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	dragOffset = 0.0; 

	if (isSingleTap) {
		// Which cover did the user tap?
		CGPoint targetPoint = [[touches anyObject] locationInView:self];
		CALayer *targetLayer = (CALayer *)[self.layer hitTest:targetPoint];
		AFItemView *targetCover = [self findCoverOnscreen:targetLayer];
		if (targetCover && (targetCover.number != selectedCoverView.number)) {
			[self setSelectedCover:targetCover.number];
		}
	}
	
	// And send the delegate the newly selected cover message.
	if (beginningCover == selectedCoverView.number) {
        // Tap?
        if([[event allTouches] count]==1) {
            UITouch *touch = [[event allTouches] anyObject];    
            if ([touch tapCount] == 1) {
                if ([self.viewDelegate respondsToSelector:@selector(openFlowView:didTap:)])
                    [self.viewDelegate openFlowView:self didTap:selectedCoverView.number];
            } else if ([touch tapCount] == 2) {
                if ([self.viewDelegate respondsToSelector:@selector(openFlowView:didDoubleTap:)])
                    [self.viewDelegate openFlowView:self didDoubleTap:selectedCoverView.number];            
            }   
            
        }    
    } else {
		if ([self.viewDelegate respondsToSelector:@selector(openFlowView:selectionDidChange:)])
			[self.viewDelegate openFlowView:self selectionDidChange:selectedCoverView.number];
    }
	
	[self layoutSubviews];
	
    // End of scrolling 
    if ([self.viewDelegate respondsToSelector:@selector(openFlowViewScrollingDidEnd:)])
        [self.viewDelegate openFlowViewScrollingDidEnd:self];    
}

- (void)reloadData {
	[self resetDataState];
	self.numberOfImages = [self.dataSource numberOfImagesInOpenView:self];
}

- (NSIndexSet *) coverIndexForSelectedCoverIndex:(NSInteger)selectedCoverIndex {
	NSMutableIndexSet *onScreenCoversIndex; 
	
	if (self.continousLoop) {
		if (selectedCoverIndex - COVER_BUFFER < 0 && self.numberOfImages < selectedCoverIndex + COVER_BUFFER + 1) {
			onScreenCoversIndex = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfImages - 1)];
		} else {
			if (selectedCoverView.number - COVER_BUFFER < 0) {
				onScreenCoversIndex = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 
																								selectedCoverIndex + COVER_BUFFER + 1)];
	
				[onScreenCoversIndex addIndexesInRange:NSMakeRangeToIndex(self.numberOfImages + selectedCoverView.number - COVER_BUFFER, self.numberOfImages - 1)]; //Covers at the end for loop 
				
			} else if (self.numberOfImages < selectedCoverView.number + COVER_BUFFER + 1) {
				onScreenCoversIndex = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRangeToIndex(selectedCoverIndex - COVER_BUFFER, 
																								self.numberOfImages - 1)];
				[onScreenCoversIndex addIndexesInRange:NSMakeRange(0, selectedCoverIndex + COVER_BUFFER - self.numberOfImages)]; //Covers at the start for loop
		
			} else {
				onScreenCoversIndex = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRangeToIndex(selectedCoverIndex - COVER_BUFFER, 
																								selectedCoverIndex + COVER_BUFFER + 1)];
			}
		}
	} else {
		onScreenCoversIndex = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRangeToIndex(MAX(0, selectedCoverIndex - COVER_BUFFER), 
																						MIN(self.numberOfImages - 1, selectedCoverIndex + COVER_BUFFER))];
	}	
	return onScreenCoversIndex; 
}

- (void)setSelectedCover:(NSInteger)newSelectedCover {
	//Don't do anything if the currently selectedCover is the newSelectedCover. 
	if (selectedCoverView && (newSelectedCover == selectedCoverView.number)) {
		return;
	}
	
	NSIndexSet *onScreenCoversIndex = [self coverIndexForSelectedCoverIndex:newSelectedCover]; 
	
	for (AFItemView *cover in [self.onScreenCovers allValues]) {	//TODO: iOS4.0 enumerateKeysAndObjectsUsingBlock:
		if (! [onScreenCoversIndex containsIndex:cover.number]) {
			[self.offScreenCovers addObject:cover];
			[cover.layer removeFromSuperlayer];
			[cover removeFromSuperview];
			[self.onScreenCovers removeObjectForKey:[NSNumber numberWithInt:cover.number]];
		}
	}

	for (NSInteger i = 0; i < self.numberOfImages; i++) { 
		//Check to see if the cover is already in the covers list
		if ([onScreenCoversIndex containsIndex:i]) { //TODO: Implement using enumerateIndexesUsingBlock: iOS 4.0 only!
			//Add to screen. 
			AFItemView *cover = [onScreenCovers objectForKey:[NSNumber numberWithInt:i]];
			if (cover == nil) {
				cover = [self coverForIndex:i];;
				[onScreenCovers setObject:cover forKey:[NSNumber numberWithInt:i]];
			}
			[self updateCoverImage:cover];
			[self.layer addSublayer:cover.layer];
		}
	}
	
	self.selectedCoverView = [onScreenCovers objectForKey:[NSNumber numberWithInt:newSelectedCover]];
	
	[self layoutSubviews];
}


- (void)layoutCoverAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([self.viewDelegate respondsToSelector:@selector(openFlowViewAnimationDidEnd:)]) {
        [self.viewDelegate openFlowViewAnimationDidEnd:self];    
	}
}

- (void)dismissFlippedAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	// Same as layoutCoverAnimationDidStop: for now
    if ([self.viewDelegate respondsToSelector:@selector(openFlowViewAnimationDidEnd:)]) {
        [self.viewDelegate openFlowViewAnimationDidEnd:self];    
	}
}


@end