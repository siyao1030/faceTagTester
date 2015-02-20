//
//  FTAdditions.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/17/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTAdditions.h"

@implementation FTAdditions


static const char * __ptQueueIdentifier = "ftQueueIdentifier";

dispatch_queue_t CoreDataWriteQueue(void) {
    static dispatch_queue_t sDispatchQueue = NULL;
    if (!sDispatchQueue) {
        sDispatchQueue = dispatch_queue_create("siyaoxie.faceTagTester.coredata-write", NULL);
        dispatch_queue_set_specific(sDispatchQueue, __ptQueueIdentifier, (void *)CFSTR("ftCoreDataWriteQueue"), NULL);
    }
    return sDispatchQueue;
}


dispatch_queue_t BackgroundQueue(void) {
    static dispatch_queue_t sDispatchQueue = NULL;
    if (!sDispatchQueue) {
        sDispatchQueue = dispatch_queue_create("siyaoxie.faceTagTester.background", NULL);
        dispatch_queue_set_specific(sDispatchQueue, __ptQueueIdentifier, (void *)CFSTR("ftCoreDataWriteQueue"), NULL);
    }
    return sDispatchQueue;
}

@end
