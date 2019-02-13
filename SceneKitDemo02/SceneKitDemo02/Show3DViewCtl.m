//
//  Show3DViewCtl.m
//  SceneKitDemo02
//
//  Created by Hans3D on 2019/2/13.
//  Copyright © 2019年 wnkpzzz. All rights reserved.
//

#import "Show3DViewCtl.h"
#import "ViewController.h"
#import "ZipArchive.h" // zip解压
#import "AFNetworking.h" // AFN网络
#import <SceneKit/SceneKit.h> // 3D框架

#define WS(weakSelf)                 __weak __typeof(&*self)weakSelf = self;
#define APP_WIDTH                    [[UIScreen mainScreen] bounds].size.width
#define APP_HEIGHT                   [[UIScreen mainScreen] bounds].size.height
#define URL_3d_download              @"http://55.118.187/share/download"

@interface Show3DViewCtl ()<SSZipArchiveDelegate>

@property(strong,nonatomic)SCNView *scnView;
@property(strong,nonatomic)SCNScene *scene;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation Show3DViewCtl

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setBaseConfig];
    [self createBaseDir];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - 基础设置

// 基本设置
-(void)setBaseConfig{
    
    self.view.backgroundColor = [UIColor blackColor];
    self.contentView.backgroundColor = [UIColor blackColor];
    
    // 1.添加SCNView视图
    self.scnView = [[SCNView alloc]initWithFrame:CGRectMake(0, 0, APP_WIDTH, APP_WIDTH)];
    self.scnView.allowsCameraControl = YES; // 允许操纵，这样用户就可以改变视角的位置和方向
    self.scnView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:self.scnView];

}

// 返回事件
- (IBAction)backAction:(id)sender {
    
    // 返回到任意界面
    for (UIViewController *temp in self.navigationController.viewControllers) {
        if ([temp isKindOfClass:[ViewController class]]) {
            [self.navigationController popToViewController:temp animated:YES];
        }
    }
}

// 删除事件
- (IBAction)deleteAction:(id)sender {
    
    WS(weakSelf);
    //显示弹出框列表选择
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"删除模型"
                                                                   message:@"删除该模型，您可以从头模列表中重新下载，确定删除该头模吗？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                         NSFileManager * manager = [NSFileManager defaultManager];
                                                         
                                                         // 总体数据文件夹
                                                         NSString *dataDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@",weakSelf.fileName]];
                                                         
                                                         // 删除文件夹
                                                         [manager removeItemAtPath:dataDirectory error:nil];
                                                         
                                                         // 返回到任意界面
                                                         for (UIViewController *temp in self.navigationController.viewControllers) {
                                                             if ([temp isKindOfClass:[ViewController class]]) {
                                                                 [self.navigationController popToViewController:temp animated:YES];
                                                             }
                                                         }
                                                     }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             //响应事件
                                                         }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - SSZipArchiveDelegate

- (void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo {
    NSLog(@"将要解压。");
}

- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPat uniqueId:(NSString *)uniqueId {
    NSLog(@"解压完成！");
}

#pragma mark - 主体流程

// 1.检测文件是否存在
-(void)createBaseDir{
    
    NSFileManager * manager = [NSFileManager defaultManager];
    
    // 总体数据文件夹
    NSString *dataDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"3dDataDir"];
    
    // 删除文件夹
    [manager removeItemAtPath:dataDirectory error:nil];
    
    if ([manager fileExistsAtPath:dataDirectory]) {
        NSLog(@"3dDataDir文件存在");
    }else{
        NSLog(@"3dDataDir文件不存在--->去创建");
        [manager createDirectoryAtPath:dataDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *showDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"3dShowDir"];
    
    if ([manager fileExistsAtPath:showDirectory]) {
        NSLog(@"3dShowDir文件存在");
    }else{
        NSLog(@"3dShowDir文件不存在--->去创建");
        [manager createDirectoryAtPath:showDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    // 子节点数据文件夹
    NSString *childDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@",_fileName]];
    if ([manager fileExistsAtPath:childDirectory]) {
        NSLog(@"3dShowDir下面子文件存在--->去展示。");
        [self show3DModel];
    }else{
        NSLog(@"3dShowDir下面子文件不存在--->去下载");
        [self downloadNetDataforDir];
    }
    
}

// 2.通过网络下载文件并存入沙盒Document/3dDataDir下
-(void)downloadNetDataforDir{
    
    NSString * urlStr = @"ftp://zcz:123456@47.107.172.158/200180808.zip";  // 网址是我的服务器地址
    
    //远程地址
    NSURL *URL = [NSURL URLWithString:urlStr];
    //默认配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //AFN3.0+基于封住URLSession的句柄
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //下载Task操作
    WS(weakSelf);
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // 下载进度
        NSLog(@"%f===下载进度",downloadProgress.fractionCompleted);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        // 设置下载完成操作
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用
        NSString *imgFilePath = [filePath path];// 将NSURL转成NSString
        NSLog(@"filePath = %@",filePath);
        NSLog(@"imgFilePath = %@",imgFilePath);
        NSString *destinationPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"3dDataDir"];
        
        [weakSelf releaseZipFilesWithUnzipFileAtPath:imgFilePath Destination:destinationPath];
    }];
    [downloadTask resume];
}

