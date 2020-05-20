//
//  ViewController.m
//  TrackDemo
//
//  Created by auto.jiang on 2020/12/6.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, copy) NSString *articleId;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.articleId = @"123456789";
    
    UIButton *button1 = [UIButton new];
    button1.backgroundColor = [UIColor greenColor];
    [button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button1 setTitle:@"按钮1" forState:UIControlStateNormal];
    button1.frame = CGRectMake(50, 100, 80, 50);
    [button1 addTarget:self action:@selector(buttonAciton1:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton new];
    button2.backgroundColor = [UIColor greenColor];
    [button2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button2 setTitle:@"按钮2" forState:UIControlStateNormal];
    button2.frame = CGRectMake(150, 100, 80, 50);
    [button2 addTarget:self action:@selector(buttonAciton2:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

#pragma mark - aciton

- (void)buttonAciton1:(UIButton *)button{
    
}

- (void)buttonAciton2:(UIButton *)button{
    
}

@end
