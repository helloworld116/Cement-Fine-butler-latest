//
//  CommonViewController.m
//  Cement Fine butler
//
//  Created by 文正光 on 13-12-4.
//  Copyright (c) 2013年 河南丰博自动化有限公司. All rights reserved.
//

#import "CommonViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view

    self.noDataView = [[ErrorOrNoDataView alloc] initWithFrame:CGRectZero];
    self.noDataView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //需要增加左右界面的需再viewWillAppear中添加
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //移除观察条件
    [self.request clearDelegatesAndCancel];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 发送网络请求
-(void) sendRequest{
    //清除数据及处理界面
    self.responseData = nil;
    self.data = nil;
    //自定义清除
    [self clear];
    //加载过程提示
    self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHUD.labelText = @"正在加载中...";
    self.progressHUD.labelFont = [UIFont systemFontOfSize:12];
    //    self.progressHUD.dimBackground = YES;
    self.progressHUD.opacity=1.0;
    self.progressHUD.delegate = self;
    [self.view addSubview:self.progressHUD];
    [self.progressHUD show:YES];
    
    DDLogCInfo(@"******  Request URL is:%@  ******",self.URL);
    self.request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.URL]];
    self.request.timeOutSeconds = kASIHttpRequestTimeoutSeconds;
    [self.request setPostValue:kSharedApp.accessToken forKey:@"accessToken"];
    [self.request setPostValue:[NSNumber numberWithInt:kSharedApp.finalFactoryId] forKey:@"factoryId"];
    [self setRequestParams];
    [self.request setDelegate:self];
    [self.request setDidFailSelector:@selector(requestFailed:)];
    [self.request setDidFinishSelector:@selector(requestSuccess:)];
    [self.request startAsynchronous];
}

-(void)sendRequestWithNoProgress{
    //清除数据及处理界面
    self.responseData = nil;
    self.data = nil;
//    self.messageView.hidden = YES;
    //自定义清除
    [self clear];
    DDLogCInfo(@"******  Request URL is:%@  ******",self.URL);
    self.request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.URL]];
    self.request.timeOutSeconds = kASIHttpRequestTimeoutSeconds;
    [self.request setPostValue:kSharedApp.accessToken forKey:@"accessToken"];
    [self.request setPostValue:[NSNumber numberWithInt:kSharedApp.finalFactoryId] forKey:@"factoryId"];
    [self setRequestParams];
    [self.request setDelegate:self];
    [self.request setDidFailSelector:@selector(requestFailedWithNoProgressHUDrequest:)];
    [self.request setDidFinishSelector:@selector(requestSuccess:)];
    [self.request startAsynchronous];
}

/**
 *  连续请求时出错处理
 *
 *  @param request <#request description#>
 */
-(void)requestFailedWithNoProgressHUDrequest:(ASIHTTPRequest *)request{
    
}

#pragma mark 网络请求
-(void) requestFailed:(ASIHTTPRequest *)request{
    [self.progressHUD hide:YES];
    NSString *message = nil;
    if ([@"The request timed out" isEqualToString:[[request error] localizedDescription]]) {
        message = @"网络请求超时啦。。。";
    }else{
        message = @"网络出错啦。。。";
    }
    self.noDataView.lblMsg.text = message;
}

-(void)requestSuccess:(ASIHTTPRequest *)request{
    self.noDataView.hidden = YES;
    [self.progressHUD hide:YES];
    self.responseData = [Tool stringToDictionary:request.responseString];
    int errorCode = [[self.responseData objectForKey:@"error"] intValue];
    if (errorCode==kErrorCode0) {
        self.data = [self.responseData objectForKey:@"data"];
        if ([Tool isNullOrNil:self.data]) {
            self.noDataView.lblMsg.text = @"没有满足条件的数据";
            [self responseCode0WithNOData];
        }else{
            [self responseCode0WithData];
        }
    }else if(errorCode==kErrorCodeExpired){
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            LoginViewController *loginViewController = (LoginViewController *)[kSharedApp.storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
            kSharedApp.window.rootViewController = loginViewController;
        });
    }else{
        [self responseWithOtherCode];
    }
}


#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	[self.progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark 自定义VC必须实现的方法
-(void)responseCode0WithData{
    
}

-(void)responseWithOtherCode{
    self.noDataView.hidden= NO;
}

#pragma mark 自定义VC可选实现的方法
-(void)clear{
    self.data = nil;
    [self.request clearDelegatesAndCancel];
}

-(void)setRequestParams{
    NSString *startDate,*endDate;
    NSDate *date = [NSDate date];
    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow: -(60.0f*60.0f*24.0f)];
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:date];
    NSInteger day = [dateComponents day];
    NSInteger month = [dateComponents month];
    NSInteger year = [dateComponents year];
    
    NSRange range;
    NSUInteger numberOfDaysInMonth;
    switch (self.timeType) {
        case 0:
            startDate = [NSString stringWithFormat:@"%d-%d-%d",year,month,day];
            endDate = [NSString stringWithFormat:@"%d-%d-%d",year,month,day];
            break;
        case 1:
            dateComponents = [gregorian components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:yesterday];
            day = [dateComponents day];
            month = [dateComponents month];
            year = [dateComponents year];
            startDate = [NSString stringWithFormat:@"%d-%d-%d",year,month,day];
            endDate = [NSString stringWithFormat:@"%d-%d-%d",year,month,day];
            break;
        case 2:
            range = [gregorian rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
            numberOfDaysInMonth = range.length;
            startDate = [NSString stringWithFormat:@"%d-%d-1",year,month];
            endDate = [NSString stringWithFormat:@"%d-%d-%d",year,month,numberOfDaysInMonth];
            break;
        case 3:
            startDate = [NSString stringWithFormat:@"%d-1-1",year];
            endDate = [NSString stringWithFormat:@"%d-12-31",year];
            break;
        default:
            break;
    }
    [self.request setPostValue:startDate forKey:@"startTime"];
    [self.request setPostValue:endDate forKey:@"endTime"];
}

-(void)setPanels{}

-(void)responseCode0WithNOData{}
@end
