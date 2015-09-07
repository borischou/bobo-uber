//
//  BBHomelistTableViewCell.m
//  Bobo
//
//  Created by Zhouboli on 15/6/12.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import "BBStatusTableViewCell.h"
#import "BBNetworkUtils.h"
#import <UIImageView+WebCache.h>
#import "BBImageBrowserView.h"
#import "NSString+Convert.h"
#import "Utils.h"
#import "BBUpdateStatusView.h"
#import "AppDelegate.h"
#import "WeiboSDK.h"
#import "BBStatusDetailViewController.h"
#import "BBMainStatusTableViewController.h"
#import "BBFavoritesTableViewController.h"
#import "BBProfileTableViewController.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height
#define bAvatarWidth 45
#define bAvatarHeight bAvatarWidth
#define bNicknameWidth [UIScreen mainScreen].bounds.size.width/2
#define bNicknameHeight 20
#define bPostTimeWidth bNicknameWidth
#define bPostTimeHeight 20
#define bTopPadding 10.0
#define bSmallGap 5
#define bBigGap 10
#define bTextFontSize 14.f
#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

#define bPostImgHeight ([UIScreen mainScreen].bounds.size.width-2*bSmallGap)/3
#define bPostImgHeightForTwo ([UIScreen mainScreen].bounds.size.width-2*bSmallGap)/2
#define bPostImgWidth bPostImgHeight
#define bPostImgWidthForTwo bPostImgHeightForTwo

#define bBarHeight bHeight/25
#define bBarSmallGap 7
#define bImageHeight [UIScreen mainScreen].bounds.size.height/25-2*bBarSmallGap
#define bImageWidth bImageHeight
#define bFontSize 12.0

#define bRetweetBGColor [UIColor colorWithRed:30.f/255 green:30.f/255 blue:30.f/255 alpha:1.f]
#define bCellBGColor [UIColor colorWithRed:59.f/255 green:59.f/255 blue:59.f/255 alpha:1.f]

#define bMaleColor [UIColor colorWithRed:0.0/255 green:154.0/255 blue:205.0/255 alpha:1.0] //light blue
#define bFemaleColor [UIColor colorWithRed:255.0/255 green:52.0/255 blue:181.0/255 alpha:1.0] //pink

#define bWeiboDomain @"https://api.weibo.com/2/"

@interface BBStatusTableViewCell ()

@end

@implementation BBStatusTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (self.highlighted) {
        self.contentView.alpha = 0.9;
    } else {
        self.contentView.alpha = 1.0;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initCellLayout];
        [self setupBarButtonsLayout];
    }
    return self;
}

