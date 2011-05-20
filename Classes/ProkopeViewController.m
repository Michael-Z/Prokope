//
//  ProkopeViewController.m
//  Prokope
//
//  Created by D. Robert Adams on 5/9/11.
//  Copyright 2011 Grand Valley State University. All rights reserved.
//

#import "DocumentController.h"
#import "ProkopeViewController.h"
#import "SecondNavigation.h"

@implementation ProkopeViewController

@synthesize ProkopeTableView;

/******************************************************************************
 * Handles the event of the user wanting to display a document. Loads the
 * DocumentController and displays it.
 */
- (void) showDocument 
{
	[super viewDidLoad];
	
	// Load the document controller nib display it.
	DocumentController *docController = [[DocumentController alloc] 
										 initWithNibName:@"DocumentController" bundle:nil];
	[self presentModalViewController:docController animated:YES];
	
	[docController release];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [myArrayData count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// The only line of code I added in this method - fyi. It populates the cells with the contents of the array
    cell.textLabel.text = [myArrayData objectAtIndex:indexPath.row];
	
    return cell;
}

// This method repsonds to the touch on an item in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[ProkopeTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SecondNavigation *secondNav = [[SecondNavigation alloc] initWithNibName:@"SecondNavigation" bundle:nil];
	[secondNav setTitle:[myArrayData objectAtIndex:indexPath.row]];
	
	[self.navigationController pushViewController:secondNav animated:YES];
	[secondNav release];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(void)viewDidLoad
{
	self.title = @"Home Page";
	[super viewDidLoad];
		
	ProkopeTableView.delegate = self;
	ProkopeTableView.dataSource = self;
		
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
		
	myArrayData = [[NSMutableArray alloc] initWithObjects: @"Ceasar", @"Ciscero", @"Plato", @"Aristole", nil];
}



- (void)dealloc {
    [super dealloc];
}

@end
