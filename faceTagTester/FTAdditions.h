//
//  FTAdditions.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/17/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+FTAdditions.h"

@interface FTAdditions : NSObject

dispatch_queue_t CoreDataWriteQueue(void);
dispatch_queue_t BackgroundQueue(void);

@end