-(void)initCellLayout
{
    self.contentView.backgroundColor = bCellBGColor;
    
    //profile image
    _avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, bAvatarWidth, bAvatarHeight)];
    [self.contentView addSubview:_avatarView];
    
    //nickname
    _nicknameLbl = [[UILabel alloc] initWithFrame:CGRectMake(10+bAvatarWidth+10, 10+5, bNicknameWidth, bNicknameHeight)];
    _nicknameLbl.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_nicknameLbl];
    
    //vip
    _vipView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_vipView];
    
    //post time
    _postTimeLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _postTimeLbl.textColor = [UIColor lightTextColor];
    _postTimeLbl.font = [UIFont systemFontOfSize:10.f];
    [self.contentView addSubview:_postTimeLbl];
    
    //source
    _sourceLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _sourceLbl.textColor = [UIColor lightTextColor];
    [_sourceLbl setFont:[UIFont systemFontOfSize:10.f]];
    [self.contentView addSubview:_sourceLbl];
    
    //text
    _postBodyLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _postBodyLbl.textColor = [UIColor whiteColor];
    _postBodyLbl.numberOfLines = 0;
    _postBodyLbl.lineBreakMode = NSLineBreakByWordWrapping;
    _postBodyLbl.font = [UIFont systemFontOfSize:bTextFontSize];
    [self.contentView addSubview:_postBodyLbl];
    
    //img views for status
    _statusImgViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < 9; i ++) {
        UIImageView *sImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        sImgView.clipsToBounds = YES;
        sImgView.tag = i;
        sImgView.contentMode = UIViewContentModeScaleAspectFill;
        [sImgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusImageTapped:)]];
        sImgView.userInteractionEnabled = YES;
        [_statusImgViews addObject:sImgView];
        [self.contentView addSubview:sImgView];
    }
    //retweet view
    _repostView = [[UIView alloc] initWithFrame:CGRectZero];
    _repostView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repostViewTapped:)];
    [_repostView addGestureRecognizer:tap];
    _repostView.backgroundColor = bRetweetBGColor;
    
    //repost text
    _repostLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _repostLbl.textColor = [UIColor whiteColor];
    _repostLbl.numberOfLines = 0;
    _repostLbl.lineBreakMode = NSLineBreakByWordWrapping;
    _repostLbl.font = [UIFont systemFontOfSize:bTextFontSize];
    [_repostView addSubview:_repostLbl];
    
    //img views for retweeted_status
    _imgViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < 9; i ++) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imgView.clipsToBounds = YES;
        imgView.tag = i;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        [imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repostImageTapped:)]];
        imgView.userInteractionEnabled = YES;
        [_imgViews addObject:imgView];
        [_repostView addSubview:imgView];
    }
    [self.contentView addSubview:_repostView];
}

-(void)setupBarButtonsLayout
{
    self.contentView.backgroundColor = bCellBGColor;
    
    _retweetImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _retweetImageView.image = [UIImage imageNamed:@"retwt_icon"];
    _retweetImageView.userInteractionEnabled = YES;
    [_retweetImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retweetImageViewTapped)]];
    [self.contentView addSubview:_retweetImageView];
    
    _retweetCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _retweetCountLabel.textColor = [UIColor lightTextColor];
    _retweetCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_retweetCountLabel];
    
    _commentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _commentImageView.image = [UIImage imageNamed:@"cmt_icon"];
    _commentImageView.clipsToBounds = YES;
    _commentImageView.userInteractionEnabled = YES;
    [_commentImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentImageViewTapped)]];
    [self.contentView addSubview:_commentImageView];
    
    _commentCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _commentCountLabel.textColor = [UIColor lightTextColor];
    _commentCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_commentCountLabel];
    
    _likeImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _likeImageView.image = [UIImage imageNamed:@"like_icon_2"];
    _likeImageView.clipsToBounds = YES;
    _likeImageView.userInteractionEnabled = YES;
    [_likeImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likeImageViewTapped)]];
    [self.contentView addSubview:_likeImageView];
    
    _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _likeCountLabel.textColor = [UIColor lightTextColor];
    _likeCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_likeCountLabel];
    
    _favoritesImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _favoritesImageView.image = [UIImage imageNamed:@"fav_icon_3"];
    _favoritesImageView.clipsToBounds = YES;
    _favoritesImageView.userInteractionEnabled = YES;
    [_favoritesImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favoritesImageViewTapped)]];
    [self.contentView addSubview:_favoritesImageView];
}

-(void)retweetImageViewTapped
{
    NSLog(@"retweetImageViewTapped");
    BBUpdateStatusView *updateStatusView = [[BBUpdateStatusView alloc] initWithFlag:2]; //转发
    updateStatusView.idStr = _status.idstr;
    updateStatusView.nameLabel.text = @"转发";
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.window addSubview:updateStatusView];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        updateStatusView.frame = CGRectMake(bSmallGap, statusBarHeight+bSmallGap, bWidth-2*bSmallGap, bHeight/2-5);
        [updateStatusView.statusTextView becomeFirstResponder];
    } completion:^(BOOL finished) {
        if (finished) {
            //what are you gonna do
        }
    }];
}

