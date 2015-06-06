//
//  AddressBookTableViewController.m
//  AddressBookDemo
//
//  Created by Gaowl on 15/3/10.
//  Copyright (c) 2015年 Gaowl. All rights reserved.
//

#import "AddressBookTableViewController.h"
#import <AddressBook/AddressBook.h>
#import "ContactPeople.h"
#import "pinyin.h"
#import "ContactPeopleGroup.h"

@interface AddressBookTableViewController ()

/**所有联系人*/
@property (nonatomic, strong) NSMutableArray *contactPeoples;
/**所有联系人分组*/
@property (nonatomic, strong) NSArray *contactPeopleGrous;

@property (nonatomic, weak) UIAlertView *alert;

@end

@implementation AddressBookTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.contactPeoples = [NSMutableArray array];

	CFErrorRef error = NULL;
	// 创建一个通讯录操作对象
	ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
	// 从未授权
	if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
		__weak typeof(self) weakSelf = self;

		// 请求权限
		ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
			if (granted) {
			    // 获取所有的联系人信息
			    [weakSelf gainAllContactPeople:addressBookRef];
			    [weakSelf.tableView reloadData];
			}
			else {
			    //用户拒绝访问通讯录,给用户提示设置应用访问通讯录
			    [weakSelf showAlertWithContent:@"通讯录访问权限不足"];
			}
		});
	}
	else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {// 已经拒绝
		//用户拒绝访问通讯录,给用户提示设置应用访问通讯录
		[self showAlertWithContent:@"通讯录访问权限不足"];
	}
	else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {// 已经取得权限
		// 获取所有的联系人信息
		[self gainAllContactPeople:addressBookRef];
		[self.tableView reloadData];
	}
}

/**获取所有的联系人信息*/
- (void)gainAllContactPeople:(ABAddressBookRef)addressBookRef {
	// 获取所有结果
	CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
	// 转换为可变数组
	CFMutableArrayRef mresults = CFArrayCreateMutableCopy(kCFAllocatorDefault,
	                                                      CFArrayGetCount(results),
	                                                      results);
	// 将结果按照拼音排序，将结果放入mresults数组中
	CFArraySortValues(mresults,
	                  CFRangeMake(0, CFArrayGetCount(results)),
	                  (CFComparatorFunction)ABPersonComparePeopleByName,
	                  NULL);

	NSInteger peopleCount = CFArrayGetCount(mresults);
	// 遍历所有联系人
	for (NSInteger i = 0; i < peopleCount; i++) {
		ABRecordRef record = CFArrayGetValueAtIndex(mresults, i);
		NSString *peopleName = (__bridge NSString *)(ABRecordCopyCompositeName(record));
		ABMultiValueRef phone = ABRecordCopyValue(record, kABPersonPhoneProperty);
		//        ABRecordID recordID = ABRecordGetRecordID(record);// 唯一ID
		NSInteger telNumberCount = ABMultiValueGetCount(phone);

		ContactPeople *people;
		// 遍历所有号码
		for (NSInteger j = 0; j < telNumberCount; j++) {
			NSString *personPhone = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, j);
			// 返回需要的手机号码
			personPhone = [self requiredPhoneNumber:personPhone];
			if (personPhone != nil) {
				if (peopleName.length == 0)
					peopleName = personPhone;
				NSString *groupName = [self requiredGroupName:peopleName];
				// 转换为模型
				people = [ContactPeople contactPeopleWithName:peopleName andGroupName:groupName andMobilePhoneNumber:personPhone];
			}
		}

		if (people)
			// 将模型存入数组
			[self.contactPeoples addObject:people];
	}
	[self sortAndGroupContactPeoples];
}

/**返回需要的手机号码*/
- (NSString *)requiredPhoneNumber:(NSString *)number {
	// 去掉“-”
	if ([number rangeOfString:@"-"].length >= 1)
		number = [[number componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789#*+"] invertedSet]] componentsJoinedByString:@""];

	// 去掉“+86”前缀
	if ([number hasPrefix:@"+86"])
		number = [number substringFromIndex:3];

	// 去掉空格和换行
	number = [number stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// 验证是否为手机号
	NSString *regex = @"^((13[0-9])|(147)|(15[^4,\\D])|(18[0-9]))\\d{8}$";
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	BOOL isMatch = [pred evaluateWithObject:number];

	return isMatch ? number : nil;
}

/**返回联系人分组名*/
- (NSString *)requiredGroupName:(NSString *)name {
	char firstChar = pinyinFirstLetter([name characterAtIndex:0]);
	if ((firstChar >= 'a' && firstChar <= 'z') || (firstChar >= 'A' && firstChar <= 'Z')) {
		if ([name hasPrefix:@"曾"])
			firstChar = 'Z';
		if ([name hasPrefix:@"解"])
			firstChar = 'X';
		if ([name hasPrefix:@"仇"])
			firstChar = 'Q';
		if ([name hasPrefix:@"朴"])
			firstChar = 'P';
		if ([name hasPrefix:@"查"])
			firstChar = 'Z';
		if ([name hasPrefix:@"能"])
			firstChar = 'N';
		if ([name hasPrefix:@"乐"])
			firstChar = 'Y';
		if ([name hasPrefix:@"单"])
			firstChar = 'S';
	}
	else
		firstChar = '#';
	return [[NSString stringWithFormat:@"%c", firstChar] uppercaseString];
}

/**排序和分组*/
- (void)sortAndGroupContactPeoples {
	// 取出所有的分组名
	NSMutableSet *setM = [NSMutableSet set];
	[self.contactPeoples enumerateObjectsUsingBlock: ^(ContactPeople *people, NSUInteger idx, BOOL *stop) {
	    [setM addObject:people.groupName];
	}];

	NSMutableArray *peopleGroupsM = [NSMutableArray array];
	// 遍历分组名列表
	[setM enumerateObjectsUsingBlock: ^(NSString *groupName, BOOL *stop) {
	    ContactPeopleGroup *peopleGroup = [[ContactPeopleGroup alloc]init];
	    peopleGroup.groupName = groupName;
	    // 取出分组下所有的联系人
	    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupName =%@", groupName];
	    NSArray *peoples = [self.contactPeoples filteredArrayUsingPredicate:predicate];

	    peopleGroup.peoples = peoples;
	    [peopleGroupsM addObject:peopleGroup];
	}];

	// 排序
	NSSortDescriptor *sortByGroupName = [[NSSortDescriptor alloc] initWithKey:@"groupName" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:sortByGroupName, nil];
	self.contactPeopleGrous = [peopleGroupsM sortedArrayUsingDescriptors:sortDescriptors];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.contactPeopleGrous.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	ContactPeopleGroup *group = self.contactPeopleGrous[section];
	return group.peoples.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ID = @"cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
	ContactPeopleGroup *group = self.contactPeopleGrous[indexPath.section];
	ContactPeople *people = group.peoples[indexPath.row];
	cell.textLabel.text = people.name;
	cell.detailTextLabel.text = people.mobilePhoneNumber;
	return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [self.contactPeopleGrous valueForKeyPath:@"groupName"];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	ContactPeopleGroup *group = self.contactPeopleGrous[section];
	return group.groupName;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	ContactPeopleGroup *group = self.contactPeopleGrous[indexPath.section];
	ContactPeople *people = group.peoples[indexPath.row];
	NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"telprompt://%@", people.mobilePhoneNumber];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}

- (void)showAlertWithContent:(NSString *)content {
	UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:content delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
	[alert show];
}

@end
