//
//  BBCollectionTableViewController.m
//  Bobo
//
//  Created by Zhouboli on 15/8/7.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import "BBFavoritesTableViewController.h"
#import "BLRefreshGifHeader.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bBtnHeight bHeight/25
#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height
#define uSmallGap 5
#define uBigGap 10
#define bBtnBGColor [UIColor colorWithRed:47.f/255 green:79.f/255 blue:79.f/255 alpha:1.f]

#define bWeiboDomain @"https://api.weibo.com/2/"

@interface BBFavoritesTableViewController () <BBStatusTableViewCellDelegate, TTTAttributedLabelDelegate, UITabBarControllerDelegate>
{
    int _page;
}

@end

@implementation BBFavoritesTableViewController

#pragma mark - View Controller life cycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    _page = 1;
    _weiboAccount = [[AppDelegate delegate] defaultAccount];
    [self setNavBarBtn];
    [self setMJRefresh];
    [self.tableView.header beginRefreshing];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.tabBarController.delegate = self;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.tabBarController.delegate = nil;
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"让圣光净化一切！");
    [Utils clearImageCache];
    [Utils clearDiskImages];
}

#pragma mark - Helpers

-(void)navigateToSettings
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"提示" message:@"您尚未在系统设置中登录您的新浪微博账号，请在设置中登录您的新浪微博账号后再打开Friends浏览微博内容。是否跳转到系统设置？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[Utils preferenceSinaWeiboURL]]];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
    {
        //取消
    }];
    [ac addAction:settingsAction];
    [ac addAction:cancelAction];
    [self.navigationController presentViewController:ac animated:YES completion:^{}];
}

-(void)setMJRefresh
{
    self.tableView.header = [BLRefreshGifHeader headerWithRefreshingBlock:^{
        if (!_weiboAccount)
        {
            _weiboAccount = [[AppDelegate delegate] validWeiboAccount];
            if (_weiboAccount)
            {
                _page = 1;
                [self fetchFavoriteStatuses];
            }
            else
            {
                [self.tableView.header endRefreshing];
                [self navigateToSettings];
                [Utils presentNotificationWithText:@"更新失败"];
            }
        }
        else
        {
            _page = 1;
            [self fetchFavoriteStatuses];
        }
    }];
    MJRefreshBackNormalFooter *footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(fetchFavoriteStatuses)];
    [footer setTitle:@"上拉以获取更早微博" forState:MJRefreshStateIdle];
    [footer setTitle:@"正在获取" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"暂无更多数据" forState:MJRefreshStateNoMoreData];
    self.tableView.footer = footer;
}

-(void)setNavBarBtn
{
    UIButton *postBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    postBtn.frame = CGRectMake(0, 0, 23, 23);
    [postBtn setImage:[UIImage imageNamed:@"barbutton_icon_post"] forState:UIControlStateNormal];
    [postBtn addTarget:self action:@selector(postBarbuttonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *postBarBtn = [[UIBarButtonItem alloc] initWithCustomView:postBtn];
    self.navigationItem.rightBarButtonItem = postBarBtn;
}

#pragma mark - UIButtons

-(void)postBarbuttonPressed
{
    AppDelegate *delegate = [AppDelegate delegate];
    BBUpdateStatusView *updateStatusView = [[BBUpdateStatusView alloc] initWithFlag:0]; //0: 发微博
    updateStatusView.nameLabel.text = delegate.user.screen_name;
    [delegate.window addSubview:updateStatusView];
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        updateStatusView.frame = CGRectMake(uSmallGap, statusBarHeight+uSmallGap, bWidth-2*uSmallGap, bHeight/2-5);
        [updateStatusView.statusTextView becomeFirstResponder];
    } completion:^(BOOL finished) {}];
}

#pragma mark - Weibo support

//https://api.weibo.com/2/favorites.json?count=count_num&page=page_num
-(void)fetchFavoriteStatuses
{
    [Utils genericWeiboRequestWithAccount:_weiboAccount URL:[NSString stringWithFormat:@"favorites.json?count=20&page=%d", _page] SLRequestHTTPMethod:SLRequestMethodGET parameters:nil completionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSError *error = nil;
        [self handleWeiboResult:[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error]];
    }
               completionBlockWithFailure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"favoristes error: %@", [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [Utils presentNotificationWithText:@"更新失败"];
            [self.tableView.header endRefreshing];
            [self.tableView.footer endRefreshing];
        });
        
    }];
}

