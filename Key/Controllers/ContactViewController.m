//
//  ContactViewController.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContactViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KMessage.h"
#import "CollapsingFutures.h"
#import "KPost.h"
#import "ProfileViewController.h"
#import "DatabaseDataSource.h"

@interface ContactViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic) KUser *currentUser;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentUser = [KAccountManager sharedManager].user;
    self.contactTextField.delegate = self;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [tapRec setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapRec];
    
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:[self tableData]
                                                                      cellIdentifier:[self cellIdentifier]
                                                                           tableView:self.contactsTableView
                                                                  configureCellBlock:[self configureCellBlock]
                                                                sectionCriteriaBlock:[self sectionCriteriaBlock]
                                                                           sortBlock:[self sortBlock]];
    [dataSource registerForUpdatesFromClasses:@[@"KUser"]];
    self.contactsTableView.dataSource = dataSource;
}

- (NSArray *)tableData {
    return [KUser all];
}

- (NSString *)cellIdentifier {
    return @"Cells";
}

- (NSComparisonResult (^)(KDatabaseObject*, KDatabaseObject*))sortBlock {
    return ^(KDatabaseObject *object1, KDatabaseObject *object2) {
        KUser *user1 = (KUser *)object1;
        KUser *user2 = (KUser *)object2;
        if([user1.uniqueId isEqualToString:self.currentUser.uniqueId]) {
            return NSOrderedAscending;
        }else if([user2.uniqueId isEqualToString:self.currentUser.uniqueId]) {
            return NSOrderedDescending;
        }else {
            return [user1.username compare:user2.username];
        }
    };
}

- (BOOL (^)(KDatabaseObject*, NSUInteger))sectionCriteriaBlock {
    return ^(KDatabaseObject *object, NSUInteger sectionId) {
        return [object isKindOfClass:[KUser class]];
    };
}

- (UITableViewCell* (^)(UITableViewCell*, KDatabaseObject*))configureCellBlock {
    return ^(UITableViewCell *cell, KDatabaseObject *object) {
        
        return cell;
    };
}

- (IBAction)addContact:(id)sender {
    if(![self.contactTextField.text isEqualToString:@""] && ![self.contactTextField.text isEqualToString:self.currentUser.username]) {
        KUser *targetUser = [KUser findByDictionary:@{@"username" : [self.contactTextField.text lowercaseString]}];
        if(!targetUser) {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUsername:[self.contactTextField.text lowercaseString]];
            
            [futureUser catchDo:^(id failure) {
                NSLog(@"ERROR: %@", failure);
            }];
        }
        self.contactTextField.text = @"";
    }
}

@end
