//
//  ContactPeople.h
//  AddressBookDemo
//
//  Created by 高万里 on 15/3/11.
//  Copyright (c) 2015年 Gaowl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactPeople : NSObject

/**联系人*/
@property(nonatomic, copy) NSString *name;
/**分组名*/
@property(nonatomic, copy) NSString *groupName;
/**手机号码*/
@property(nonatomic, copy) NSString *mobilePhoneNumber;

+ (instancetype)contactPeopleWithName:(NSString *)name andGroupName:(NSString *)groupName andMobilePhoneNumber:(NSString *)mobilePhoneNumber;

@end