-(void)handleWeiboResult:(id)result
{
    NSDictionary *resultDict = result;
    if (![[resultDict objectForKey:@"favorites"] isEqual:[NSNull null]])
    {
        NSArray *favArray = [resultDict objectForKey:@"favorites"];
        if (favArray.count > 0)
        {
            if (!_statuses) {
                _statuses = @[].mutableCopy;
            }
            if (_page == 1) {
                _statuses = nil;
                _statuses = @[].mutableCopy;
            }
            for (int i = 0; i < favArray.count; i ++)
            {
                if (![[favArray[i] objectForKey:@"status"] isEqual:[NSNull null]])
                {
                    Status *status = [[Status alloc] initWithDictionary:[favArray[i] objectForKey:@"status"]];
                    [_statuses addObject:status];
                }
            }
            _page += 1;
        }
    }
    [self.tableView.header endRefreshing];
    [self.tableView.footer endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - UITabBarControllerDelegate

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    AppDelegate *delegate = [AppDelegate delegate];
    if (delegate.currentIndex == tabBarController.selectedIndex)
    {
        [self.tableView.header beginRefreshing];
    }
    delegate.currentIndex = tabBarController.selectedIndex;
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                    withVelocity:(CGPoint)velocity
             targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (fabs(targetContentOffset->y+bHeight-self.tableView.contentSize.height) <= 250)
    {
        [self fetchFavoriteStatuses];
    }
}

#pragma mark - UITableView data source & delegate & Helpers

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_statuses count])
    {
        return [_statuses count];
    }
    else
    {
        return 0;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_statuses count])
    {
        Status *status = [_statuses objectAtIndex:indexPath.section];
        return status.height;
    }
    else
    {
        return 0;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView registerClass:[BBStatusTableViewCell class] forCellReuseIdentifier:@"home"];
    BBStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"home" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([_statuses count])
    {
        if ([_statuses count])
        {
            Status *status = [self.statuses objectAtIndex:indexPath.section];
            cell.status = status;
            cell.delegate = self;
            cell.tweetTextLabel.delegate = self;
            cell.retweetTextLabel.delegate = self;
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BBStatusDetailViewController *dtvc = [[BBStatusDetailViewController alloc] init];
    dtvc.title = @"Detail";
    dtvc.hidesBottomBarWhenPushed = YES;
    Status *status = [_statuses objectAtIndex:indexPath.section];
    dtvc.status = status;
    [self.navigationController pushViewController:dtvc animated:YES];
}

#pragma mark - TTTAttributedLabelDelegate & support

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result
{
    NSLog(@"pressed: %@", [label.text substringWithRange:result.range]);
    [self presentDetailViewWithHotword:[label.text substringWithRange:result.range]];
}

-(void)attributedLabel:(TTTAttributedLabel *)label didLongPressLinkWithTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point
{
    NSLog(@"long pressed: %@", [label.text substringWithRange:result.range]);
    [self presentDetailViewWithHotword:[label.text substringWithRange:result.range]];
}

-(void)presentDetailViewWithHotword:(NSString *)hotword
{
    if ([hotword hasPrefix:@"@"]) {
        NSDictionary *params = @{@"screen_name": [hotword substringFromIndex:1]};
        [Utils genericWeiboRequestWithAccount:[[AppDelegate delegate] defaultAccount]
                                          URL:@"statuses/user_timeline.json"
                          SLRequestHTTPMethod:SLRequestMethodGET
                                   parameters:params
                   completionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSMutableArray *statuses = [Utils statusesWith:responseObject];
             Status *status = statuses.firstObject;
             User *user = status.user;
             
             BBProfileTableViewController *profiletvc = [[BBProfileTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
             [Utils setupNavigationController:self.navigationController withUIViewController:profiletvc];
             profiletvc.uid = user.idstr;
             profiletvc.statuses = statuses;
             profiletvc.user = user;
             profiletvc.shouldNavBtnShown = NO;
             profiletvc.title = @"Profile";
             profiletvc.hidesBottomBarWhenPushed = YES;
             [self.navigationController pushViewController:profiletvc animated:YES];
         }
                   completionBlockWithFailure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"error %@", error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [Utils presentNotificationWithText:@"访问失败"];
             });
         }];
    }
    if ([hotword hasPrefix:@"http"])
    {
        //打开webview
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[hotword stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
        [self.navigationController presentViewController:sfvc animated:YES completion:^{}];
    }
    if ([hotword hasPrefix:@"#"])
    {
        //热门话题
    }
}

@end