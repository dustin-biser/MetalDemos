//
//  main.m
//  Mipmap
//
//  Created by Dustin on 3/7/16.
//  Copyright © 2016 none. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//---------------------------------------------------------------------------------------
@interface Car : NSObject
    
    @property (copy) NSString * model;

    - (id)initWithModel:(NSString *)aModel;

    - (void)drive;

@end

//---------------------------------------------------------------------------------------
@implementation Car
    
    //-----------------------------------------------------------------------------------
    - (id)initWithModel:(NSString *)aModel {
        self = [super init];
        if (self) {
            // Any custom setup work goes here
            _model = [aModel copy];
        }
        return self;
    }


    //-----------------------------------------------------------------------------------
    - (void)drive {
        NSLog(@"Driving a %@\n", self.model);
    }


    //-----------------------------------------------------------------------------------
    - (void)dealloc {
        NSLog(@"Deleting Car object\n");
    }

@end
//---------------------------------------------------------------------------------------


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * model = @"Vyper";
        Car * car = [[Car alloc] initWithModel:model];
        [car drive];
    }
    
    return NSApplicationMain(argc, argv);
}
