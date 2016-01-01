//
//  ResourceIndices.swift
//  MetalSwift
//
//  Created by Dustin on 12/31/15.
//  Copyright © 2015 none. All rights reserved.
//

enum IndexForVertexAttribute : Int {
    case Positions = 0,
    Normals,
    TextureCoords
}

enum IndexForBuffer : Int {
    case VertexBuffer = 0,
    FrameUniformBuffer,
    MaterialUniformBuffer
}
