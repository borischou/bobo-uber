//
//  BBMessageTableViewController.m
//  Bobo
//
//  Created by Zhouboli on 15/9/2.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import "BBMessageViewController.h"
#import "BBMessageTableView.h"
#import <MJRefresh/MJRefresh.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "Utils.h"
#import "AppDelegate.h"
#import "Comment.h"
#import "BBMessageMenuView.h"

#define bWeiboDomain @"https://api.weibo.com/2/"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define mMenuHeight 35
#define mTableViewHeight bHeight-mMenuHeight-49-44-[UIApplication sharedApplication].statusBarFrame.size.height

@interface BBMessageViewController () <UIScrollViewDelegate, BBMessageMenuViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) BBMessageMenuView *menuView;
@property (strong, nonatomic) BBMessageTableView *messageTableView;
@property (strong, nonatomic) BBMessageTableView *byMeTableView;
@property (strong, nonatomic) BBMessageTableView *mentionTableView;
@property (strong, nonatomic) BBMessageTableView *allTableView;

@property (copy, nonatomic) NSMutableArray *maxids;
@property (copy, nonatomic) NSMutableArray *sinceids;
@property (copy, nonatomic) NSString *uri;

@property (strong, nonatomic) ACAccount *weiboAccount;

@end

@implementation BBMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _weiboAccount = [[AppDelegate delegate] defaultAccount];
    
    _uri = @"to_me";
    _maxids = @[[NSNull null], [NSNull null], [NSNull null], [NSNull null]].mutableCopy;
    _sinceids = @[[NSNull null], [NSNull null], [NSNull null], [NSNull null]].mutableCopy;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, mMenuHeight, bWidth, mTableViewHeight)];
    _scrollView.contentSize = CGSizeMake(bWidth*4, mTableViewHeight);
    _scrollView.delegate = self;
    _scrollView.bounces = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    
    _messageTableView = [[BBMessageTableView alloc] initWithFrame:CGRectMake(0, 0, bWidth, mTableViewHeight) style:UITableViewStyleGrouped];
    [_scrollView addSubview:_messageTableView];
    
    _menuView = [[BBMessageMenuView alloc] init];
    _menuView.delegate = self;
    [self.view addSubview:_menuView];
    
    [self setMJRefreshWithTableView:_messageTableView flag:0];
    [_messageTableView.header beginRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BBMessageMenuViewDelegate

-(void)didClickMenuButtonAtIndex:(NSInteger)index
{
    [_scrollView setContentOffset:CGPointMake(index*bWidth, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate & support

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self loadTableViewInScrollView:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadTableViewInScrollView:scrollView];
}

-(void)loadTableViewInScrollView:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x == 0) { //to_me
        [_menuView moveLineAccordingToFlag:0];
        _uri = @"to_me";
        if (!_messageTableView) {
            _messageTableView = [[BBMessageTableView alloc] initWithFrame:CGRectMake(0, 0, bWidth, mTableViewHeight) style:UITableViewStyleGrouped];
            [scrollView addSubview:_messageTableView];
            [self setMJRefreshWithTableView:_messageTableView flag:0];
            [_messageTableView.header beginRefreshing];
        }
    }
    if (scrollView.contentOffset.x == bWidth) { //by_me
        [_menuView moveLineAccordingToFlag:1];
        _uri = @"by_me";
        if (!_byMeTableView) {
            _byMeTableView = [[BBMessageTableView alloc] initWithFrame:CGRectMake(bWidth, 0, bWidth, mTableViewHeight) style:UITableViewStyleGrouped];
            [scrollView addSubview:_byMeTableView];
            [self setMJRefreshWithTableView:_byMeTableView flag:1];
            [_byMeTableView.header beginRefreshing];
        }
    }
    if (scrollView.contentOffset.x == bWidth*2) { //mentions
        [_menuView moveLineAccordingToFlag:2];
        _uri = @"mentions";
        if (!_mentionTableView) {
            _mentionTableView = [[BBMessageTableView alloc] initWithFrame:CGRectMake(bWidth*2, 0, bWidth, mTableViewHeight) style:UITableViewStyleGrouped];
            [scrollView addSubview:_mentionTableView];
            [self setMJRefreshWithTableView:_mentionTableView flag:2];
            [_mentionTableView.header beginRefreshing];
        }
    }
    if (scrollView.contentOffset.x == bWidth*3) { //timeline
        [_menuView moveLineAccordingToFlag:3];
        _uri = @"timeline";
        if (!_allTableView) {
            _allTableView = [[BBMessageTableView alloc] initWithFrame:CGRectMake(bWidth*3, 0, bWidth, mTableViewHeight) style:UITableViewStyleGrouped];
            [scrollView addSubview:_allTableView];
            [self setMJRefreshWithTableView:_allTableView flag:3];
            [_allTableView.header beginRefreshing];
        }
    }
}

