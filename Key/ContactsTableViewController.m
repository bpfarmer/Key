//
//  ContactsTableViewController.m
//  Key
//
//  Created by Loren on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KStorageManager.h"

static NSString *ContactsTableViewCellIdentifier = @"Contacts";

@interface ContactsTableViewController ()

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:ContactsTableViewCellIdentifier];
    
    /* Make sure our table view resizes correctly */
    self.tableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]){
        // Return the number of sections.
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]){
        switch (section){
            case 0:{
                // Returns number of contacts associated with current user's account, sets row count accordingly
                return [[KStorageManager sharedManager] numberOfKeysInCollection:[KUser collection]] -1;
                break;
            }
                
        }
        
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if ([tableView isEqual:self.tableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:ContactsTableViewCellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"Some Contact"];
    }
    
    return cell;
}

- (UILabel *) newLabelWithTitle:(NSString *)paramTitle{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = paramTitle;
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    return label;
}

- (UIView *) tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return [self newLabelWithTitle:@"Section 1 Header"];
    }
    return nil; }

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 0){
        return [self newLabelWithTitle:@"Section 1 Footer"];
    }
    return nil; }

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
