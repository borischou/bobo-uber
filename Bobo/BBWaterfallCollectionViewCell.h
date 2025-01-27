//
//  BBWaterfallCollectionViewCell.h
//  Bobo
//
//  Created by Boris Chow on 8/25/15.
//  Copyright (c) 2015 Zhouboli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel.h>
#import "Status.h"

@class BBWaterfallCollectionViewCell;
@protocol BBWaterfallCollectionViewCellDelegate <NSObject>

-(void)collectionViewCell:(BBWaterfallCollectionViewCell *)cell didTapCoverpicture:(UIImageView *)coverpicture;

@end

@interface BBWaterfallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) id <BBWaterfallCollectionViewCellDelegate> delegate;

@property (strong, nonatomic) Status *status;

@property (strong, nonatomic) UIImageView *avatarView;

//博主图片或转发图片
@property (strong, nonatomic) UIImageView *coverImageView;

//博主微博信息
//@property (strong, nonatomic) STTweetLabel *tweetTextLabel;
@property (strong, nonatomic) TTTAttributedLabel *tweetTextLabel;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UILabel *retweetNumLabel;
@property (strong, nonatomic) UILabel *commentNumLabel;

//转发微博信息
//@property (strong, nonatomic) STTweetLabel *retweetTextLabel;
@property (strong, nonatomic) TTTAttributedLabel *retweetTextLabel;
@property (strong, nonatomic) UILabel *retweetNameLabel;
@property (strong, nonatomic) UIImageView *retweetIcon;
@property (strong, nonatomic) UIImageView *commentIcon;

@property (strong, nonatomic) UIImageView *gifView;
@property (strong, nonatomic) UIView *mask;

@end
