//
//  KTableViewController.m
//  Key
//
//  Created by Brendan Farmer on 8/24/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KTableViewController.h"
#import "SubtitleTableViewCell.h"
#import "KDatabaseObject.h"
#import "KPost.h"

@interface KTableViewController ()
@end

@implementation KTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
    self.tableView.allowsMultipleSelection = YES;
    [self.tableView registerClass:[SubtitleTableViewCell class] forCellReuseIdentifier:[self cellIdentifier]];
    self.sectionData = [self loadTableViewData];
}

+ (dispatch_queue_t)sharedQueue {
    static dispatch_once_t pred;
    static dispatch_queue_t sharedDispatchQueue;
    
    dispatch_once(&pred, ^{
        sharedDispatchQueue = dispatch_queue_create("KTableViewQueue", NULL);
    });
    
    return sharedDispatchQueue;
}

- (NSArray *)loadTableViewData {
    NSMutableArray *newSectionData = [NSMutableArray new];
    for(NSDictionary *sectionDictionary in [self.sectionCriteria objectEnumerator]) {
        if([sectionDictionary objectForKey:@"criteria"]) {
            [newSectionData addObject:[NSClassFromString(sectionDictionary[@"class"]) findAllByDictionary:sectionDictionary[@"criteria"] orderBy:self.sortedByProperty descending:self.sortDescending]];
        }else if([sectionDictionary objectForKey:@"where"] && [sectionDictionary objectForKey:@"parameters"]) {
            [newSectionData addObject:[NSClassFromString(sectionDictionary[@"class"]) findAllWhere:sectionDictionary[@"where"] parameters:sectionDictionary[@"parameters"]]];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[NSClassFromString(sectionDictionary[@"class"]) notificationChannel] object:nil];
    };
    return [self modifySectionData:newSectionData];
}

- (NSArray *)modifySectionData:(NSArray *)sectionData {
    return sectionData;
}

- (BOOL)object:(KDatabaseObject *)object matchesCriteriaforSection:(NSUInteger)sectionId {
    NSDictionary *sectionDictionary = self.sectionCriteria[sectionId];
    if(![object isKindOfClass:NSClassFromString(sectionDictionary[@"class"])]) return NO;
    NSDictionary *criteriaDictionary = (NSDictionary *)sectionDictionary[@"criteria"];
    __block BOOL matchesCriteria = YES;
    [criteriaDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(![[object valueForKey:key] isEqual:obj]) {
            matchesCriteria = NO;
            *stop = YES;
        }
    }];
    return matchesCriteria;
}

- (void)databaseModified:(NSNotification *)notification {
    dispatch_async([self.class sharedQueue], ^{
        KDatabaseObject *object = (KDatabaseObject *)notification.object;
        [self.sectionCriteria enumerateObjectsUsingBlock:^(id obj, NSUInteger sectionId, BOOL *stop) {
            if([self object:object matchesCriteriaforSection:sectionId]) {
                NSInteger oldCellId = [self currentCellIdInSectionId:sectionId object:object];
                NSInteger newCellId = [self destinationCellIdInSectionId:sectionId object:object];
                self.sectionData = [self newDataForSectionId:sectionId oldCellId:oldCellId newCellId:newCellId object:object];
                newCellId = [((NSArray *)self.sectionData[sectionId]) indexOfObject:object];
                dispatch_async(dispatch_get_main_queue(), ^{
                    while(self.tableView.numberOfSections <= sectionId) [self.tableView insertSections:[NSIndexSet indexSetWithIndex:self.tableView.numberOfSections] withRowAnimation:UITableViewRowAnimationAutomatic];
                    if(oldCellId != -1) {
                        if(oldCellId != newCellId) {
                            [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:oldCellId inSection:sectionId] toIndexPath:[NSIndexPath indexPathForRow:newCellId inSection:sectionId]];
                            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newCellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }else {
                            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldCellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }else {
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newCellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                });
            }
        }];
    });
}

- (NSArray *)newDataForSectionId:(NSUInteger)sectionId oldCellId:(NSInteger)oldCellId newCellId:(NSInteger)newCellId object:(KDatabaseObject *)object {
    NSMutableArray *updatedData  = [[NSMutableArray alloc] initWithArray:self.sectionData];
    NSMutableArray *updatedCells = [[NSMutableArray alloc] initWithArray:self.sectionData[sectionId]];
    if(oldCellId != -1) {
        [updatedCells removeObjectAtIndex:oldCellId];
    }
    if(newCellId != -1) [updatedCells insertObject:object atIndex:newCellId];
    else {
        [updatedCells addObject:object];
        newCellId = [updatedCells indexOfObject:object];
    }
    [updatedData replaceObjectAtIndex:sectionId withObject:updatedCells];
    return [updatedData copy];
}

- (NSInteger)destinationCellIdInSectionId:(NSUInteger)sectionId object:(KDatabaseObject *)object {
    __block NSInteger newCellId = -1;
    if(self.sortedByProperty) {
        [self.sectionData[sectionId] enumerateObjectsUsingBlock:^(id cell, NSUInteger replaceCellId, BOOL *stop) {
            KDatabaseObject *compareObject = (KDatabaseObject *)cell;
            if(self.sortDescending) {
                if([KDatabaseObject compareProperty:self.sortedByProperty object1:object object2:compareObject]) {
                    newCellId = replaceCellId;
                    *stop = YES;
                }
            }else {
                if(![KDatabaseObject compareProperty:self.sortedByProperty object1:object object2:compareObject]) {
                    newCellId = replaceCellId;
                    *stop = YES;
                }
            }
        }];
    }
    return newCellId;
}

- (NSInteger)currentCellIdInSectionId:(NSUInteger)sectionId object:(KDatabaseObject *)object {
    __block NSInteger updatedIndex = -1;
    [((NSArray *)self.sectionData[sectionId]) enumerateObjectsUsingBlock:^(id obj, NSUInteger cellId, BOOL *stop) {
        KDatabaseObject *currentObject = (KDatabaseObject *)obj;
        if([object.uniqueId isEqualToString:currentObject.uniqueId]) {
            updatedIndex = cellId;
            *stop = YES;
        }
    }];
    return updatedIndex;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)self.sectionData[section]).count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSObject *)objectForIndexPath:(NSIndexPath *)indexPath {
    return ((NSArray *)self.sectionData[indexPath.section])[indexPath.row];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)cellIdentifier {
    return @"Cells";
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
