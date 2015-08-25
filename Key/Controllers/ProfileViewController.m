//
//  ProfileViewController.m
//  Key
//
//  Created by Brendan Farmer on 8/13/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ProfileViewController.h"
#import "KPost.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "SubtitleTableViewCell.h"
#import "MediaViewController.h"
#import "ContactViewController.h"
#import "KLocation.h"

@interface ProfileViewController () <UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@property (nonatomic, strong) IBOutlet UILabel *usernameLabel;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    self.tableView = self.postsTableView;
    self.sectionCriteria = @[@{@"class" : @"KPost",
                               @"criteria" : @{@"authorId" : self.user.uniqueId, @"ephemeral" : @NO, @"attachmentCount" : [NSNumber numberWithInteger:0]}}];
    self.sortedByProperty = @"createdAt";
    self.sortDescending   = YES;
    [super viewDidLoad];
    self.usernameLabel.text = self.user.username;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KPost *post = (KPost *)[self objectForIndexPath:indexPath];
    SubtitleTableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    
    cell.imageView.image = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", post.displayDate];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if(post.location)cell.detailTextLabel.text = post.location.shortAddress;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KPost *post = (KPost *)[self objectForIndexPath:indexPath];
    if(post) {
        MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
        mediaViewController.post = post;
        dispatch_async(dispatch_get_main_queue(), ^{});
        [self presentViewController:mediaViewController animated:NO completion:nil];
    }
}

- (IBAction)clickDone:(id)sender {
    [(ContactViewController *)self.parentViewController dismissProfileViewController:self];
}


@end
