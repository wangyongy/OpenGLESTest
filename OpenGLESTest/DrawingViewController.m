//
//  DrawingViewController.m
//  OpenGLESTest
//
//  Created by 王勇 on 2018/11/7.
//  Copyright © 2018年 王勇. All rights reserved.
//

#import "DrawingViewController.h"
#import "LearnView.h"
#import "GLShowImageView.h"

@interface DrawingViewController ()


@end

@implementation DrawingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    switch (self.showType) {
        case 0:
            self.view = [[LearnView alloc] initWithFrame:self.view.bounds];
            break;
        case 1:
            self.view = [[GLShowImageView alloc] initWithFrame:self.view.bounds];
            break;
        default:
            break;
    }
   
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"change" style:UIBarButtonItemStyleDone target:self action:@selector(changeButtonAction:)]];

    // Do any additional setup after loading the view.
}
#pragma mark - action
- (IBAction)changeButtonAction:(UIButton *)sender
{
    if (self.showType == 0) [(LearnView *)self.view change];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
