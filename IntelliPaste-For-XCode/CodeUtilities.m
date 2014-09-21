//
//  CodeUtilities.m
//  IntelliPaste
//
//  Created by Robert Gummesson on 09/06/2014.
//  Copyright (c) 2014 Cane Media Limited. All rights reserved.
//

#import "CodeUtilities.h"

@implementation CodeUtilities

+ (NSArray *)methodsFromText:(NSString *)text
{
    NSCharacterSet *const characterSetMethods = [NSCharacterSet characterSetWithCharactersInString:@"+-{}#"];
    NSCharacterSet *const characterSetHeaders = [NSCharacterSet characterSetWithCharactersInString:@"+-;#"];
    
    NSRange range = NSMakeRange(0, text.length);
    NSArray *methodsMethod = [self methodsFromText:text range:&range characterSet:characterSetMethods isRoot:YES];
    NSArray *methodsHeader = [self methodsFromText:text range:&range characterSet:characterSetHeaders isRoot:YES];
    
    if (methodsMethod.count > methodsHeader.count) {
        return methodsMethod;
    } else if (methodsHeader.count > methodsMethod.count) {
        return methodsHeader;
    } else {
        NSInteger methodCharacterLength = [[methodsMethod valueForKeyPath:@"@sum.length"] integerValue];
        NSInteger headerCharacterLength = [[methodsHeader valueForKeyPath:@"@sum.length"] integerValue];
        return headerCharacterLength > methodCharacterLength ? methodsMethod : methodsHeader;
    }
}

+ (NSArray *)methodsFromText:(NSString *)text range:(NSRangePointer)rangePointer characterSet:(NSCharacterSet *)characterSet isRoot:(BOOL)isRoot
{
    NSRange range = NSMakeRange(rangePointer->location, rangePointer->length);
    NSUInteger previousLocation = range.location;
    
    NSMutableArray *methods = [NSMutableArray array];
    NSCharacterSet *const characterSetDefault = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
    
    BOOL isMethod = NO, canBeMethod = YES, isOpen = NO;
    
    range.location = [text rangeOfCharacterFromSet:characterSet options:0 range:range].location;
    while (range.location != NSNotFound) {
        range.length = text.length - range.location;
        
        char token = [text characterAtIndex:range.location];
        switch (token) {
            case '+':
            case '-':
                if (isMethod) {
                    return nil;
                }
                isMethod = canBeMethod;
                break;
                
            case '{':
            case ';':
            {
                if (isRoot && !isMethod) {
                    break;
                }
                isMethod = NO;
                isOpen = YES;
                
                if (isRoot) {
                    previousLocation--;
                    canBeMethod = token == ';';
                    
                    NSString *method = [text substringWithRange:NSMakeRange(previousLocation, range.location - previousLocation)];
                    [methods addObject:[method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
                range.location++;
                range.length--;
                [self methodsFromText:text range:&range characterSet:characterSetDefault isRoot:NO];
                canBeMethod = YES;
                break;
            }
                
            case '}':
                rangePointer->location = ++range.location;
                rangePointer->length = --range.length;
                if (!isRoot || isOpen) {
                    return methods;
                }
                break;
                
            case '#':
                if (!isMethod) {
                    // For pragma marks, move to the next line
                    NSCharacterSet *const lineBreakCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
                    NSUInteger location = [text rangeOfCharacterFromSet:lineBreakCharacterSet options:0 range:range].location;
                    
                    if (location != NSNotFound) {
                        range.length -= location - range.location;
                        range.location = location;
                    }
                }
                break;
        }
        
        if (!range.length) {
            break;
        }
        
        range.location++;
        range.length--;
        
        NSUInteger location = [text rangeOfCharacterFromSet:characterSet options:0 range:range].location;
        if (location == NSNotFound) {
            if (isRoot && isMethod) {
                NSString *method = [text substringWithRange:NSMakeRange(previousLocation, text.length - previousLocation)];
                [methods addObject:[method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
            break;
        } else {
            previousLocation = range.location;
            range.location = location;
        }
    }
    return methods;
}

@end
