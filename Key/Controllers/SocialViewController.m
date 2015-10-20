//
//  SocialViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SocialViewController.h"
#import "KStorageManager.h"
#import "KPost.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "SelectRecipientViewController.h"
#import "HomeViewController.h"
#import "MediaViewController.h"
#import "SubtitleTableViewCell.h"
#import "DatabaseDataSource.h"

@interface SocialViewController () <UITextViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@end

@implementation SocialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentUser = [KAccountManager sharedManager].user;
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:[self tableData]
                                                                      cellIdentifier:[self cellIdentifier]
                                                                           tableView:self.postsTableView
                                                                  configureCellBlock:[self configureCellBlock]
                                                                sectionCriteriaBlock:[self sectionCriteriaBlock]
                                                                           sortBlock:[self sortBlock]];
    [dataSource registerForUpdatesFromClasses:@[@"KUser"]];
    self.postsTableView.dataSource = dataSource;
}

- (NSArray *)tableData {
    return [KPost findAllWhere:@"ephemeral = 0 and (read_at > :yesterday or read_at is null)" parameters:@{@"yesterday" : [NSNumber numberWithDouble:[[NSDate dateWithTimeIntervalSinceNow:(-60*60*24)] timeIntervalSinceReferenceDate]]}];
}

- (NSString *)cellIdentifier {
    return @"Posts";
}

- (NSComparisonResult (^)(KDatabaseObject*, KDatabaseObject*))sortBlock {
    return ^(KDatabaseObject *object1, KDatabaseObject *object2) {
        KPost *post1 = (KPost *)object1;
        KPost *post2 = (KPost *)object2;
        if(post1.readAt && !post2.readAt) {
            return NSOrderedDescending;
        }else if(!post1.readAt && post2.readAt) {
            return NSOrderedAscending;
        }else {
            return [post1.createdAt compare:post2.createdAt];
        }
    };
}

- (BOOL (^)(KDatabaseObject*, NSUInteger))sectionCriteriaBlock {
    return ^(KDatabaseObject *object, NSUInteger sectionId) {
        KPost *post = (KPost *)object;
        return post.ephemeral;
    };
}

- (UITableViewCell* (^)(UITableViewCell*, KDatabaseObject*))configureCellBlock {
    return ^(UITableViewCell *cell, KDatabaseObject *object) {
        KPost *post = (KPost *)object;
        cell.textLabel.text  = [NSString stringWithFormat:@"%@", post.author.username];
        cell.imageView.image = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", post.displayDate];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        return cell;
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    //dispatch_async([self.class sharedQueue], ^{
        KPost *post = [KPost new];
        if(post) {
            MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
            mediaViewController.post = post;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.parentViewController presentViewController:mediaViewController animated:NO completion:nil];
            });
        }
    //});
}


@end
