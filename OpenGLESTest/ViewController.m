//
//  ViewController.m
//  OpenGLESTest
//
//  Created by 王勇 on 2018/11/7.
//  Copyright © 2018年 王勇. All rights reserved.
//

#import "ViewController.h"
#import "DrawingViewController.h"

#define VSH @"attribute vec4 position;\
attribute vec2 textCoordinate;\
uniform mat4 rotateMatrix;\
\
varying lowp vec2 varyTextCoord;\
\
void main()\
{\
varyTextCoord = textCoordinate;\
\
vec4 vPos = position;\
\
vPos = vPos * rotateMatrix;\
\
gl_Position = vPos;\
}"

#define FSH @"varying lowp vec2 varyTextCoord;\
\
uniform sampler2D colorMap;\
\
void main()\
{\
gl_FragColor = texture2D(colorMap, varyTextCoord);\
}"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSArray * dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [UIApplication sharedApplication].keyWindow.rootViewController = [[UINavigationController alloc] initWithRootViewController:self];
    // Do any additional setup after loading the view, typically from a nib.
}
- (NSArray *)dataArray
{
    if (_dataArray == nil) {
        
        _dataArray = @[@"绘制图案:三角形,矩形,圆形",@"绘制图片"];
    }
    
    return _dataArray;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell  = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = self.dataArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    DrawingViewController * ctl = [[DrawingViewController alloc] init];
    
    ctl.title = self.dataArray[indexPath.row];
    
    ctl.showType = indexPath.row;
    
    [self.navigationController pushViewController:ctl animated:YES];

}

@end