#pragma mark - Weibo support

-(void)setMJRefreshWithTableView:(BBMessageTableView *)tableView flag:(NSInteger)flag
{
    tableView.header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self fetchLatestCommentsWithTableView:tableView flag:flag];
    }];
    MJRefreshBackNormalFooter *footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        [self fetchHistoryCommentsWithTableView:tableView flag:flag];
    }];
    [footer setTitle:@"上拉以获取更早微博" forState:MJRefreshStateIdle];
    [footer setTitle:@"正在获取" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"暂无更多数据" forState:MJRefreshStateNoMoreData];
    tableView.footer = footer;
}

-(void)handleWeiboResult:(id)result type:(NSString *)type forTableView:(BBMessageTableView *)tableView flag:(NSInteger)flag
{
    if ([type isEqualToString:@"refresh"]) { //下拉刷新最新消息
        NSArray *downloadedComments = [result objectForKey:@"comments"];
        if (downloadedComments.count > 0) {
            for (int i = 0; i < [downloadedComments count]; i ++) {
                Comment *tmp_comment = [[Comment alloc] initWithDictionary:downloadedComments[i]];
                [tableView.comments insertObject:tmp_comment atIndex:i];
            }
            NSDictionary *lastone = downloadedComments.lastObject;
            _maxids[flag] = lastone[@"idstr"];
            NSDictionary *firstone = downloadedComments.firstObject;
            _sinceids[flag] = firstone[@"idstr"];
        }
        [tableView.header endRefreshing];
    }
    
    if ([type isEqualToString:@"history"]) { //上拉刷新历史消息
        NSArray *historyMessages = [result objectForKey:@"statuses"];
        if (historyMessages.count > 0) {
            for (int i = 1; i < [historyMessages count]; i ++) {
                Comment *tmp_comment = [[Comment alloc] initWithDictionary:historyMessages[i]];
                [tableView.comments addObject:tmp_comment];
            }
            NSDictionary *lastone = historyMessages.lastObject;
            _maxids[flag] = lastone[@"idstr"];
        }
        [tableView.footer endRefreshing];
    }
    [tableView reloadData];
    NSLog(@"The currentLastStatusId is: %@", _maxids[flag]);
}

-(void)fetchLatestCommentsWithTableView:(BBMessageTableView *)tableView flag:(NSInteger)flag
{
    NSString *url;
    if ([_sinceids[flag] isEqual:[NSNull null]]) {
        url = [NSString stringWithFormat:@"comments/%@.json", _uri];
    } else {
        url = [NSString stringWithFormat:@"comments/%@.json?since_id=%@", _uri, _sinceids[flag]];
    }
    [Utils genericWeiboRequestWithAccount:_weiboAccount URL:url SLRequestHTTPMethod:SLRequestMethodGET parameters:nil completionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
        if ([_uri isEqualToString:@"to_me"]) {
            [self handleWeiboResult:result type:@"refresh" forTableView:_messageTableView flag:0];
        }
        if ([_uri isEqualToString:@"by_me"]) {
            [self handleWeiboResult:result type:@"refresh" forTableView:_byMeTableView flag:1];
        }
        if ([_uri isEqualToString:@"mentions"]) {
            [self handleWeiboResult:result type:@"refresh" forTableView:_mentionTableView flag:2];
        }
        if ([_uri isEqualToString:@"timeline"]) {
            [self handleWeiboResult:result type:@"refresh" forTableView:_allTableView flag:3];
        }
    } completionBlockWithFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"message error: %@", [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [Utils presentNotificationWithText:@"更新失败"];
            [tableView.header endRefreshing];
        });
        
    }];
}

-(void)fetchHistoryCommentsWithTableView:(BBMessageTableView *)tableView flag:(NSInteger)flag
{
    [Utils genericWeiboRequestWithAccount:_weiboAccount URL:[NSString stringWithFormat:@"comments/%@.json?max_id=%@&count=20", _uri, _maxids[flag]] SLRequestHTTPMethod:SLRequestMethodGET parameters:nil completionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
        if ([_uri isEqualToString:@"to_me"]) {
            [self handleWeiboResult:result type:@"history" forTableView:_messageTableView flag:0];
        }
        if ([_uri isEqualToString:@"by_me"]) {
            [self handleWeiboResult:result type:@"history" forTableView:_byMeTableView flag:1];
        }
        if ([_uri isEqualToString:@"mentions"]) {
            [self handleWeiboResult:result type:@"history" forTableView:_mentionTableView flag:2];
        }
        if ([_uri isEqualToString:@"timeline"]) {
            [self handleWeiboResult:result type:@"history" forTableView:_allTableView flag:3];
        }
    } completionBlockWithFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Utils presentNotificationWithText:@"更新失败"];
            [tableView.footer endRefreshing];
        });
        
    }];
}

@end