-(void)commentImageViewTapped
{
    NSLog(@"commentImageViewTapped");
    BBUpdateStatusView *updateStatusView = [[BBUpdateStatusView alloc] initWithFlag:1]; //写评论
    updateStatusView.idStr = _status.idstr;
    updateStatusView.nameLabel.text = _status.user.screen_name;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.window addSubview:updateStatusView];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        updateStatusView.frame = CGRectMake(bSmallGap, statusBarHeight+bSmallGap, bWidth-2*bSmallGap, bHeight/2-5);
        [updateStatusView.statusTextView becomeFirstResponder];
    } completion:^(BOOL finished) {
        if (finished) {
            //what are you gonna do
        }
    }];
}

-(void)likeImageViewTapped
{
    NSLog(@"likeImageViewTapped");
}

-(void)favoritesImageViewTapped
{
    NSLog(@"favoritesImageViewTapped");
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!delegate.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:@"未登录" message:@"Please log in first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    else
    {
        if (_status.favorited) {
            [_favoritesImageView setImage:[UIImage imageNamed:@"fav_icon_3"]];
            NSMutableDictionary *params = @{}.mutableCopy;
            [params setObject:delegate.wbToken forKey:@"access_token"];
            [params setObject:_status.idstr forKey:@"id"];
            NSString *url = [bWeiboDomain stringByAppendingString:@"favorites/destroy.json"];
            [WBHttpRequest requestWithURL:url httpMethod:@"POST" params:params queue:nil withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                if (!error) {
                    NSLog(@"收藏已删除。");
                    [_status setFavorited:NO];
                }
                else
                {
                    NSLog(@"收藏删除失败：%@", error);
                }
            }];
        }
        else
        {
            [_favoritesImageView setImage:[UIImage imageNamed:@"faved_icon"]];
            NSMutableDictionary *params = @{}.mutableCopy;
            [params setObject:delegate.wbToken forKey:@"access_token"];
            [params setObject:_status.idstr forKey:@"id"];
            NSString *url = [bWeiboDomain stringByAppendingString:@"favorites/create.json"];
            [WBHttpRequest requestWithURL:url httpMethod:@"POST" params:params queue:nil withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                if (!error) {
                    NSLog(@"收藏成功。");
                    [_status setFavorited:YES];
                }
                else
                {
                    NSLog(@"收藏失败：%@", error);
                }
            }];
        }
    }
}

-(void)statusImageTapped:(UITapGestureRecognizer *)tap
{
    NSMutableArray *largeUrls = @[].mutableCopy;
    for (NSString *str in _status.pic_urls) {
        [largeUrls addObject:[NSString largePictureUrlConvertedFromThumbUrl:str]];
    }
    [self setImageBrowserWithImageUrls:largeUrls andTappedViewTag:tap.view.tag];
}

-(void)repostImageTapped:(UITapGestureRecognizer *)tap
{
    NSMutableArray *largeUrls = @[].mutableCopy;
    for (NSString *str in _status.retweeted_status.pic_urls) {
        [largeUrls addObject:[NSString largePictureUrlConvertedFromThumbUrl:str]];
    }
    [self setImageBrowserWithImageUrls:largeUrls andTappedViewTag:tap.view.tag];
}

-(void)repostViewTapped:(UITapGestureRecognizer *)tap
{
    BBStatusDetailViewController *dtvc = [[BBStatusDetailViewController alloc] init];
    dtvc.title = @"Detail";
    dtvc.hidesBottomBarWhenPushed = YES;
    dtvc.status = _status.retweeted_status;
    
    id tableViewController = [[[self nextResponder] nextResponder] nextResponder];
    id detailTableViewController = [tableViewController nextResponder];

    if ([tableViewController isKindOfClass:[BBMainStatusTableViewController class]] || [tableViewController isKindOfClass:[BBProfileTableViewController class]] || [tableViewController isKindOfClass:[BBFavoritesTableViewController class]]) {
        BBMainStatusTableViewController *mstvc = (BBMainStatusTableViewController *)tableViewController;
        [mstvc.navigationController pushViewController:dtvc animated:YES];
    }
    if ([detailTableViewController isKindOfClass:[BBStatusDetailViewController class]]) {
        BBStatusDetailViewController *sdvc = (BBStatusDetailViewController *)detailTableViewController;
        [sdvc.navigationController pushViewController:dtvc animated:YES];
    }
}

