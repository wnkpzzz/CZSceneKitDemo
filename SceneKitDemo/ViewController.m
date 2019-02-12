//
//  ViewController.m
//  SceneKitDemo
//
//  Created by Hans3D on 2019/2/12.
//  Copyright © 2019年 wnkpzzz. All rights reserved.
//

#import "ViewController.h"
#import <SceneKit/SceneKit.h>

#define APP_WIDTH                    [[UIScreen mainScreen] bounds].size.width
#define APP_HEIGHT                   [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()

@property(strong,nonatomic) SCNView *scnView;
@property(strong,nonatomic) SCNScene *scene;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.添加SCNView视图
    self.scnView = [[SCNView alloc]initWithFrame:CGRectMake(0, 0, APP_WIDTH, APP_WIDTH)];
    self.scnView.allowsCameraControl = YES; // 允许操纵，这样用户就可以改变视角的位置和方向
    self.scnView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.scnView];
    
    // 2.加载obj模型
    SCNSceneSource *sceneSource = [SCNSceneSource  sceneSourceWithURL:[[NSBundle mainBundle] URLForResource:@"head3d" withExtension:@".obj"] options:nil];
    self.scene  = [sceneSource sceneWithOptions:nil error:nil];
    self.scnView.scene = self.scene;
    
    // 3.加载模型贴图
    SCNNode *node = self.scnView.scene.rootNode.childNodes.firstObject;
    node.geometry.firstMaterial.lightingModelName = SCNLightingModelPhong;
    node.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"head3d.jpg"];    [self.scene.rootNode addChildNode:node];
    [self.scnView.scene.rootNode addChildNode:node];
    
}


@end
