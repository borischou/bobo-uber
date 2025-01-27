//
//  BBUpdateStatusView.h
//  Bobo
//
//  Created by Zhouboli on 15/8/12.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Status.h"
#import "Comment.h"
#import "Draft.h"

typedef NS_ENUM(NSInteger, updateStatusType)
{
    updateStatusTypePost,
    updateStatusTypeComment,
    updateStatusTypeRepost,
    updateStatusTypeReply
};

@class BBUpdateStatusView;
@protocol BBUpdateStatusViewDelegate <NSObject>

@optional
-(void)updateStatusView:(BBUpdateStatusView *)updateStatusView shouldDeleteDraftAt:(NSString *)time;
-(void)updateStatusView:(BBUpdateStatusView *)updateStatusView shouldDisplayComment:(Comment *)comment;

@end

@interface BBUpdateStatusView : UIView

@property (weak, nonatomic) id <BBUpdateStatusViewDelegate> delegate;

@property (strong, nonatomic) UILabel *todoLabel;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *countLabel;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *sendBtn;
@property (strong, nonatomic) UITextView *statusTextView;

@property (strong, nonatomic) NSMutableArray *pickedOnes;
@property (strong, nonatomic) Status *status;
@property (strong, nonatomic) Comment *comment;
@property (strong, nonatomic) Draft *draft;
@property (assign, nonatomic) BOOL isDetail;

-(instancetype)initWithFlag:(NSInteger)flag; //0-发微博; 1-写评论; 2-转发; 3-回复评论

@end
