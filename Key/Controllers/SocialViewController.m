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

@property (nonatomic, strong) IBOutlet UITextView *postTextView;
@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@property (nonatomic, weak) NSArray *posts;

@end

@implementation SocialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *borderColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
    
    self.postTextView.layer.borderColor = borderColor.CGColor;
    self.postTextView.layer.borderWidth = 1.0;
    self.postTextView.layer.cornerRadius = 5.0;
    
    self.postTextView.delegate = self;
    
    [self.postTextView sizeToFit];
    [self.postTextView layoutIfNeeded];
    
    self.postsTableView.delegate = self;
    self.postsTableView.dataSource = self;
    
    [self.postsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    self.posts = [KPost all];
    
    self.currentUser = [KAccountManager sharedManager].user;
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
    UITableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier
                                                                      forIndexPath:indexPath];
    
    NSString *text = post.text;
    if(text == nil) text = @"Tap to View";
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", post.author.username, text];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KPost *post = self.posts[indexPath.row];
    if(post) {
        MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
        mediaViewController.post = post;
        [self.parentViewController presentViewController:mediaViewController animated:NO completion:nil];
    }
}


@end
