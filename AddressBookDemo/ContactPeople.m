//
//  ContactPeople.m
//  AddressBookDemo
//
//  Created by 高万里 on 15/3/11.
//  Copyright (c) 2015年 Gaowl. All rights reserved.
//

#import "ContactPeople.h"

@implementation ContactPeople

- (instancetype)initWithName:(NSString *)name andGroupName:(NSString *)groupName andMobilePhoneNumber:(NSString *)mobilePhoneNumber
{
    if (self = [super init])
    {
        self.name = name;
        self.groupName = groupName;
        self.mobilePhoneNumber = mobilePhoneNumber;
    }
    return self;
}

+ (instancetype)contactPeopleWithName:(NSString *)name andGroupName:(NSString *)groupName andMobilePhoneNumber:(NSString *)mobilePhoneNumber
{
    return [[self alloc]initWithName:name andGroupName:groupName andMobilePhoneNumber:mobilePhoneNumber];
}

@end
