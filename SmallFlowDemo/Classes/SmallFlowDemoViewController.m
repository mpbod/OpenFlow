//
//  SmallFlowDemoViewController.m
//  SmallFlowDemo
//
//  Created by Dirk on 19.08.09.
//  Copyright holtwick.it 2009. All rights reserved.
//

/* 
  
 TODO:
 
 - Images do not size to fit correctly in the small view
 - I need to react on a single tap at the current item to jump to a detail view
 - When nothing moves I need to display a 'play' button and a frame around the current item (image overlay)
 - When the element is put inside a table view it is very picky about horizontal and vertical movements
 
 */

#import "SmallFlowDemoViewController.h"

@implementation SmallFlowDemoViewController

@synthesize smallOpenFlowView = smallOpenFlowView_;
@synthesize titleLabel = titleLabel_;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load the sample images
    NSString *imageName;
    for (int i=0; i < 30; i++) {
        imageName = [[NSString alloc] initWithFormat:@"%d.jpg", i];
        [smallOpenFlowView_ setImage:[UIImage imageNamed:imageName] forIndex:i];
        [imageName release];
    }
    [smallOpenFlowView_ setNumberOfImages:30];   
    [smallOpenFlowView_ setViewDelegate:self];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc{
    [smallOpenFlowView_ release];
    [titleLabel_ release];
    [super dealloc];
}

// MARK: OpenFlowViewDelegate

- (void)openFlowView:(AFOpenFlowView *)openFlowView selectionDidChange:(int)index {
    // Set a title showing us which is the current cover shown
    [titleLabel_ setText:[NSString stringWithFormat:@"Item #%d", index]];
}

@end
