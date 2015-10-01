//
//  DatabaseDataSource.m
//  Key
//
//  Created by Brendan Farmer on 9/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "DatabaseDataSource.h"
#import "KDatabaseObject.h"

@interface DatabaseDataSource ()

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *sectionData;

@property (nonatomic, copy) NSString *cellIdentifier;
@property (nonatomic, copy) TableViewCellConfigureBlock configureCellBlock;
@property (nonatomic, copy) SectionCriteriaBlock sectionCriteriaBlock;
@property (nonatomic, copy) SortBlock sortBlock;

@end

@implementation DatabaseDataSource

- (instancetype)initWithSectionData:(NSArray *)sectionData
                     cellIdentifier:(NSString *)cellIdentifier
                          tableView:(UITableView *)tableView
                 configureCellBlock:(TableViewCellConfigureBlock)configureCellBlock
               sectionCriteriaBlock:(SectionCriteriaBlock)sectionCriteriaBlock
                          sortBlock:(SortBlock)sortBlock{
    
    self = [super init];
    if(self) {
        self.sectionData          = sectionData;
        self.cellIdentifier       = cellIdentifier;
        self.tableView            = tableView;
        self.configureCellBlock   = configureCellBlock;
        self.sectionCriteriaBlock = sectionCriteriaBlock;
        self.sortBlock            = sortBlock;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier forIndexPath:indexPath];
    KDatabaseObject *object = [self objectAtIndexPath:indexPath];
    self.configureCellBlock(cell, object);
    return cell;
}

+ (dispatch_queue_t)sharedQueue {
    static dispatch_once_t pred;
    static dispatch_queue_t sharedDispatchQueue;
    
    dispatch_once(&pred, ^{
        sharedDispatchQueue = dispatch_queue_create("DataSourceQueue", NULL);
    });
    
    return sharedDispatchQueue;
}

- (void)databaseNotification:(NSNotification *)notification {
    dispatch_async([self.class sharedQueue], ^{
        [self objectUpdated:notification.object];
    });
}

- (void)objectUpdated:(KDatabaseObject *)object {
    [self.sectionData enumerateObjectsUsingBlock:^(id obj, NSUInteger sectionId, BOOL *stop) {
        if(self.sectionCriteriaBlock(object, sectionId)) {
            [self ensureSectionExists:sectionId];
            
            NSArray *objectsInSection = self.sectionData[sectionId];
            NSMutableArray *updatedObjects = [NSMutableArray arrayWithArray:objectsInSection];
            
            NSUInteger currentObjectIndex = [objectsInSection indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if([((KDatabaseObject *)obj).uniqueId isEqualToString:object.uniqueId]) {
                    *stop = YES;
                    return YES;
                }else return NO;
            }];
            
            if(currentObjectIndex == NSNotFound) {
                [updatedObjects addObject:object];
                [self updateSection:sectionId withArray:updatedObjects];
                [self addCellWithObject:object atIndexPath:[NSIndexPath indexPathForRow:[updatedObjects indexOfObject:object] inSection:sectionId]];
            }else {
                [updatedObjects replaceObjectAtIndex:currentObjectIndex withObject:object];
                [self updateSection:sectionId withArray:updatedObjects];
                [self reloadCellId:currentObjectIndex inSectionId:sectionId];
            }
            
            [updatedObjects sortUsingComparator:self.sortBlock];
            if([updatedObjects indexOfObject:object] != currentObjectIndex) {
                [self updateSection:sectionId withArray:updatedObjects];
                [self moveOldCellId:currentObjectIndex toNewCellId:[updatedObjects indexOfObject:object] inSectionId:sectionId];
            }
        }
    }];
}

- (void)updateSection:(NSUInteger)sectionId withArray:(NSArray *)array {
    NSMutableArray *mutableSectionData = [NSMutableArray arrayWithArray:self.sectionData];
    [mutableSectionData replaceObjectAtIndex:sectionId withObject:array];
    self.sectionData = [mutableSectionData copy];
}

- (void)addCellWithObject:(KDatabaseObject *)object atIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.tableView) [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)reloadCellId:(NSInteger)cellId inSectionId:(NSUInteger)sectionId {
    dispatch_async(dispatch_get_main_queue(), ^{
       if(self.tableView) [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellId inSection:sectionId]] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)moveOldCellId:(NSInteger)oldCellId toNewCellId:(NSInteger)newCellId inSectionId:(NSUInteger)sectionId {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.tableView) [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:oldCellId inSection:sectionId] toIndexPath:[NSIndexPath indexPathForRow:newCellId inSection:sectionId]];
    });
}

- (void)ensureSectionExists:(NSUInteger)sectionId {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.tableView) while(self.tableView.numberOfSections <= sectionId) [self.tableView insertSections:[NSIndexSet indexSetWithIndex:self.tableView.numberOfSections] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)self.sectionData[section]).count;
}

- (KDatabaseObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return ((NSArray *)self.sectionData[indexPath.section])[indexPath.row];
}


@end
