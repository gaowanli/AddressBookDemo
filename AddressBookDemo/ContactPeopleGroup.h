//
//  ContactPeopleGroup.h
//  AddressBookDemo
//
//  Created by Gaowl on 15/5/25.
//  Copyright (c) 2015年 Gaowl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactPeopleGroup : NSObject

/**分组名*/
@property(nonatomic, copy) NSString *groupName;
/**所有的联系人存放ContactPeople对象数组*/
@property(nonatomic, strong) NSArray *peoples;

@end
