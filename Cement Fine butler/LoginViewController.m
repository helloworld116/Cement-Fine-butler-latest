//
//  LoginViewController.m
//  CustomerSystem
//
//  Created by wzg on 13-4-22.
//  Copyright (c) 2013年 denglei. All rights reserved.
//

#import "LoginViewController.h"
#import "LoginAction.h"
#import "LocalNotifactionServices.h"


@interface LoginViewController ()<MBProgressHUDDelegate>
@property (retain, nonatomic) ASIFormDataRequest *request;
@property (nonatomic,retain) MBProgressHUD *HUD;
@property (nonatomic,copy) NSString *uname;
@property (nonatomic,copy) NSString *pword;
@property BOOL keyboardWasShow;
@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setBackground{
    self.backgroundImgView.image = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basemap" ofType:@".png"]];
    self.continerView.backgroundColor = [UIColor clearColor];
    self.titleImgView.image = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_03" ofType:@".png"]];
    self.username.background = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"username_box" ofType:@".png"]];
    self.password.background = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"key_box" ofType:@".png"]];
    [self.btnLogin setBackgroundImage:[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login_box" ofType:@".png"]] forState:UIControlStateNormal];
    [self.btnLogin setBackgroundImage:[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login_click_box" ofType:@".png"]] forState:UIControlStateHighlighted];
    [self.username setValue:[UIColor colorWithRed:205.0/255.0 green:229.0/255.0 blue:250.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    [self.password setValue:[UIColor colorWithRed:205.0/255.0 green:229.0/255.0 blue:250.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self setBackground];
    self.username.delegate = self;
    self.password.delegate = self;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [userDefaults objectForKey:@"username"];
    self.username.text = username;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setUsername:nil];
    [self setPassword:nil];
    [self setPassword:nil];
  
    self.uname = nil;
    self.pword = nil;
    [self setContinerView:nil];
    [self setTitleImgView:nil];
    [self setBtnLogin:nil];
    [self setBackgroundImgView:nil];
    [super viewDidUnload];
}

- (IBAction)doLogin:(id)sender {
    if([self validate]){
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
        [self.view addSubview:self.HUD];
        self.HUD.delegate = self;
        self.HUD.dimBackground = YES;//
        self.HUD.labelText = @"正在登录...";
        [self.HUD show:YES];
        [self sendRequest];
    }
}

-(BOOL)validate{
    //键盘缩回
    self.keyboardWasShow = NO;
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    //过滤左右空格
    self.uname = [self.username.text stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceCharacterSet]];
    self.pword = [self.password.text stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceCharacterSet]];
    
    if (self.uname == nil || [@"" isEqualToString:self.uname]) {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.labelText = @"用户名不能为空";
        self.HUD.labelFont = [UIFont systemFontOfSize:13.f];
        self.HUD.margin = 5.f;
        if (IS_IPHONE_5) {
            self.HUD.yOffset = -43;
        }else{
            self.HUD.yOffset = 2;
        }
        if(IS_IOS7){
            self.HUD.yOffset -=10;
        }
        self.HUD.xOffset = 85;
        self.HUD.delegate = self;
        [self.view addSubview:self.HUD];
        [self.HUD show:YES];
        [self.HUD hide:YES afterDelay:1];
        return NO;
    }
    if (self.pword ==nil || [@"" isEqualToString:self.pword]) {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.labelText = @"密码不能为空";
        self.HUD.labelFont = [UIFont systemFontOfSize:13.f];
        self.HUD.margin = 5.f;
        if (IS_IPHONE_5) {
            self.HUD.yOffset = 15;
        }else{
            self.HUD.yOffset = 58;
        }
        if(IS_IOS7){
            self.HUD.yOffset -=10;
        }
        self.HUD.xOffset = 90;
        self.HUD.delegate = self;
        [self.view addSubview:self.HUD];
        [self.HUD show:YES];
        [self.HUD hide:YES afterDelay:1];
        return NO;
    }
    return YES;
}

- (IBAction)backgroundTouch:(id)sender {
    self.keyboardWasShow = NO;
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
}

#pragma mark 发送网络请求
-(void) sendRequest {
    DDLogCInfo(@"******  Request URL is:%@  ******",kLoginURL);
    self.request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kLoginURL]];
    [self.request setUseCookiePersistence:YES];
    [self.request setPostValue:self.uname forKey:@"username"];
    [self.request setPostValue:self.pword forKey:@"password"];
    [self.request setDelegate:self];
    [self.request setDidFailSelector:@selector(requestFailed:)];
    [self.request setDidFinishSelector:@selector(requestSuccess:)];
    [self.request startAsynchronous];
}

#pragma mark 网络请求
-(void) requestFailed:(ASIHTTPRequest *)request{
//    [SVProgressHUD showErrorWithStatus:@"网络请求出错"];
    DDLogCError(@"网络请求出错,%@",[request error]);
    self.password.text = nil;
    [self.HUD hide:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"友情提示" message:@"服务器异常，请稍后再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];

}

-(void)requestSuccess:(ASIHTTPRequest *)request{
    [self.HUD hide:YES];
    NSDictionary *dict = [Tool stringToDictionary:request.responseString];
    int errorCode = [[dict objectForKey:@"error"] intValue];
    if (errorCode==kErrorCode0) {
        DDLogCVerbose(@"登录成功");
        NSDictionary *data = [dict objectForKey:@"data"];
        kSharedApp.accessToken = [data objectForKey:@"accessToken"];
        kSharedApp.expiresIn = [[data objectForKey:@"expiresIn"] intValue];
        kSharedApp.factory = [data objectForKey:@"factorys"][0];
        kSharedApp.startFactoryId=kSharedApp.finalFactoryId=[[kSharedApp.factory objectForKey:@"id"] intValue];
        kSharedApp.factorys = [data objectForKey:@"factorys"];
        kSharedApp.user = [data objectForKey:@"user"];
        NSArray *permissions = [data objectForKey:@"permissions"];
        for (NSDictionary *permission in permissions) {
            if([kMultiGroupCode isEqualToString:[permission objectForKey:@"code"]]){
                kSharedApp.multiGroup=YES;
                break;
            }
        }
        
        //保存用户名和密码
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.uname forKey:@"username"];
        [userDefaults setObject:self.pword forKey:@"password"];
        
        UITabBarController *tabBarController = [kSharedApp showViewControllers];
        tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:tabBarController animated:YES completion:nil];
        
        //防止session过期，自动登录
        LoginAction *loginAction = [[LoginAction alloc] init];
//        [loginAction  backstageLoginWithSync:NO];
        [loginAction performSelector:@selector(backstageLoginWithSync:) withObject:[NSNumber numberWithBool:NO] afterDelay:kSharedApp.expiresIn-10];
        //预警消息
        [kSharedApp.notifactionServices performSelector:@selector(getNotifactions) withObject:nil afterDelay:10];
        kSharedApp.loginTimer = [NSTimer scheduledTimerWithTimeInterval:30*60 target:kSharedApp.notifactionServices selector:@selector(getNotifactions) userInfo:nil repeats:YES];
//        [notifactionServices getNotifactions];
    }else{
        DDLogCWarn(@"登录失败，errorCode is %d",errorCode);
        self.password.text = nil;
//        NSString *msg = [dict objectForKey:@"message"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"用户名或密码错误" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark textfield代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (self.username==textField) {
        [self.password becomeFirstResponder];
    }else if (self.password==textField){
        [self doLogin:nil];
        [textField resignFirstResponder];
        self.keyboardWasShow = NO;
    }
    return YES;
}
    
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (!self.keyboardWasShow) {
        NSTimeInterval animationDuration = 0.30f;
        [UIView beginAnimations:@"DownKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        CGRect rect = self.continerView.frame;
        if (IS_IPHONE_5) {
           rect.origin.y += 65;
        }else{
            rect.origin.y += 150;
        }
        if (IS_IOS7) {
            rect.origin.y -= 20;
        }
        self.continerView.frame = rect;
        [UIView commitAnimations];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (!self.keyboardWasShow) {
        NSTimeInterval animationDuration = 0.30f;
        [UIView beginAnimations:@"UpKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        CGRect rect = self.continerView.frame;
        if (IS_IPHONE_5) {
            rect.origin.y -= 65;
        }else{
            rect.origin.y -= 150;
        }
        if (IS_IOS7) {
            rect.origin.y += 20;
        }
        self.continerView.frame = rect;
        [UIView commitAnimations];
        self.keyboardWasShow = YES;
    }
}

#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[self.HUD removeFromSuperview];
	self.HUD = nil;
}
@end
