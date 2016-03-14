//
//  ObjLoader.m
//  MetalDemos
//
//  Created by Dustin on 3/11/16.
//  Copyright © 2016 none. All rights reserved.
//

#import "ObjLoader.h"

#import <tinyobjloader/tiny_obj_loader.h>
#import <iostream>


@implementation MeshData : NSObject

@end


@implementation ObjLoader {
@private
    std::vector<tinyobj::shape_t> _shapes;
    std::vector<tinyobj::material_t> _materials;
    
}

    //-----------------------------------------------------------------------------------
    - (instancetype) initWithFileName:(NSString *)fileName {
        _numMeshes = 0;
        
        NSString * assetFilePath = [[NSBundle mainBundle] pathForResource:fileName
                                                                     ofType: nil];
        if (assetFilePath == nil) {
            NSLog(@"Unable to locate asset %@", fileName);
        }
        
        std::string error;
        const char * cFileName = [assetFilePath cStringUsingEncoding:NSASCIIStringEncoding];
        const char * mtlPath = NULL;
        
        bool result = tinyobj::LoadObj(
            _shapes,
            _materials,
            error,
            cFileName,
            mtlPath
        );
        
        if(!result) {
            std::cerr << "Error calling tinyobj::LoadObj" << std::endl;
            std::cerr << error << std::endl;
        }
        
        _numMeshes = _shapes.size();
        
        return self;
    }


    //-----------------------------------------------------------------------------------
    - (NSMutableArray<MeshData *> *)getMeshData {
        if (_numMeshes == 0) {
            return nil;
        }
        
        NSMutableArray<MeshData *> * result = [[NSMutableArray alloc] initWithObjects:nil count:_numMeshes];
        NSUInteger index = 0;
        for(const tinyobj::shape_t &shape : _shapes) {
            MeshData * meshData = [[MeshData alloc] init];
            meshData.name = [NSString stringWithCString:shape.name.c_str() encoding:[NSString defaultCStringEncoding]];
            meshData.positions = shape.mesh.positions.data();
            
            [result replaceObjectAtIndex:index withObject:meshData];
            
            
            ++index;
        }
        
        return result;
    }

@end