// 3.在3dShowDir下，用下载压缩包的名字创建一个子文件夹，方便管理。
// 4.解压model-o.scnassets.zip到该目录下
-(void)createSameDirTo3DShowDir{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) ;
    NSString *documentsDirectory = [paths lastObject];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // 3.在3dShowDir下，用下载压缩包的名字创建一个子文件夹，方便管理。Document/3dShowDir/200180808
    NSString *childNewDirectory = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@",_fileName]];
    if (![manager fileExistsAtPath:childNewDirectory]) {
        [manager createDirectoryAtPath:childNewDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    // 4解压model-o.scnassets.zip得到model-o.scnassets文件夹到Document/3dShowDir/200180808目录下
    NSError *error;
    WS(weakSelf);
    NSString *modelDirectory = [documentsDirectory stringByAppendingPathComponent:@"model-o.scnassets.zip"];
    
    if ([SSZipArchive unzipFileAtPath:modelDirectory toDestination:childNewDirectory overwrite:YES password:nil error:&error delegate:self]) {
        NSLog(@"解压成功");
        [weakSelf decompressionAndMoveToDir];
    }else {
        NSLog(@"%@",error);
    }
}

// 5.解压云端数据
-(void)releaseZipFilesWithUnzipFileAtPath:(NSString *)zipPath Destination:(NSString *)unzipPath{
    
    NSError *error;
    WS(weakSelf);
    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath overwrite:YES password:nil error:&error delegate:self]) {
        NSLog(@"success");
        NSLog(@"unzipPath = %@",unzipPath);
        [weakSelf createSameDirTo3DShowDir];
    }else {
        NSLog(@"%@",error);
    }
}

// 5.1移动到model-o.scnassets文件夹下
-(void)decompressionAndMoveToDir{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) ;
    NSString *documentsDirectory = [paths lastObject];
    
    // 文件源
    NSString *testDataPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"3dDataDir/%@",self.fileName]];
    // 复制到
    NSString *childNewDirectory = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@/model-o.scnassets",_fileName]];
    
    // 执行复制操作
    [self copyFileFromPath:testDataPath toPath:childNewDirectory];
    // 展示3D模型
    [self show3DModel];
    
}

// 5.2复制文件夹下所有文件到另一个文件夹
-(void)copyFileFromPath:(NSString *)sourcePath toPath:(NSString *)toPath{
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];NSArray* array = [fileManager contentsOfDirectoryAtPath:sourcePath error:nil];for(int i = 0; i<[array count]; i++){NSString *fullPath = [sourcePath stringByAppendingPathComponent:[array objectAtIndex:i]];NSString *fullToPath = [toPath stringByAppendingPathComponent:[array objectAtIndex:i]];NSLog(@"%@",fullPath);NSLog(@"%@",fullToPath);
        //判断是不是文件夹
        BOOL isFolder = NO;//判断是不是存在路径 并且是不是文件夹
        BOOL isExist = [fileManager fileExistsAtPath:fullPath isDirectory:&isFolder];
        if (isExist){
            NSError *err = nil;
            [[NSFileManager defaultManager] copyItemAtPath:  fullPath toPath:fullToPath error:&err];
            NSLog(@"%@",err);
            if (isFolder){
                [self copyFileFromPath:fullPath toPath:fullToPath];
                
            }}}
    
}

// 6.展示3D模型
-(void)show3DModel{
    
    // 1.文件路径
    NSString *objDataPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@/model-o.scnassets/head3d.obj",self.fileName]];
    NSString *imgDataPath =[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"3dShowDir/%@/model-o.scnassets/head3d.jpg",self.fileName]];
    
    // 2.加载模型
    SCNSceneSource *sceneSource = [SCNSceneSource  sceneSourceWithURL:[NSURL URLWithString:objDataPath] options:nil];
    self.scene  = [sceneSource sceneWithOptions:nil error:nil];
    self.scnView.scene = self.scene;
    
    // 3.加载模型贴图
    SCNNode *node = self.scnView.scene.rootNode.childNodes.firstObject;
    node.geometry.firstMaterial.lightingModelName = SCNLightingModelPhong;
    node.geometry.firstMaterial.diffuse.contents = imgDataPath;
    [self.scene.rootNode addChildNode:node];
    [self.scnView.scene.rootNode addChildNode:node];
    
    //    SCNLight *light = [SCNLight light];// 创建光对象
    //    light.type = SCNLightTypeAmbient;// 设置类型
    //    light.color = [UIColor whiteColor]; // 设置光的颜色
    //    SCNNode *lightNode = [SCNNode node];
    //    lightNode.light  = light;
    //    [self.scnView.scene.rootNode addChildNode:lightNode]; // 添加到场景中去

}

@end

