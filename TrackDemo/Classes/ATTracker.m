//
//  ATTracker.m
//  TrackDemo
//
//  Created by auto.jiang on 2020/12/6.
//

#import "ATTracker.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface ATTracker()
///注册表
@property(nonatomic, strong) NSMutableDictionary *map;

@end

@implementation ATTracker

+(instancetype)shared{
    static ATTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ATTracker alloc] init];
    });
    return instance;
}

#pragma mark - lazy load

-(NSMutableDictionary *)map{
    if (!_map) {
        _map = [NSMutableDictionary new];
    }
    return _map;
}

#pragma mark - track event
///埋点方法 根据各自项目的特点 自行编写
+ (void)trackWithEvent:(NSString *)event type:(NSNumber *)type refer:(NSString *)refer{
    if (refer == nil) {
        refer = @"";
    }
    NSDictionary *dict =@{
        @"event" : event,
        @"type": type,
        @"refer": refer
    };
    NSLog(@"%@", dict);
}

#pragma mark - swizzle function
void swizzleDifferentClassInstanceMethod(Class originalCls,Class swizzledCls,SEL originalSelector, SEL swizzledSelector) {
    if (!originalCls || !swizzledCls) {
        NSLog(@"交换方法失败--交换的类名不为空");
        return;
    }
    
    if (!originalSelector || !swizzledSelector) {
        NSLog(@"交换方法失败--交换的方法名不为空");
        return;
    }
    
    Method originalMethod = class_getInstanceMethod(originalCls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledCls, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(originalCls,
                                        swizzledSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        method_exchangeImplementations(originalMethod, class_getInstanceMethod(originalCls, swizzledSelector));
    } else {
        NSLog(@"交换方法失败--埋点丢失！");
    }
 }

NSString* dynamicMethodComon(id self, SEL _cmd, NSArray *argv){
//    NSLog(@" dynamicMethodComon ==> %@", argv);
    NSString *method = [NSString stringWithFormat:@"hook_%@_%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    NSDictionary *userInfo = [ATTracker.shared.map valueForKey:method];
    id p = self;
    while (p != [NSObject class] && userInfo == nil) {
        //查找正确的类
        p = [p superclass];
        method = [NSString stringWithFormat:@"hook_%@_%@", NSStringFromClass([p class]),NSStringFromSelector(_cmd)];
        userInfo = [ATTracker.shared.map valueForKey:method];
    }
///<<<<<<<<<<<<<<<<<<<<  以下格式解析，根据各自项目特点自行实现 ( 对应json格式的匹配）userInfo 代表每一个配置的埋点数据
    NSArray *events = userInfo[@"events"];
    NSArray *types = userInfo[@"types"];
    NSArray *refers = userInfo[@"refers"];
    for (int i = 0; i < events.count; i++) {
        NSString *event = events[i];
        NSNumber *type = types[i];
        NSDictionary *refer = refers[i];
        __block NSString *referValue = @"";
        if (refer) {
            [refer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
                if (referValue.length > 0) {
                    referValue = [referValue stringByAppendingString:@"&"];
                }
                if ([value containsString:@"self."]) {
                    NSString *keyPath = [value componentsSeparatedByString:@"self."].lastObject;
                    value = [self valueForKeyPath:keyPath];
                }else if ([value containsString:@"#"]){
                    NSString *lastObject = [value componentsSeparatedByString:@"#"].lastObject;
                    int index = [lastObject intValue];
                    if (index < argv.count) {
                        value = argv[index];
                    }
                }
                referValue = [referValue stringByAppendingFormat:@"%@=%@", key,value];
            }];
        }
///<<<<<<<<<<<<<<<<<<<< 以上格式解析，根据各自项目特点自行实现
        [ATTracker trackWithEvent:event type:type refer:referValue];
    }
    return method;
}

+(int)countChar:(NSString *)s cchar:(char) c
{
    int count = 0;
    unsigned long l = [s length];
    for (int i = 0; i < l; i++) {
        char cc = [s characterAtIndex: i];
        if (cc == c) {
            count++;
        }
    }
    return count;
}

/// 模版1 - 0个参数
void dynamicMethod0(id self, SEL _cmd) {
    NSString *method = dynamicMethodComon(self,_cmd, @[]);
    [self performSelectorWithArgs: NSSelectorFromString(method)];
}
/// 模版2 - 1个参数
void dynamicMethod1(id self, SEL _cmd, id argv0) {
    NSString *method = dynamicMethodComon(self,_cmd, @[argv0]);
    [self performSelectorWithArgs: NSSelectorFromString(method), argv0];
}

/// 模版3 - 2个参数
void dynamicMethod2(id self, SEL _cmd, id argv0, id argv1) {
    NSString *method = dynamicMethodComon(self,_cmd, @[argv0, argv1]);
    [self performSelectorWithArgs: NSSelectorFromString(method), argv0, argv1];
}

/// 模版4 - 3个参数
void dynamicMethod3(id self, SEL _cmd, id argv0, id argv1, id argv2) {
    NSString *method = dynamicMethodComon(self,_cmd, @[argv0, argv1, argv2]);
    [self performSelectorWithArgs: NSSelectorFromString(method), argv0, argv1, argv2];
}

///读取 json 文件
+ (id)getJsonDataJsonname:(NSString *)jsonname
{
    NSString *path = [[NSBundle mainBundle] pathForResource:jsonname ofType:@"json"];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:path];
    NSError *error;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (!jsonData || error) {
        //NSLog(@"JSON解码失败");
        return nil;
    } else {
        return jsonObj;
    }
}


