//
//  XFTopicCell.m
//  XFBaisi
//
//  Created by xiaofans on 16/6/29.
//  Copyright © 2016年 xiaofan. All rights reserved.
//

#import "XFTopicCell.h"
#import "XFTopic.h"
#import "XFComment.h"
#import "XFUser.h"
#import "XFTopicPictureView.h"
#import "XFTopicVideoView.h"
#import "XFTopicAudioView.h"


@interface XFTopicCell ()
/** 头像 */
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
/** 名字 */
@property (nonatomic, weak) IBOutlet UILabel     *nameLabel;
/** 审核通过时间 */
@property (nonatomic, weak) IBOutlet UILabel     *createdAtLabel;
/** 内容文字 */
@property (nonatomic, weak) IBOutlet UILabel     *text_label;
/** 顶 按钮 */
@property (nonatomic, weak) IBOutlet UIButton    *dingButton;
/** 踩 按钮 */
@property (nonatomic, weak) IBOutlet UIButton    *caiButton;
/** 转发/分享 按钮 */
@property (nonatomic, weak) IBOutlet UIButton    *repostButton;
/** 评论按钮 */
@property (nonatomic, weak) IBOutlet UIButton    *commentButton;
/** 最热评论整体 view */
@property (nonatomic, weak) IBOutlet UIView      *topCmtView;
/** 最热评论内容 */
@property (nonatomic, weak) IBOutlet UILabel     *topCmtContentLabel;

/** 中间控件 */
/** 图片 view */
@property (nonatomic, weak) XFTopicPictureView   *pictureView;
/** 视频 view */
@property (nonatomic, weak) XFTopicVideoView     *videoView;
/** 音频 view */
@property (nonatomic, weak) XFTopicAudioView     *audioView;

@end

@implementation XFTopicCell

#pragma mark - 懒加载

- (XFTopicPictureView *)pictureView {
    if (!_pictureView) {
        XFTopicPictureView *pictureView = [XFTopicPictureView xf_viewFromXib];
        [self.contentView addSubview:pictureView];
        _pictureView = pictureView;
    }
    return _pictureView;
}

- (XFTopicVideoView *)videoView {
    if (!_videoView) {
        XFTopicVideoView *videoView = [XFTopicVideoView xf_viewFromXib];
        [self.contentView addSubview:videoView];
        _videoView = videoView;
    }
    return _videoView;
}

- (XFTopicAudioView *)audioView {
    if (!_audioView) {
        XFTopicAudioView *audioView = [XFTopicAudioView xf_viewFromXib];
        [self.contentView addSubview:audioView];
        _audioView = audioView;
    }
    return _audioView;
}


#pragma mark - 初始化

- (void)awakeFromNib {
    self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mainCellBackground"]];
}

- (void)setTopic:(XFTopic *)topic {
    _topic = topic;
    
    [self.profileImageView xf_setHeader:topic.user.header.firstObject];
    
    self.nameLabel.text      = topic.user.name;
    
    self.createdAtLabel.text = topic.passtime;
    self.text_label.text     = topic.text;
    
    [self setupButton:self.dingButton    number:topic.up      placeholder:@"顶"];
    [self setupButton:self.caiButton     number:topic.down    placeholder:@"踩"];
    [self setupButton:self.repostButton  number:topic.forward placeholder:@"分享"];
    [self setupButton:self.commentButton number:topic.comment placeholder:@"评论"];
    
#pragma mark - 是否显示最热评论
    if (topic.top_comment) {    // 有
        self.topCmtView.hidden  = NO;
        
        NSString *username      = topic.top_comment.user.name;
        NSString *content       = topic.top_comment.content;
        
        self.topCmtContentLabel.text = [NSString stringWithFormat:@"%@: %@", username, content];
        
    } else {                // 没有
        self.topCmtView.hidden  = YES;
    }
    
#pragma mark - 处理 cell 中间的内容
    
    if ([topic.type isEqualToString:XFTopicImage] ) {           // 图片
        self.pictureView.hidden = NO;
        self.videoView.hidden   = YES;
        self.audioView.hidden   = YES;
        self.pictureView.frame  = topic.contentFrame;
        self.pictureView.topic  = topic;
    } else if ([topic.type isEqualToString:XFTopicWord]) {      // 段子
        self.pictureView.hidden = YES;
        self.videoView.hidden   = YES;
        self.audioView.hidden   = YES;
    } else if ([topic.type isEqualToString:XFTopicVideo]) {     // 视频
        self.pictureView.hidden = YES;
        self.videoView.hidden   = NO;
        self.audioView.hidden   = YES;
        self.videoView.frame    = topic.contentFrame;
        self.videoView.topic    = topic;
    } else if ([topic.type isEqualToString:XFTopicGif]) {       // gif
        self.pictureView.hidden = NO;
        self.videoView.hidden   = YES;
        self.audioView.hidden   = YES;
        self.pictureView.frame  = topic.contentFrame;
        self.pictureView.topic  = topic;
    } else if ([topic.type isEqualToString:XFTopicAudio]) {     // 音频
        self.pictureView.hidden = YES;
        self.videoView.hidden   = YES;
        self.audioView.hidden   = NO;
        self.audioView.topic    = topic;
        self.audioView.frame    = topic.contentFrame;
    }
}

/**
 *  设置按钮文字
 */
- (void)setupButton:(UIButton *)button number:(NSInteger)number placeholder:(NSString *)placeholder {
    if (number >= 10000) {
        [button setTitle:[NSString stringWithFormat:@"%.1f万", number / 10000.0] forState:UIControlStateNormal];
    } else if (number > 0) {
        [button setTitle:[NSString stringWithFormat:@"%zd", number] forState:UIControlStateNormal];
    } else {
        [button setTitle:placeholder forState:UIControlStateNormal];
    }
}

/**
 *  重写 setFrame 方法,拦截系统设置的 frame
 */
- (void)setFrame:(CGRect)frame {
    
    frame.size.height -= XFMargin;
    frame.origin.y += XFMargin;
    
    [super setFrame:frame];
}

#pragma mark - 按钮点击事件

- (IBAction)more {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[UIAlertAction actionWithTitle:@"收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        XFLog(@"点击了 --> 收藏");
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        XFLog(@"点击了 --> 举报");
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"取消" style: UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        XFLog(@"点击了 --> 取消");
    }]];
    
    [self.window.rootViewController presentViewController:controller animated:YES completion:nil];
}

- (IBAction)dingBtnClick:(UIButton *)sender {
    
    XFLog(@"顶");
}

- (IBAction)caiBtnClick:(UIButton *)sender {
    
    XFLog(@"踩");
}

- (IBAction)forwardBtnClick:(UIButton *)sender {
    
    XFLog(@"分享");
}

- (IBAction)commentBtnClick:(UIButton *)sender {
    
    XFLog(@"评论");
}

@end






