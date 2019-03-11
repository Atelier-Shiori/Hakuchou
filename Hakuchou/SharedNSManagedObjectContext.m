//
//  SharedNSManagedObjectContext.m
//  Hakuchou
//
//  Created by 香風智乃 on 3/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "SharedNSManagedObjectContext.h"

@implementation SharedNSManagedObjectContext
+ (instancetype)initalizeSharedInstanceWithContext:(NSManagedObjectContext *)moc {
    SharedNSManagedObjectContext *sharedContext = [self sharedInstance];
    sharedContext.moc = moc;
    return sharedContext;
}
+ (instancetype)sharedInstance {
    static SharedNSManagedObjectContext *sharedManagedObjectContext = nil;
    static dispatch_once_t sharedManagedObjectContexttoken;
    dispatch_once(&sharedManagedObjectContexttoken, ^{
        sharedManagedObjectContext = [[SharedNSManagedObjectContext alloc] init];
    });
    return sharedManagedObjectContext;
}
@end
