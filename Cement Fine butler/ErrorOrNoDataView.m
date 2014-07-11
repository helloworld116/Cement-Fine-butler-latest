//
//  ErrorOrNoDataView.m
//  Cement Fine butler
//
//  Created by 文正光 on 14-5-7.
//  Copyright (c) 2014年 河南丰博自动化有限公司. All rights reserved.
//

#import "ErrorOrNoDataView.h"

@implementation ErrorOrNoDataView

- (id)initWithFrame:(CGRect)frame
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"ErrorOrNoDataView" owner:self options:nil] objectAtIndex:0];
    if (self) {
        // Initialization code
        self.frame = frame;
        self.lblMsg.text = @"加载失败，请稍后刷新";
        [self.btn setBackgroundImage:[UIImage imageNamed:@"error_btn"] forState:UIControlStateNormal];
        [self.btn setBackgroundImage:[UIImage imageNamed:@"error_btn_click"] forState:UIControlStateHighlighted];
    }
    return self;
}



@end
