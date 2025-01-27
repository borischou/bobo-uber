//
//  BBImageBrowserView.m
//  Bobo
//
//  Created by Zhouboli on 15/6/25.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import "BBImageBrowserView.h"
#import <YYWebImage.h>
#import "Utils.h"
#import "UIColor+Custom.h"
#import "BBProgressView.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

@interface BBImageBrowserView () <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIPageControl *pageControl; //图片数量不超过9张时显示page control
@property (assign, nonatomic) NSInteger count;
@property (assign, nonatomic) NSInteger imageTag;
@property (assign, nonatomic) BOOL saved;

@property (strong, nonatomic) UITapGestureRecognizer *singleTap;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@end

@implementation BBImageBrowserView

-(instancetype)initWithFrame:(CGRect)frame imageUrls:(NSMutableArray *)urls imageTag:(NSInteger)tag
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.0;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = 1.0;
        } completion:^(BOOL finished) {}];
        _imageTag = tag;
        _count = [urls count];
        _saved = NO;
        [self loadMainScrollViewWithImages:urls viewTag:tag];
        
        if (urls.count <= 9 && urls.count > 1) {
            [self loadPageControl];
        }
    }
    return self;
}

-(void)loadProgressView:(YYAnimatedImageView *)imageView url:(NSString *)url originX:(CGFloat)originX scrollView:(UIScrollView *)scrollView
{
    BBProgressView *progressView = [[BBProgressView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    progressView.center = CGPointMake(bWidth/2, bHeight/2);
    [scrollView addSubview:progressView];
    
    [imageView yy_setImageWithURL:[NSURL URLWithString:url] placeholder:nil options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation progress:^(NSInteger receivedSize, NSInteger expectedSize)
     {
         //转换为百分比进度传入progress view
         float progress = fabsf((float)receivedSize/(float)expectedSize);
         [progressView setPercent:progress];
     }
                        transform:nil
                       completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
     {
         if (!error)
         {
             [progressView removeFromSuperview];
             [self resizeImage:image imageView:imageView originX:originX scrollView:scrollView];
         }
     }];
}

-(void)loadMainScrollViewWithImages:(NSMutableArray *)urls viewTag:(NSInteger)tag
{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, bWidth, bHeight)];
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeMake(bWidth*(2+_count), bHeight);
    _scrollView.contentOffset = CGPointMake(bWidth*(tag+1), 0);
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.userInteractionEnabled = YES;
    _scrollView.alwaysBounceVertical = NO;
    _scrollView.alwaysBounceHorizontal = YES;
    
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapped:)];
    [_scrollView addGestureRecognizer:_singleTap];
    [self addSubview:_scrollView];
    
    //第一个UIImageView放最后一张图
    [self loadSubScrollViewWithImage:urls.lastObject originX:0];
    
    //第二个UIImageView开始顺序放图
    for (int i = 0; i < [urls count]; i ++)
    {
        [self loadSubScrollViewWithImage:urls[i] originX:bWidth*(i+1)];
    }
    
    //最后一个UIImageView放第一张图
    [self loadSubScrollViewWithImage:urls.firstObject originX:bWidth*(1+urls.count)];
}

-(void)loadSubScrollViewWithImage:(NSString *)url originX:(CGFloat)originX
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(originX, 0, bWidth, bHeight)];
    
    //傲娇的YY，必须new才正常
    YYAnimatedImageView *imageView = [YYAnimatedImageView new];
    [imageView setFrame:CGRectMake(0, 0, bWidth, bHeight)];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDoubleTapped:)];
    [doubleTap setNumberOfTapsRequired:2];
    [imageView addGestureRecognizer:doubleTap];
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewLongPressed:)];
    [_longPress setMinimumPressDuration:0.7];
    [imageView addGestureRecognizer:_longPress];
    
    //单击双击共存时优先检测双击，若无双击则执行单击回调方法
    [_singleTap requireGestureRecognizerToFail:doubleTap];
    
    if (_imageTag == originX/bWidth-1)
    {
        NSLog(@"initial index: %ld", (long)_imageTag);
        _imageView = imageView;
    }
    
    [scrollView setDelegate:self];
    [scrollView setUserInteractionEnabled:YES];
    [scrollView setMaximumZoomScale:2.0];
    [scrollView setMinimumZoomScale:0.5];
    
    [scrollView addSubview:imageView];
    [_scrollView addSubview:scrollView];
    
    [self loadProgressView:imageView url:url originX:originX scrollView:scrollView];
}

