//
//  XFLoginRegisterTextField.m
//  XFBaisi
//
//  Created by xiaofans on 16/6/26.
//  Copyright © 2016年 xiaofan. All rights reserved.
//

#import "XFLoginRegisterTextField.h"


@interface XFLoginRegisterTextField ()

@end

@implementation XFLoginRegisterTextField


- (void)awakeFromNib {
    // 设置光标颜色
    self.tintColor = [UIColor whiteColor];
    
    // 设置默认的占位文字颜色
    self.xf_placeholderColor = [UIColor grayColor];
}

/**
 *  成为第一响应者
 */
- (BOOL)becomeFirstResponder
{
    self.xf_placeholderColor = [UIColor whiteColor];
    return [super becomeFirstResponder];
}

/**
 *  放弃第一响应者
 */
- (BOOL)resignFirstResponder
{
    self.xf_placeholderColor = [UIColor grayColor];
    return [super resignFirstResponder];
}


@end