//override this method to load views dynamically
-(void)layoutSubviews
{
    [super layoutSubviews];
    [self setStatusData];
    [self setCellLayout];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
}

-(void)setStatusData
{
    //status
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:_status.user.avatar_large] placeholderImage:[UIImage imageNamed:@"bb_holder_profile_image"] options:SDWebImageLowPriority];
    
    _nicknameLbl.text = _status.user.screen_name;
    if ([_status.user.gender isEqualToString:@"m"]) {
        [_nicknameLbl setTextColor:bMaleColor];
    }
    if ([_status.user.gender isEqualToString:@"f"]) {
        [_nicknameLbl setTextColor:bFemaleColor];
    }
    if ([_status.user.gender isEqualToString:@"n"]) {
        [_nicknameLbl setTextColor:[UIColor lightTextColor]];
    }
    
    _postTimeLbl.text = [Utils formatPostTime:_status.created_at];
    _sourceLbl.text = [NSString trim:_status.source];
    _postBodyLbl.text = _status.text;
    
    if (_status.pic_urls.count > 0) {
        for (int i = 0; i < [_status.pic_urls count]; i ++) {
            if ([_status.pic_urls[i] hasSuffix:@"gif"]) {
                [_statusImgViews[i] sd_setImageWithURL:[NSURL URLWithString:_status.pic_urls[i]] placeholderImage:[UIImage imageNamed:@"pic_placeholder"]];
            } else {
                [_statusImgViews[i] sd_setImageWithURL:[NSURL URLWithString:[NSString largePictureUrlConvertedFromThumbUrl:_status.pic_urls[i]]] placeholderImage:[UIImage imageNamed:@"pic_placeholder"]];
            }
        }
    }
    
    //repost status
    _repostLbl.text = [NSString stringWithFormat:@"@%@:%@", _status.retweeted_status.user.screen_name, _status.retweeted_status.text];
    
    if (_status.retweeted_status.pic_urls.count > 0) {
        for (int i = 0; i < [_status.retweeted_status.pic_urls count]; i ++) {
            if ([_status.retweeted_status.pic_urls[i] hasSuffix:@"gif"]) {
                [_imgViews[i] sd_setImageWithURL:[NSURL URLWithString:_status.retweeted_status.pic_urls[i]] placeholderImage:[UIImage imageNamed:@"pic_placeholder"]];
            } else {
                [_imgViews[i] sd_setImageWithURL:[NSURL URLWithString:[NSString largePictureUrlConvertedFromThumbUrl:_status.retweeted_status.pic_urls[i]]] placeholderImage:[UIImage imageNamed:@"pic_placeholder"]];
            }
        }
    }
    
    //barbuttons
    _retweetCountLabel.text = [NSString getNumStrFrom:_status.reposts_count];
    _commentCountLabel.text = [NSString getNumStrFrom:_status.comments_count];
    _likeCountLabel.text = [NSString getNumStrFrom:_status.attitudes_count];
    
    if (_status.favorited) {
        _favoritesImageView.image = [UIImage imageNamed:@"faved_icon"];
    } else {
        _favoritesImageView.image = [UIImage imageNamed:@"fav_icon_3"];
    }
}

