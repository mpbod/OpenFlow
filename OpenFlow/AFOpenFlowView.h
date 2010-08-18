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
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "AFItemView.h"
#import "AFOpenFlowViewDelegate.h"
#import "AFOpenFlowViewDataSource.h"


@interface AFOpenFlowView : UIView {
	id <AFOpenFlowViewDataSource> dataSource;
	id <AFOpenFlowViewDelegate> viewDelegate;
	
	//Open Flow Configuration
	BOOL continousLoop; 
	CGFloat coverSpacing; 
	CGFloat centerCoverOffset; 
	CGFloat sideCoverAngle; 
	CGFloat sideCoverZPosition; 
	NSInteger coverBuffer; 
	CGFloat dragDivisor; 
	CGFloat reflectionFraction; 
	CGFloat coverHeightFraction; 
	CGFloat coverImageSize; 
	
	UIColor *backingColor;
	
	NSMutableSet *offScreenCovers;
	NSMutableDictionary *onScreenCovers;
	NSMutableDictionary	*coverImages;
	NSMutableDictionary	*coverImageHeights;
	UIImage	*defaultImage;
	CGFloat	defaultImageHeight;
    
	NSInteger numberOfImages;
	NSInteger beginningCover;
	
	AFItemView *selectedCoverView;
	
	CATransform3D leftTransform, rightTransform;
	
	Boolean isSingleTap;
	Boolean isDoubleTap;
	Boolean isDraggingACover;
	CGFloat startPosition;
	NSInteger selectedCoverAtDragStart; 
	CGFloat dragOffset; 
	CGPoint startPoint;
}

@property (nonatomic, assign) id <AFOpenFlowViewDataSource> dataSource;
@property (nonatomic, assign) id <AFOpenFlowViewDelegate> viewDelegate;

@property (nonatomic, assign) BOOL continousLoop; 
@property (nonatomic, assign) CGFloat coverSpacing; 
@property (nonatomic, assign) CGFloat centerCoverOffset; 
@property (nonatomic, assign) CGFloat sideCoverAngle; 
@property (nonatomic, assign) CGFloat sideCoverZPosition; 
@property (nonatomic, assign) NSInteger coverBuffer; 
@property (nonatomic, assign) CGFloat dragDivisor; 
@property (nonatomic, assign) CGFloat reflectionFraction; 
@property (nonatomic, assign) CGFloat coverHeightFraction; 
@property (nonatomic, assign) CGFloat coverImageSize; 

@property (nonatomic, retain) UIColor *backingColor; 

@property (nonatomic, retain) NSMutableSet *offScreenCovers;
@property (nonatomic, retain) NSMutableDictionary *onScreenCovers;
@property (nonatomic, retain) NSMutableDictionary *coverImages;
@property (nonatomic, retain) NSMutableDictionary *coverImageHeights;

@property (nonatomic, retain) UIImage *defaultImage;
@property NSInteger numberOfImages;
@property (nonatomic, retain) AFItemView *selectedCoverView;

- (void)reloadData; 
- (void)setSelectedCover:(NSInteger)newSelectedCover;
- (void)setImage:(UIImage *)image forIndex:(NSInteger)index;

@end