#pragma mark - initialize

+ (void)initialize
{
    if (self == [ATTracker class]) {
        
        ///  方式 二
        NSArray *array = [self getJsonDataJsonname:@"tracker"];
//        NSLog(@"%@", array);
        
        [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *hookClass = obj[@"hookClass"];
            NSString *hookMethod = obj[@"hookMethod"];
            NSString *method = [NSString stringWithFormat:@"hook_%@_%@", hookClass, hookMethod];

            [ATTracker.shared.map setObject:obj forKey:method];
            SEL sel = NSSelectorFromString(method);
            int count = [self countChar: hookMethod cchar: ':'];
            if (count == 0) {
                class_addMethod(self, sel, (IMP)dynamicMethod0, "v@:");
            }else if(count == 1){
                class_addMethod(self, sel, (IMP)dynamicMethod1, "v@:@");
            }else if(count == 2){
                class_addMethod(self, sel, (IMP)dynamicMethod2, "v@:@@");
            }else {
                class_addMethod(self, sel, (IMP)dynamicMethod3, "v@:@@@");
            }
            swizzleDifferentClassInstanceMethod(
                NSClassFromString(hookClass),
                self,
                NSSelectorFromString(hookMethod),
                sel
            );
        }];
        
        ///  方式 一
        swizzleDifferentClassInstanceMethod(
            NSClassFromString(@"ViewController"),
            self,
            NSSelectorFromString(@"viewWillAppear:"),
            @selector(hook_ViewController_viewWillAppear:)
        );
        swizzleDifferentClassInstanceMethod(
            NSClassFromString(@"ViewController"),
            self,
            NSSelectorFromString(@"buttonAciton2:"),
            @selector(hook_ViewController_buttonAciton2:)
        );
    }
}
#pragma mark - swizzle method
///  方式 一
/// ViewController.viewWillAppear
- (void)hook_ViewController_viewWillAppear:(BOOL)animated{
    [self hook_ViewController_viewWillAppear:animated];
    NSString *articleId = [self valueForKeyPath:@"articleId"];
    NSString *refer = [NSString stringWithFormat:@"uid=123&articleId=%@", articleId];
    [ATTracker trackWithEvent:@"view_willAppear_show" type:@1 refer:refer];
}

/// ViewController.buttonAciton2:
- (void)hook_ViewController_buttonAciton2:(UIButton *)button{
    [self hook_ViewController_buttonAciton2:button];
    [ATTracker trackWithEvent:@"view_button2_click" type:@2 refer:@"uid=123"];
}

@end

