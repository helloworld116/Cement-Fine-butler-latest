//
//  EquipmentListViewController.m
//  Cement Fine butler
//
//  Created by 文正光 on 13-10-16.
//  Copyright (c) 2013年 河南丰博自动化有限公司. All rights reserved.
//

#import "EquipmentListViewController.h"
#import "EquipmentListCell.h"
#import "EquipmentMapViewController.h"
#import "EquipmentDetailsViewController.h"
#import "ElecDetailViewController.h"

@interface EquipmentListViewController ()<MBProgressHUDDelegate>
@property (strong, nonatomic) IBOutlet UITableView *pullTableView;
@property (strong, nonatomic) UIBarButtonItem *rightButtonItem;
@property (retain,nonatomic) MBProgressHUD *progressHUD;
@property (retain, nonatomic) ASIFormDataRequest *request;
@property (retain, nonatomic) PromptMessageView *messageView;
@property (nonatomic,assign) int totalCount;
@property (nonatomic,assign) int currentPage;
@property (nonatomic,retain) NSTimer *timer;
@end

@implementation EquipmentListViewController

static const float delaySeconds = 3.0f;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if([UIViewController instancesRespondToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout=UIRectEdgeNone;
    }
    self.navigationItem.title = @"设备列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return_icon"] highlightedImage:[UIImage imageNamed:@"return_click_icon"] target:self action:@selector(pop:)];

    self.currentPage=1;
//    self.list = [NSMutableArray array];
//    [self sendRequest:self.currentPage withProgress:YES];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 5, 0, 0)];
    if([UITableViewController instancesRespondToSelector:@selector(setSeparatorInset:)]){
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    self.tableView.separatorColor = [Tool hexStringToColor:@"#e3e3e3"];
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([EquipmentListCell class]) owner:self options:nil] objectAtIndex:0];
    self.tableView.rowHeight = view.frame.size.height;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if ((kSharedApp.startFactoryId!=kSharedApp.finalFactoryId)&&(self.list==nil)) {
        [self.list removeAllObjects];
        //send request
        [self sendRequest:self.currentPage withProgress:YES];
    }
    NSDictionary *info = @{@"page":[NSNumber numberWithInt:self.currentPage],@"isProgress":@NO};
    self.timer = [NSTimer scheduledTimerWithTimeInterval:delaySeconds target:self selector:@selector(onTimer:) userInfo:info repeats:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    [self.request clearDelegatesAndCancel];
}

-(void)onTimer:(NSTimer *)timer {
    NSDictionary *condition = [timer userInfo];
    [self sendRequest:[[condition objectForKey:@"page"] intValue] withProgress:[[condition objectForKey:@"isProgress"] boolValue]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showMapViewController:(id)sender{
    EquipmentMapViewController *mapController = [self.storyboard instantiateViewControllerWithIdentifier:@"equipmentMapViewController"];
    mapController.equipmentList = self.list;
    mapController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:mapController animated:YES];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.list count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PublicEquipmentCell *cell;
    NSDictionary *equipmentInfo = [self.list objectAtIndex:indexPath.row];
    NSString *imgName = [NSString stringWithFormat:@"%@%@",@"equipment_",[Tool stringToString:[equipmentInfo objectForKey:@"code"]]];
    if ([@"990" isEqualToString:[Tool stringToString:[equipmentInfo objectForKey:@"code"]]]) {
        static NSString *CellIdentifier = @"EleCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"EquipmentListCell" owner:self options:nil] objectAtIndex:1];
        }
        cell.lblEquipmentName.text = [NSString stringWithFormat:@"%@",[Tool stringToString:[equipmentInfo objectForKey:@"typename"]]];
        cell.lblTotalOutput.text = [NSString stringWithFormat:@"度数：%@%@",[Tool numberToStringWithFormatter:[NSNumber numberWithDouble:[Tool doubleValue:[equipmentInfo objectForKey:@"totalOutput"]]]],@"度"];
    }else{
        static NSString *CellIdentifier = @"EquipmentListCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
        }
        cell.lblEquipmentName.text = [NSString stringWithFormat:@"%@ （%@）",[Tool stringToString:[equipmentInfo objectForKey:@"typename"]],[Tool stringToString:[equipmentInfo objectForKey:@"materialName"]]];
        ((EquipmentListCell *)cell).lblInstantFlowRate.text = [NSString stringWithFormat:@"瞬时流量：%@%@",[Tool numberToStringWithFormatter:[NSNumber numberWithDouble:[Tool doubleValue:[equipmentInfo objectForKey:@"instantFlowRate"]]]],@"吨/时"];
        cell.lblTotalOutput.text = [NSString stringWithFormat:@"总累积量：%@%@",[Tool numberToStringWithFormatter:[NSNumber numberWithDouble:[Tool doubleValue:[equipmentInfo objectForKey:@"totalOutput"]]]],@"吨"];
    }
    cell.imgView.image = [UIImage imageNamed:imgName];
    cell.lblSN.text = [NSString stringWithFormat:@"%@%@",@"SN：",[Tool stringToString:[equipmentInfo objectForKey:@"sn"]]];
    cell.lblStatus.text = [Tool stringToString:[equipmentInfo objectForKey:@"statusLabel"]];
    cell.lblLineName.text = [NSString stringWithFormat:@"%@%@",@"产线：",[Tool stringToString:[equipmentInfo objectForKey:@"linename"]]];
    int status = [Tool intValue:[equipmentInfo objectForKey:@"status"]];
    [self colorByEquipmentStatus:status equipmentCell:cell];
    return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSDictionary *equipmentInfo = [self.list objectAtIndex:indexPath.row];
