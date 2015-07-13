//
//  EditPostViewController.h
//  Key
//
//  Created by Brendan Farmer on 6/30/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DismissAndPresentProtocol.h"

@interface EditPostViewController : UIViewController

@property (nonatomic,weak) id <DismissAndPresentProtocol> delegate;

@end
