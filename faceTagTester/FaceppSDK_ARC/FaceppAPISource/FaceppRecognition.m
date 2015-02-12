//
//  FaceppRecognition.m
//  ImageCapture
//
//  Created by youmu on 12-11-27.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import "FaceppRecognition.h"
#import "FaceppClient.h"
#import "FaceppAPI.h"
#import "FaceppDetection.h"
#import "FaceppDetection+LocalResultUploader.h"


@implementation FaceppRecognition

-(FaceppResult*) compareWithFaceId1:(NSString*)id1 andId2:(NSString*)id2 async:(BOOL)async{
    NSMutableArray *params = [NSMutableArray arrayWithObjects:@"face_id1", id1, @"face_id2", id2, nil];
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }
    return [FaceppClient requestWithMethod:@"recognition/compare" params:params];
}

-(FaceppResult*) identifyWithGroupId:(NSString*)groupId orGroupName:(NSString*)name andURL:(NSString*)url orImageData:(NSData*)data orKeyFaceId:(NSArray*)keyFaceId async:(BOOL)async {
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:16];
    if (groupId != nil) {
        [params addObject:@"group_id"];
        [params addObject:groupId];
    }
    if (name != nil) {
        [params addObject:@"group_name"];
        [params addObject:name];
    }
    if (url != nil) {
        [params addObject:@"url"];
        [params addObject:url];
    }
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }
    if ((keyFaceId != nil) && ([keyFaceId count]>0)) {
        [params addObject:@"key_face_id"];
        NSMutableString *faces = [NSMutableString stringWithString:[keyFaceId objectAtIndex:0]];
        for (int i=1; i<[keyFaceId count]; i++)
            [faces appendFormat:@",%@", [keyFaceId objectAtIndex:i]];
        [params addObject:faces];
    }
    
    // request
    if (data != NULL)
        return [FaceppClient requestWithMethod:@"recognition/identify" image:data params:params];
    else
        return [FaceppClient requestWithMethod:@"recognition/identify" params:params];
}

-(FaceppResult*) searchWithKeyFaceId:(NSString*) keyFaceId andFacesetId:(NSString*)facesetId orFacesetName:(NSString*)facesetName {
    return [self searchWithKeyFaceId:keyFaceId andFacesetId:facesetId orFacesetName:facesetName andCount:nil async:NO];
}

-(FaceppResult*) searchWithKeyFaceId:(NSString*) keyFaceId andFacesetId:(NSString*)facesetId orFacesetName:(NSString*)facesetName andCount:(NSNumber*)count async:(BOOL)async{
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:16];
    if (keyFaceId != nil) {
        [params addObject:@"key_face_id"];
        [params addObject:keyFaceId];
    }
    if (facesetId != nil) {
        [params addObject:@"faceset_id"];
        [params addObject:facesetId];
    }
    if (facesetName != nil) {
        [params addObject:@"faceset_name"];
        [params addObject:facesetName];
    }
    if (count != nil) {
        [params addObject:@"count"];
        [params addObject:count];
    }
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }

    return [FaceppClient requestWithMethod:@"recognition/search" params:params];
}

-(FaceppResult*) verifyWithFaceId:(NSString*) faceId andPersonId:(NSString*)personId orPersonName:(NSString*)personName async:(BOOL)async{
    NSMutableArray *params = [NSMutableArray arrayWithObjects:@"face_id", faceId, nil];
    if (personId != nil) {
        [params addObject:@"person_id"];
        [params addObject:personId];
    }
    if (personName != nil) {
        [params addObject:@"person_name"];
        [params addObject:personName];
    }
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }

    return [FaceppClient requestWithMethod:@"recognition/verify" params:params];
}

-(FaceppResult*) identifyWithLocalResult: (FaceppLocalResult*)result attribute:(FaceppDetectionAttribute)attribute tag:(NSString*)tag withinGroup:(NSString *)groupID {
    // resize to 600x600
    int sizeLimit = 600;
    float scale = MAX([result.image size].width / sizeLimit, [result.image size].height / sizeLimit);
    if (scale > 1) {
        result.image = [FaceppDetection imageWithImage:result.image scaledToSize:
                        CGSizeMake([result.image size].width/scale, [result.image size].height/scale)];
    } else
        scale = 1;
    NSMutableString *offline_result = [NSMutableString stringWithString:@"["];
    for (size_t i=0; i<result.faces.count; i++) {
        if (i>0)
            [offline_result appendString: @","];
        FaceppLocalFace *face = [result.faces objectAtIndex:i];
        [offline_result appendFormat:@"[%d,%d,%d,%d]",
         (int)(face.bounds.origin.x / scale),
         (int)(face.bounds.origin.y / scale),
         (int)((face.bounds.origin.x+face.bounds.size.width) / scale),
         (int)((face.bounds.origin.y+face.bounds.size.height) / scale)];
    }
    [offline_result appendString:@"]"];
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:4];
    [params addObject:@"mode"];
    [params addObject:@"offline"];
    [params addObject:@"offline_result"];
    [params addObject:offline_result];
    
    NSData *data = UIImageJPEGRepresentation(result.image, 0);
    
    return [self identifyWithGroupId:groupID orGroupName:nil andURL:nil orImageData:data orKeyFaceId:nil async:NO];
    
}
@end
