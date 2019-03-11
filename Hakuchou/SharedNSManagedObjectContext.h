//
//  SharedNSManagedObjectContext.h
//  Hakuchou
//
//  Created by 香風智乃 on 3/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elseif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SharedNSManagedObjectContext : NSObject
@property (strong) NSManagedObjectContext *moc;
@end

NS_ASSUME_NONNULL_END
