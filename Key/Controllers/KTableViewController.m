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
    [self.tableView registerClass:[SubtitleTableViewCell class] forCellReuseIdentifier:[self cellIdentifier]];
    
    NSMutableArray *newSectionData = [NSMutableArray new];
    NSEnumerator *sectionCriteriaEnumerator = [self.sectionCriteria objectEnumerator];
    for(NSDictionary *sectionDictionary in sectionCriteriaEnumerator) {
        [newSectionData addObject:[NSClassFromString(sectionDictionary[@"class"]) findAllByDictionary:sectionDictionary[@"criteria"]]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[NSClassFromString(sectionDictionary[@"class"]) notificationChannel] object:nil];
    };
    self.sectionData = [newSectionData copy];
}

+ (dispatch_queue_t)sharedQueue {
    static dispatch_once_t pred;
    static dispatch_queue_t sharedDispatchQueue;
    
    dispatch_once(&pred, ^{
        sharedDispatchQueue = dispatch_queue_create("KTableViewQueue", NULL);
    });
    
    return sharedDispatchQueue;
}

- (void)databaseModified:(NSNotification *)notification {
    dispatch_async([[self class] sharedQueue], ^{
        KDatabaseObject *object = (KDatabaseObject *)notification.object;
        NSLog(@"NEW OBJECT: %@", object);
        [self.sectionCriteria enumerateObjectsUsingBlock:^(id obj, NSUInteger sectionId, BOOL *stop) {
            NSDictionary *sectionDictionary = (NSDictionary *)obj;
            NSDictionary *criteriaDictionary = (NSDictionary *)sectionDictionary[@"criteria"];
            NSLog(@"SECTION DICTIONARY: %@, CRITERIA DICTIONARY: %@", sectionDictionary, criteriaDictionary);
            if([object isKindOfClass:NSClassFromString(sectionDictionary[@"class"])]) {
                NSLog(@"CORRECTLY RECOGNIZED CLASS");
                __block BOOL matchesCriteria = YES;
                [criteriaDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if(![[object valueForKey:key] isEqual:obj]) {
                        matchesCriteria = NO;
                        *stop = YES;
                    }
                }];
                NSLog(@"CRITERIA MATCHING: %d", matchesCriteria);
                if(matchesCriteria) {
                    __block NSUInteger updatedIndex = -1;
                    NSArray *currentCells = (NSArray *)self.sectionData[sectionId];
                    [currentCells enumerateObjectsUsingBlock:^(id obj, NSUInteger cellId, BOOL *stop) {
                        KDatabaseObject *currentObject = (KDatabaseObject *)obj;
                        if([object.uniqueId isEqualToString:currentObject.uniqueId]) updatedIndex = cellId;
                        *stop = YES;
                    }];
                    
                    NSMutableArray *updatedData  = [[NSMutableArray alloc] initWithArray:self.sectionData];
                    NSMutableArray *updatedCells = [[NSMutableArray alloc] initWithArray:self.sectionData[sectionId]];
                    NSArray *newSectionData;
                    if(updatedIndex != -1) {
                        [updatedCells removeObjectAtIndex:updatedIndex];
                        NSLog(@"UPDATED CELLS: %@", updatedCells);
                        if(updatedCells.count > 0)[updatedData replaceObjectAtIndex:sectionId withObject:updatedCells];
                        else [updatedData replaceObjectAtIndex:sectionId withObject:@[]];
                        NSLog(@"UPDATED DATA: %@", updatedData);
                        self.sectionData = [updatedData copy];
                        NSLog(@"NEW SECTION DATA: %@", newSectionData);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"UPDATED CELLS: %@", self.sectionData);
                            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(updatedIndex) inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        });
                    }
                    __block NSInteger newCellId = 0;
                    if(self.sortedByProperty) {
                        [updatedCells enumerateObjectsUsingBlock:^(id cell, NSUInteger replaceCellId, BOOL *stop) {
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
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newCellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (KDatabaseObject *)objectForIndexPath:(NSIndexPath *)indexPath {
    return (KDatabaseObject *)((NSArray *)self.sectionData[indexPath.section])[indexPath.row];
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
