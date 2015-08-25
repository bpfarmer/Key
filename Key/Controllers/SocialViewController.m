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

@interface SocialViewController () <UITextViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@end

@implementation SocialViewController

- (void)viewDidLoad {
    self.tableView = self.postsTableView;
    self.sectionCriteria = @[@{@"class" : @"KPost",
                               @"criteria" : @{@"ephemeral" : @NO, @"attachmentCount" : [NSNumber numberWithInteger:0]}}];
    self.sortedByProperty = @"createdAt";
    self.sortDescending   = YES;
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KPost *post = (KPost *)[self objectForIndexPath:indexPath];
    SubtitleTableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    
    cell.textLabel.text  = [NSString stringWithFormat:@"%@", post.author.username];
    cell.imageView.image = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", post.displayDate];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    dispatch_async([self.class sharedQueue], ^{
        KPost *post = (KPost *)[self objectForIndexPath:indexPath];
        if(post) {
            MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
            mediaViewController.post = post;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.parentViewController presentViewController:mediaViewController animated:NO completion:nil];
            });
        }
    });
}

- (NSString *)cellIdentifier {
    return @"SocialPosts";
}


@end
