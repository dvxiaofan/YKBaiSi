//
//  XFCommentViewController.m
//  XFBaisi
//
//  Created by xiaofans on 16/7/5.
//  Copyright © 2016年 xiaofan. All rights reserved.
//

#import "XFCommentViewController.h"
#import "XFTopic.h"
#import "XFComment.h"
#import "XFComSectionHeaderView.h"
#import "XFCommentCell.h"
#import "XFTopicCell.h"

@interface XFCommentViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMargin;
@property (weak, nonatomic) IBOutlet UITextField        *writeCommentTextField;
@property (weak, nonatomic) IBOutlet UITableView        *tableView;

/** 任务管理者 */
@property (nonatomic, strong) XFHTTPSessionManager *manager;
/** 最热评论数据 */
@property (nonatomic, strong) NSArray<XFComment *> *hotComments;
/** 全部最新评论数据 */
@property (nonatomic, strong) NSMutableArray<XFComment *> *lastComments;

/** 最热评论 */
@property (nonatomic, strong) XFComment *savedTopCmt;

@end

static NSString *const XFCommentCellID = @"XFCommentCellID";
static NSString *const XFComSectionHeaderViewID = @"XFComSectionHeaderViewID";

@implementation XFCommentViewController

#pragma mark - 懒加载

- (XFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [XFHTTPSessionManager manager];
    }
    return _manager;
}

#pragma mark - 初始化

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBase];
    
    [self setupTableView];
    
    [self setupRefresh];
    
    [self setupHeaderView];
}

- (void)setupTableView {
    self.tableView.backgroundColor = XFBaseBgColor;
    // 去掉系统分割线
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XFCommentCell class]) bundle:nil] forCellReuseIdentifier:XFCommentCellID];
    [self.tableView registerClass:[XFComSectionHeaderView class] forHeaderFooterViewReuseIdentifier:XFComSectionHeaderViewID];
    
    // headerview 高度
    self.tableView.sectionHeaderHeight = XFComSectionHeaderTestFont.lineHeight + 2;
    
    // 设置 cell 高度
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
}

- (void)setupBase {
    self.navigationItem.title = @"评论";
    // 键盘变化的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)setupHeaderView {
    // 先处理模型数据
    self.savedTopCmt = self.topic.top_comment;
    self.topic.top_comment = nil;
    self.topic.cellHeight = 0;
    
    // 创建一个 UIView 用来从放 cell
    UIView *headerView = [[UIView alloc] init];
    
    XFTopicCell *cell = [XFTopicCell xf_viewFromXib];
    cell.topic = self.topic;
    cell.frame = CGRectMake(0, 0, SCREEN.width, self.topic.cellHeight);
    [headerView addSubview:cell];
    
    headerView.xf_height = cell.xf_height + XFMargin * 2;
    
    self.tableView.tableHeaderView = headerView;
}

- (void)setupRefresh {
    self.tableView.mj_header = [XFRefreshHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewComment)];
    [self.tableView.mj_header beginRefreshing];
    
    self.tableView.mj_footer = [XFRefreshFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreComment)];
}

//  移除键盘通知
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 加载数据

- (void)loadNewComment {
    // 取消所有请求
    [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"a"] = @"dataList";
    params[@"c"] = @"comment";
    params[@"data_id"] = self.topic.ID;
    params[@"hot"] = @"1";
    
    __weak typeof(self) weakSelf = self;
    
    // 请求
    [self.manager GET:BASE_URL parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable responseObject) {
        
        // 没有评论数据，结束刷新并直接返回
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [weakSelf.tableView.mj_header endRefreshing];
            return;
        }
        // 字典转模型
        weakSelf.lastComments = [XFComment mj_objectArrayWithKeyValuesArray:responseObject[@"data"]];
        weakSelf.hotComments = [XFComment mj_objectArrayWithKeyValuesArray:responseObject[@"hot"]];
        // 刷新表格
        [weakSelf.tableView reloadData];
        
        int total = [responseObject[@"total"] intValue];
        if (weakSelf.lastComments.count == total) {         // 没有更多数据
            [weakSelf.tableView.mj_header endRefreshing];
            weakSelf.tableView.mj_footer.hidden = YES;
        } else {                                            // 有数据，结束刷新
            [weakSelf.tableView.mj_header endRefreshing];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        XFLog(@"请求失败 - %@", error);
        // 控件结束刷新
        [weakSelf.tableView.mj_header endRefreshing];
    }];
}
 
- (void)loadMoreComment {
    // 取消所有请求
    [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"a"] = @"dataList";
    params[@"c"] = @"comment";
    params[@"data_id"] = self.topic.ID;
    params[@"lastcid"] = self.lastComments.lastObject.ID;
    
    __weak typeof(self) weakSelf = self;
    
    // 请求
    [self.manager GET:BASE_URL parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable responseObject) {
        
        // 没有评论数据，结束刷新并直接返回
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [weakSelf.tableView.mj_footer endRefreshing];
            return;
        }
        // 字典转模型
        NSArray *moreComments = [XFComment mj_objectArrayWithKeyValuesArray:responseObject[@"data"]];
        [weakSelf.lastComments addObjectsFromArray:moreComments];
        
        // 刷新表格
        [weakSelf.tableView reloadData];
        
        int total = [responseObject[@"total"] intValue];
        if (weakSelf.lastComments.count == total) {         // 没有更多数据
            [weakSelf.tableView.mj_footer endRefreshing];
            weakSelf.tableView.mj_footer.hidden = YES;
        } else {                                            // 有数据，结束刷新
            [weakSelf.tableView.mj_footer endRefreshing];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        XFLog(@"请求失败 - %@", error);
        // 控件结束刷新
        [weakSelf.tableView.mj_footer endRefreshing];
    }];
}

#pragma mark - 监听事件

- (void)keyboardChangeFrame:(NSNotification *)notification {
    
    // 修改约束
    CGFloat keyboardY = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    CGFloat screenH = SCREEN.height;
    self.bottomMargin.constant = screenH - keyboardY;
    
    // 动画显示
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)voiceBtnClick:(UIButton *)sender {
    XFLog(@"发语音");
}

- (IBAction)rightBtnClick:(UIButton *)sender {
    XFLog(@"确定发送");
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 有最热和最新评论
    if (self.hotComments.count) return 2;
    
    // 没有最热
    if (self.lastComments.count) return 1;
    
    // 没有最热也没有最新
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 判断是否有最热评论
    if (section == 0 && self.hotComments.count) {
        return self.hotComments.count;
    }
    
    return self.lastComments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XFCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:XFCommentCellID];
    
    if (indexPath.section == 0 && self.hotComments.count) {
        cell.commetn = self.hotComments[indexPath.row];
    } else {
        cell.commetn = self.lastComments[indexPath.row];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    XFComSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XFComSectionHeaderViewID];
    
    // 第0组 && 有最热评论数据
    if (section == 0 && self.hotComments.count) {
        headerView.textLabel.text = @"最热评论";
    } else { // 其他情况
        headerView.textLabel.text = @"最新评论";
    }
    
    return headerView;
}

/**
 *  开始拖拽时关闭键盘
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}


@end








