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

static NSString *TableViewCellIdentifier = @"Posts";

@interface ProfileViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@property (nonatomic, strong) IBOutlet UILabel *usernameLabel;
@property (nonatomic) NSArray *posts;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.posts = [KPost findByAuthorId:self.user.uniqueId];
    
    NSLog(@"POSTS RETURNED: %@", self.posts);
    
    self.postsTableView.delegate = self;
    self.postsTableView.dataSource = self;
    self.postsTableView.scrollEnabled = YES;
    
    [self.postsTableView registerClass:[SubtitleTableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.usernameLabel.text = self.user.username;
    });
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[KPost notificationChannel] object:nil];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    if(self.posts.count != [KPost findByAuthorId:self.user.uniqueId].count) {
        self.posts = [KPost findByAuthorId:self.user.uniqueId];
        [self.postsTableView reloadData];
    }
}

- (void)databaseModified:(NSNotification *)notification {
    if([notification.object isKindOfClass:[KPost class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            KPost *post = (KPost *)notification.object;
            NSLog(@"POST TO BE SHOWN: %@", post);
            if([post previewImage]) {
                NSMutableArray *posts = [[NSMutableArray alloc] initWithArray:self.posts];
                [posts addObject:[notification object]];
                self.posts = [[NSArray alloc] initWithArray:posts];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.postsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.posts.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KPost *post = self.posts[indexPath.row];
    SubtitleTableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier
                                                                            forIndexPath:indexPath];
    
    cell.textLabel.text  = [NSString stringWithFormat:@"%@", post.author.username];
    cell.imageView.image = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", post.displayDate];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KPost *post = self.posts[indexPath.row];
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