//    int equipmentStatus = [[equipmentInfo objectForKey:@"status"] intValue];
//    if (equipmentStatus==0) {
//        cell.backgroundColor = [UIColor greenColor];
//    }else{
//        cell.backgroundColor = [UIColor redColor];
//    }
//}

-(void)colorByEquipmentStatus:(int)status equipmentCell:(PublicEquipmentCell*)cell{
    switch (status) {
        case 0:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#30bee1"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_meter_normal_icon"];
            break;
        case 1:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#ff5976"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_meter_fault_icon"];
            break;
        case 2:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#fdbf6b"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_disconnect_the_meter_scale_icon"];
            break;
        case 3:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#5287b0"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_system_does_not_start_icon"];
            break;
        case 4:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#ff7ab3"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_disconnect_the_meter_box_icon"];
            break;
        case 5:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#bf5efc"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_network_anomaly_icon"];
            break;
        case 6:
            cell.lblStatusColor.backgroundColor = [Tool hexStringToColor:@"#19bc9b"];
            cell.imgStatus.image = [UIImage imageNamed:@"status_normal_shutdown_icon"];
            break;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *equipmentDetails = [self.list objectAtIndex:indexPath.row];
    EquipmentDetailsViewController *detailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"equipmentDetailsViewController"];
    detailsViewController.data = equipmentDetails;
    [self.navigationController pushViewController:detailsViewController animated:YES];
}


#pragma mark 发送网络请求
-(void) sendRequest:(NSUInteger)currentPage withProgress:(BOOL)isProgress{
    if (isProgress) {
        //加载过程提示
        self.progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
        self.progressHUD.labelText = @"正在加载中...";
        self.progressHUD.labelFont = [UIFont systemFontOfSize:12];
        self.progressHUD.dimBackground = YES;
        self.progressHUD.opacity=1.0;
        self.progressHUD.delegate = self;
        [self.tableView addSubview:self.progressHUD];
        [self.progressHUD show:YES];
    }
    DDLogCInfo(@"******  Request URL is:%@  ******",kEquipmentList);
    self.request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kEquipmentList]];
    self.request.timeOutSeconds = kASIHttpRequestTimeoutSeconds;
    [self.request setUseCookiePersistence:YES];
    [self.request setPostValue:kSharedApp.accessToken forKey:@"accessToken"];
    [self.request setPostValue:[NSNumber numberWithInt:kSharedApp.finalFactoryId] forKey:@"factoryId"];
    [self.request setPostValue:[NSNumber numberWithInt:100] forKey:@"count"];
    [self.request setPostValue:[NSNumber numberWithInt:currentPage] forKey:@"page"];
    [self.request setDelegate:self];
    [self.request setDidFailSelector:@selector(requestFailed:)];
    [self.request setDidFinishSelector:@selector(requestSuccess:)];
    [self.request startAsynchronous];
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
    self.messageView = [[PromptMessageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight-kStatusBarHeight-kNavBarHeight-kTabBarHeight) message:message];
    [self.view performSelector:@selector(addSubview:) withObject:self.messageView afterDelay:0.5];
    //请求响应后
    NSDictionary *info = @{@"page":[NSNumber numberWithInt:self.currentPage],@"isProgress":@NO};
    self.timer = [NSTimer scheduledTimerWithTimeInterval:delaySeconds target:self selector:@selector(onTimer:) userInfo:info repeats:NO];
}

-(void)requestSuccess:(ASIHTTPRequest *)request{
    NSDictionary *dict = [Tool stringToDictionary:request.responseString];
    int responseCode = [[dict objectForKey:@"error"] intValue];
    if (responseCode==kErrorCode0) {
        if (self.currentPage==1) {
            [self.list removeAllObjects];
        }
        [self.list addObjectsFromArray:[[dict objectForKey:@"data"] objectForKey:@"equipments"]];
        if (self.list.count>0) {
            self.navigationItem.rightBarButtonItem = self.rightButtonItem;
        }
        self.totalCount = [[[dict objectForKey:@"data"] objectForKey:@"totalCount"] intValue];
        [self.tableView reloadData];
    }else if(responseCode==kErrorCodeExpired){
        LoginViewController *loginViewController = (LoginViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
        kSharedApp.window.rootViewController = loginViewController;
    }else{
        
    }
    [self.progressHUD hide:YES];
    
    //请求响应后
    NSDictionary *info = @{@"page":[NSNumber numberWithInt:self.currentPage],@"isProgress":@NO};
    self.timer = [NSTimer scheduledTimerWithTimeInterval:delaySeconds target:self selector:@selector(onTimer:) userInfo:info repeats:NO];
}

-(void)pop:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	[self.progressHUD removeFromSuperview];
	self.progressHUD = nil;
}
@end
