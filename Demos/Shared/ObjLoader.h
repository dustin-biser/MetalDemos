//
//  ObjLoader.h
//  MetalDemos
//
//  Created by Dustin on 3/11/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MeshData : NSObject
    @property (nonatomic, copy) NSString * name;
    @property (nonatomic) const float * positions;
    @property (nonatomic) const float * normals;
    @property (nonatomic) const float * texcoords;
    @property (nonatomic) const unsigned int * indices;
@end


@interface ObjLoader : NSObject
    @property (nonatomic, readonly) unsigned long numMeshes;

    - (instancetype)initWithFileName:(NSString *)fileName;

    - (NSMutableArray<MeshData *> *)getMeshData;

@end
