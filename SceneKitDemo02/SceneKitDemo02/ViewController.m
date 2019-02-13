//
//  ViewController.m
//  SceneKitDemo02
//
//  Created by Hans3D on 2019/2/12.
//  Copyright © 2019年 wnkpzzz. All rights reserved.
//

#import "ViewController.h"
#import "Show3DViewCtl.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"模拟文件列表";
 
    [self checkBaseDirConfig];
}

- (IBAction)goToOne3DModel:(id)sender {
    Show3DViewCtl * Vc = [[Show3DViewCtl alloc] init];
    Vc.fileName = @"200180808"; // 服务器下发压缩文件名称
    [self.navigationController pushViewController:Vc animated:YES];
}

#pragma mark 【基础配置】从Resource下迁移model-o.scnasset.zip到沙盒目录，仅执行一次。

-(void)checkBaseDirConfig{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) ;
    NSString *documentsDirectory = [paths lastObject];
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString *childNewDirectory = [documentsDirectory stringByAppendingPathComponent:@"model-o.scnassets.zip"];
    
    if ([manager fileExistsAtPath:childNewDirectory]) {
        NSLog(@"model-o.scnassets文件存在");
    }else{
        NSLog(@"model-o.scnassets文件不存在");
        // Resource文件夹下的文件
        NSString * docPath = [[NSBundle mainBundle] pathForResource:@"model-o.scnassets" ofType:@".zip"];
        // 沙盒路径
        NSString *appLib = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] ;
        
        BOOL filesPresent = [self copyMissingFile:docPath toPath:appLib];
        if (filesPresent) {
            NSLog(@"迁移OK");
        } else{
            NSLog(@"迁移NO");
            [self checkBaseDirConfig];
        }
    }
}

// 把Resource文件夹下的文件拷贝到沙盒
- (BOOL)copyMissingFile:(NSString *)sourcePath toPath:(NSString *)toPath{
    
    BOOL retVal = YES; // If the file already exists, we'll return success…
    NSString * finalLocation = [toPath stringByAppendingPathComponent:[sourcePath lastPathComponent]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:finalLocation])
    {
        retVal = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:finalLocation error:NULL];
    }
    return retVal;
}


@end
