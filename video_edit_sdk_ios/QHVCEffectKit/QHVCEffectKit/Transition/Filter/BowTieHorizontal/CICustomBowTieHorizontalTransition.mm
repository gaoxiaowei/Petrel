//
//  CICustomBowTieHorizontalTransition.m
//  CustomCIFilter
//
//  Created by 李越 on 2018/12/3.
//  Copyright © 2018 liyue-g. All rights reserved.
//

#import "CICustomBowTieHorizontalTransition.h"
#import "QHVCEffectUtils.h"

NSString* const customBowTieHorizontalTransitionKernelString = KERNEL_STRING
(
 float check(vec2 p1, vec2 p2, vec2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}
 
 bool PointInTriangle (vec2 pt, vec2 p1, vec2 p2, vec2 p3)
{
    bool b1;
    bool b2;
    bool b3;
    b1 = check(pt, p1, p2) < 0.0;
    b2 = check(pt, p2, p3) < 0.0;
    b3 = check(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}
 
 bool in_left_triangle(vec2 p, float progress)
{
    vec2 vertex1;
    vec2 vertex2;
    vec2 vertex3;
    vertex1 = vec2(progress, 0.5);
    vertex2 = vec2(0.0, 0.5 - progress);
    vertex3 = vec2(0.0, 0.5 + progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}
 
 bool in_right_triangle(vec2 p, float progress)
{
    vec2 vertex1;
    vec2 vertex2;
    vec2 vertex3;
    vertex1 = vec2(1.0 - progress, 0.5);
    vertex2 = vec2(1.0, 0.5 - progress);
    vertex3 = vec2(1.0, 0.5 + progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}
 
 float blur_edge(vec2 bot1, vec2 bot2, vec2 top, vec2 testPt)
{
    vec2 lineDir = bot1 - top;
    vec2 perpDir = vec2(lineDir.y, -lineDir.x);
    vec2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));
    
    lineDir = bot2 - top;
    perpDir = vec2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);
    
    if (min_dist < 0.005)
    {
        return min_dist / 0.005;
    }
    else
    {
        return 1.0;
    };
}
 
 vec4 transition(sampler inputImage1, sampler inputImage2, float progress)
{
    vec2 uv = samplerTransform(inputImage1, destCoord());
    vec4 color1 = sample(inputImage1, uv);
    vec4 color2 = sample(inputImage2, samplerTransform(inputImage2, destCoord()));
    
    if (progress <= 0.0)
    {
        return color1;
    }
    
    if (in_left_triangle(uv, progress))
    {
        if (uv.x < 0.5)
        {
            vec2 vertex1 = vec2(progress, 0.5);
            vec2 vertex2 = vec2(0.0, 0.5 - progress);
            vec2 vertex3 = vec2(0.0, 0.5 + progress);
            return mix(
                       color1,
                       color2,
                       blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        }
        else
        {
            if (progress > 0.0)
            {
                return color2;
            }
            else
            {
                return color1;
            }
        }
    }
    else if (in_right_triangle(uv, progress))
    {
        if (uv.x >= 0.5)
        {
            vec2 vertex1 = vec2(1.0 - progress, 0.5);
            vec2 vertex2 = vec2(1.0, 0.5 - progress);
            vec2 vertex3 = vec2(1.0, 0.5 + progress);
            return mix(
                       color1,
                       color2,
                       blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        }
        else
        {
            return color1;
        }
    }
    else
    {
        return color1;
    }
}
 
 kernel vec4 customTransition(sampler inputImage1, sampler inputImage2, float progress)
{
    return transition(inputImage1, inputImage2, progress);
}
);

static CIKernel* customBowTieHorizontalTransitionKernel = nil;
@implementation CICustomBowTieHorizontalTransition

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        if (!customBowTieHorizontalTransitionKernel)
        {
            customBowTieHorizontalTransitionKernel = [CIKernel kernelWithString:customBowTieHorizontalTransitionKernelString];
        }
    }
    
    self.progress = @(0.0);
    return self;
}

- (CIImage *)outputImage
{
    CIImage* result = [customBowTieHorizontalTransitionKernel applyWithExtent:_inputImage.extent
                                                                roiCallback:^CGRect(int index, CGRect destRect){return destRect;}
                                                                  arguments:@[_inputImage, _targetImage, self.progress]];
    return result;
}

@end