-(void)resizeImage:(UIImage *)image imageView:(UIImageView *)imageView originX:(CGFloat)originX scrollView:(UIScrollView *)scrollView
{
    CGFloat imageHeight = image.size.height*bWidth/image.size.width;
    [imageView setImage:image];
    [scrollView setContentOffset:CGPointMake(originX, 0)];
    if (imageHeight > bHeight)
    {
        [imageView setFrame:CGRectMake(0, 0, bWidth, imageHeight)];
        [scrollView setContentSize:CGSizeMake(bWidth, imageHeight)];
    }
    else
    {
        [imageView setFrame:CGRectMake(0, 0, bWidth, bHeight)];
        [scrollView setContentSize:CGSizeMake(bWidth, bHeight)];
    }
}

-(void)loadPageControl
{
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.bounds = CGRectMake(0, 0, bWidth/2, 20);
    _pageControl.center = CGPointMake(bWidth/2, bHeight-30);
    _pageControl.numberOfPages = _count;
    _pageControl.userInteractionEnabled = NO;
    _pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    _pageControl.currentPageIndicatorTintColor = [UIColor lightTextColor];
    _pageControl.currentPage = _imageTag;
    [self addSubview:_pageControl];
}

-(void)singleTapped:(UITapGestureRecognizer *)tap
{
    [_imageView yy_cancelCurrentImageRequest];
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

-(void)imageViewDoubleTapped:(UITapGestureRecognizer *)tap
{
    CGPoint pt = [tap locationInView:tap.view];
    UIScrollView *scrollView = (UIScrollView *)tap.view.superview;
    CGRect zoomRect = CGRectMake(pt.x-tap.view.frame.size.width/4, pt.y-tap.view.frame.size.height/4, tap.view.frame.size.width/2, tap.view.frame.size.height/2);
    [scrollView zoomToRect:zoomRect animated:YES];
}

-(void)imageViewLongPressed:(UILongPressGestureRecognizer *)longPress
{
    if (!_saved)
    {
        [self saveImageToSystemAlbum:_imageView.image];
    }
    else
    {
        [Utils presentNotificationWithText:@"图片已保存"];
    }
}

-(void)saveImageToSystemAlbum:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *msg;
    if (!error)
    {
        msg = @"图片保存成功";
        _saved = YES;
    }
    else
    {
        msg = @"图片保存失败";
        _saved = NO;
    }
    [Utils presentNotificationWithText:msg];
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:_scrollView])
    {
        NSInteger imageIndex = 0;
        
        if (scrollView.contentOffset.x == 0) //第一张图(真实最后一张图)
        {
            imageIndex = _count;
            [scrollView setContentOffset:CGPointMake(bWidth*_count, 0) animated:NO];
            _pageControl.currentPage = _count-1;
        }
        else if (scrollView.contentOffset.x == bWidth*(_count+1)) //最后一张图(真实第一张图)
        {
            imageIndex = 1;
            _pageControl.currentPage = 0;
            [scrollView setContentOffset:CGPointMake(bWidth, 0) animated:NO];
        }
        else //正常顺序
        {
            imageIndex = scrollView.contentOffset.x/bWidth;
            _pageControl.currentPage = scrollView.contentOffset.x/bWidth-1;
        }
        
        UIScrollView *subScrollView = (UIScrollView *)scrollView.subviews[imageIndex];
        UIImageView *currentView = (UIImageView *)subScrollView.subviews.firstObject;
        _imageView = currentView;
    }
}

//当使用捏合手势时scrollview会向代理发送此方法告诉代理需要缩放的子控件是哪一个
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:_scrollView])
    {
        return nil;
    }
    else
    {
        return _imageView;
    }
}

@end
