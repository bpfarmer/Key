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

static NSString *TableViewCellIdentifier = @"Posts";

@interface SocialViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@property (nonatomic) NSArray *posts;

@end

@implementation SocialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.posts = [KPost unread];
    
    self.postsTableView.delegate = self;
    self.postsTableView.dataSource = self;
    self.postsTableView.scrollEnabled = YES;
    
    [self.postsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    self.currentUser = [KAccountManager sharedManager].user;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseModified:)
                                                 name:[KPost notificationChannel]
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    if(self.posts.count != [KPost unread].count) {
        self.posts = [KPost unread];
        [self.postsTableView reloadData];
    }
}

- (void)databaseModified:(NSNotification *)notification {
    if([notification.object isKindOfClass:[KPost class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            KPost *post = (KPost *)notification.object;
            NSLog(@"POST TO BE SHOWN: %@", post);
            if(!post.read) {
                if([post previewImage]) {
                    NSMutableArray *posts = [[NSMutableArray alloc] initWithArray:self.posts];
                    [posts addObject:[notification object]];
                    self.posts = [[NSArray alloc] initWithArray:posts];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.postsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.posts.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    });
                }
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
    NSLog(@"POST: %@", post);
    UITableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier
                                                                      forIndexPath:indexPath];
    
    cell.textLabel.text  = [NSString stringWithFormat:@"%@", post.author.username];
    cell.imageView.image = [UIImage imageWithData:post.previewImage];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KPost *post = self.posts[indexPath.row];
    if(post) {
        MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
        mediaViewController.post = post;
        [self.parentViewController presentViewController:mediaViewController animated:NO completion:^{
            NSMutableArray *posts = [NSMutableArray arrayWithArray:self.posts];
            [posts removeObject:post];
            post.read = YES;
            [post save];
            self.posts = posts;
            [self.postsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}


@end
