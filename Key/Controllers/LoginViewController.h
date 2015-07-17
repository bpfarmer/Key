//
//  loginViewController.h
//  Key
//
//  Created by Loren on 1/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) IBOutlet UITextField *usernameText;
@property (nonatomic) IBOutlet UITextField *passwordText;

@end