-(void)setCellLayout
{
    //vip
    if (_status.user.verified) {
        CGSize nameSize = [_nicknameLbl sizeThatFits:CGSizeMake(MAXFLOAT, bNicknameHeight)];
        [_vipView setFrame:CGRectMake(10+bAvatarWidth+10+nameSize.width, 10+5, 15, 15)];
        [_vipView setImage:[UIImage imageNamed:@"icon_vip"]];
    } else {
        [_vipView setFrame:CGRectZero];
        [_vipView setImage:nil];
    }
    
    //时间
    CGSize timeSize = [_postTimeLbl sizeThatFits:CGSizeMake(MAXFLOAT, bPostTimeHeight)];
    [_postTimeLbl setFrame:CGRectMake(10+bAvatarWidth+10, 10+5+bNicknameHeight+3, timeSize.width, bPostTimeHeight)];
    
    //来源
    CGSize sourceSize = [_sourceLbl sizeThatFits:CGSizeMake(MAXFLOAT, bPostTimeHeight)];
    [_sourceLbl setFrame:CGRectMake(10+bAvatarWidth+10+timeSize.width+10, 10+5+bNicknameHeight+3, sourceSize.width, bPostTimeHeight)];
    
    //微博正文
    CGSize postSize = [_postBodyLbl sizeThatFits:CGSizeMake(bWidth-2*bBigGap, MAXFLOAT)];
    _postBodyLbl.frame = CGRectMake(bBigGap, bBigGap+bAvatarHeight+bBigGap, bWidth-bBigGap*2, postSize.height);
    
    _repostView.hidden = YES;
    if (_status.retweeted_status) {
        
        //转发微博
        _repostView.hidden = NO;
        [self resetImageViews:_statusImgViews];
        CGSize repostSize = [_repostLbl sizeThatFits:CGSizeMake(bWidth-2*bBigGap, MAXFLOAT)];
        [_repostLbl setFrame:CGRectMake(bBigGap, 0, bWidth-2*bBigGap, repostSize.height)];
        [Utils layoutImgViews:_imgViews withImageCount:[_status.retweeted_status.pic_urls count] fromTopHeight:repostSize.height];
        
        [_repostView setFrame:CGRectMake(0, bBigGap + bAvatarHeight + bBigGap + postSize.height + bBigGap, bWidth, repostSize.height + bSmallGap + [Utils heightForImgsWithCount:[_status.retweeted_status.pic_urls count]])];        
    }
    else
    {
        //微博配图
        _repostView.hidden = YES;
        [Utils layoutImgViews:_statusImgViews withImageCount:[_status.pic_urls count] fromTopHeight:bBigGap+bAvatarHeight+bBigGap+postSize.height];
    }
    [self layoutBarButtonsWithTop:_status.height-bBarHeight];
}

-(void)layoutBarButtonsWithTop:(CGFloat)top
{
    [_retweetImageView setFrame:CGRectMake(bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize rsize = [_retweetCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_retweetCountLabel setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap, top+bBarSmallGap, rsize.width, bImageHeight)];
    
    [_commentImageView setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap+_retweetCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize csize = [_commentCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_commentCountLabel setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap+_retweetCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap, top+bBarSmallGap, csize.width, bImageHeight)];
    
    [_likeImageView setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap+_retweetCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap+_commentCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize lsize = [_likeCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_likeCountLabel setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap+_retweetCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap+_commentCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap, top+bBarSmallGap, lsize.width, bImageHeight)];
    
    [_favoritesImageView setFrame:CGRectMake(bBigGap+bImageWidth+bSmallGap+_retweetCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap+_commentCountLabel.frame.size.width+bBigGap+bImageWidth+bSmallGap+_likeCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];

}

-(void)resetImageViews:(NSMutableArray *)views
{
    for (int i = 0; i < [views count]; i ++) {
        [views[i] setFrame:CGRectZero];
    }
}

-(void)setImageBrowserWithImageUrls:(NSMutableArray *)urls andTappedViewTag:(NSInteger)tag
{
    BBImageBrowserView *browserView = [[BBImageBrowserView alloc] initWithFrame:[UIScreen mainScreen].bounds withImageUrls:urls andImageTag:tag];
    [self.window addSubview:browserView];
}

@end
