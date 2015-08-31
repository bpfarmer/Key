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
    
    dispatch_async([self.class sharedQueue], ^{
        NSMutableArray *newSectionData = [NSMutableArray new];
        NSEnumerator *sectionCriteriaEnumerator = [self.sectionCriteria objectEnumerator];
        for(NSDictionary *sectionDictionary in sectionCriteriaEnumerator) {
            [newSectionData addObject:[NSClassFromString(sectionDictionary[@"class"]) findAllByDictionary:sectionDictionary[@"criteria"] orderBy:self.sortedByProperty descending:self.sortDescending]];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[NSClassFromString(sectionDictionary[@"class"]) notificationChannel] object:nil];
        };
        self.sectionData = [self modifySectionData:[newSectionData copy]];
    });
}

+ (dispatch_queue_t)sharedQueue {
    static dispatch_once_t pred;
    static dispatch_queue_t sharedDispatchQueue;
    
    dispatch_once(&pred, ^{
        sharedDispatchQueue = dispatch_queue_create("KTableViewQueue", NULL);
    });
    
    return sharedDispatchQueue;
}

- (NSArray *)modifySectionData:(NSArray *)sectionData {
    return sectionData;
}

- (void)databaseModified:(NSNotification *)notification {
    NSLog(@"NEW OBJECT: %@", notification.object);
    NSLog(@"CURRENT OBJECTS: %@", self.sectionData);
    dispatch_async([self.class sharedQueue], ^{
        KDatabaseObject *object = (KDatabaseObject *)notification.object;
        [self.sectionCriteria enumerateObjectsUsingBlock:^(id obj, NSUInteger sectionId, BOOL *stop) {
            NSDictionary *sectionDictionary = (NSDictionary *)obj;
            NSDictionary *criteriaDictionary = (NSDictionary *)sectionDictionary[@"criteria"];
            if([object isKindOfClass:NSClassFromString(sectionDictionary[@"class"])]) {
                __block BOOL matchesCriteria = YES;
                [criteriaDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if(![[object valueForKey:key] isEqual:obj]) {
                        matchesCriteria = NO;
                        *stop = YES;
                    }
                }];
                if(matchesCriteria) {
                    __block NSUInteger updatedIndex = -1;
                    [(NSArray *)self.sectionData[sectionId] enumerateObjectsUsingBlock:^(id obj, NSUInteger cellId, BOOL *stop) {
                        KDatabaseObject *currentObject = (KDatabaseObject *)obj;
                        if([object.uniqueId isEqualToString:currentObject.uniqueId]) {
                            updatedIndex = cellId;
                            *stop = YES;
                        }
                    }];
                    
                    NSMutableArray *updatedData  = [[NSMutableArray alloc] initWithArray:self.sectionData];
                    NSMutableArray *updatedCells = [[NSMutableArray alloc] initWithArray:self.sectionData[sectionId]];
                    NSArray *newSectionData;
                    if(updatedIndex != -1) {
                        [updatedCells removeObjectAtIndex:updatedIndex];
                    }
                    
                    __block NSInteger newCellId = 0;
                    if(self.sortedByProperty) {
                        [self.sectionData[sectionId] enumerateObjectsUsingBlock:^(id cell, NSUInteger replaceCellId, BOOL *stop) {
                            KDatabaseObject *compareObject = (KDatabaseObject *)cell;
                            if([KDatabaseObject compareProperty:self.sortedByProperty object1:object object2:compareObject]) {
                                newCellId = replaceCellId;
                                *stop = YES;
                            }
                        }];
                    }
                    [updatedCells insertObject:object atIndex:newCellId];
                    [updatedData replaceObjectAtIndex:sectionId withObject:updatedCells];
                    newSectionData = [updatedData copy];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.sectionData = newSectionData;
                        if(updatedIndex != -1) {
                            [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:updatedIndex inSection:sectionId] toIndexPath:[NSIndexPath indexPathForRow:newCellId inSection:sectionId]];
                        }else {
                            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newCellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    });
                }
            }
        }];
    });
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
