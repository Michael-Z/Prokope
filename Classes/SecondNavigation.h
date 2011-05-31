//
//  SecondNavigation.h
//  Prokope
//
//  Created by Justin Antranikian on 5/20/11.
//  Copyright 2011 Grand Valley State University. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SecondNavigation : UIViewController <UITableViewDelegate, UITableViewDataSource> {

	IBOutlet UITableView *SecondNavigationTableView;
	
	NSMutableArray *MySecondArray;
}

@property (nonatomic, retain) IBOutlet UITableView *SecondNavigationTableView;

-(void)SetSecondDataArray:(NSMutableArray *)dataArray;

@end
