//
//  ContactTableViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContactTableViewController.h"
#import "KUser.h"

#define REFRESH_TIMEOUT 20

static NSString *const CONTACT_BROWSE_TABLE_CELL_IDENTIFIER = @"ContactTableViewCell";

@interface ContactTableViewController () <UISearchBarDelegate, UISearchResultsUpdating> {
    NSDictionary *latestAlphabeticalContacts;
    NSArray *searchResults;
}

@property (nonatomic, strong) UILabel *emptyViewLabel;
@property NSArray *latestSortedAlphabeticalContactKeys;
@property NSArray *latestContacts;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation ContactTableViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeObservers];
    [self initializeRefreshControl];
    [self initializeTableView];
    [self initializeSearch];
    [self setupContacts];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initializers

- (void)initializeSearch {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
}

- (void)initializeRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(refreshContacts) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.contactTableView addSubview:self.refreshControl];
}

-(void)initializeTableView {
    self.tableView.contentOffset = CGPointMake(0, 44);
    //self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)initializeObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactsDidRefresh) name:@"NOTIFICATION_DIRECTORY_WAS_UPDATED" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactRefreshFailed) name:@"NOTIFICATION_DIRECTORY_FAILED" object:nil];
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    [self filterContentForSearchText:searchString scope:nil];
    [self.tableView reloadData];
}


#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark - Filter

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    NSPredicate *numberPredicate = [NSPredicate predicateWithFormat:@"ANY SELF.username contains[cd] %@ OR fullName contains[c] %@", searchText, searchText];
    
    searchResults = [self.latestContacts filteredArrayUsingPredicate:numberPredicate];
    if (!searchResults.count && _searchController.searchBar.text.length == 0) {
        searchResults = self.latestContacts;
    }
}

#pragma mark - Contact functions

- (void)setupContacts {
//    ObservableValue *observableContacts = [KUser getUsers];
//    [observableContacts watchLatestValue:^(NSArray *latestContacts) {
//        _latestContacts = latestContacts;
//        [self onSearchOrContactChange:nil];
//    } onThread:NSThread.mainThread untilCancelled:nil];
}

- (NSArray *)contactsForSectionIndex:(NSUInteger)index {
    return [latestAlphabeticalContacts valueForKey:self.latestSortedAlphabeticalContactKeys[index]];
}

-(NSMutableDictionary*)alphabetDictionaryInit {
    NSDictionary * dic;
    
    dic = @{
            @"A": @[], @"B": @[], @"C": @[],
            @"D": @[], @"E": @[], @"F": @[],
            @"G": @[], @"H": @[], @"I": @[],
            @"J": @[], @"K": @[], @"L": @[],
            @"M": @[], @"N": @[], @"O": @[],
            @"P": @[], @"Q": @[], @"R": @[],
            @"S": @[], @"T": @[], @"U": @[],
            @"V": @[], @"W": @[], @"X": @[],
            @"Y": @[], @"Z": @[]
            };
    
    return [dic mutableCopy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
