//
//  CriteriaTree.m
//  Vienna
//
//  Created by Steve on Thu Apr 29 2004.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Criteria.h"

@implementation Criteria

/* init
 * Initialise an empty Criteria.
 */
-(instancetype)init
{
	return [self initWithField:@"" withOperator:0 withValue:@""];
}

/* initWithField
 * Initalises a new Criteria with the specified values.
 */
-(instancetype)initWithField:(NSString *)newField withOperator:(CriteriaOperator)newOperator withValue:(NSString *)newValue
{
	if ((self = [super init]) != nil)
	{
		self.field = newField;
		self.operator = newOperator;
		self.value = newValue;
	}
	return self;
}

/* operatorString
 * Returns the localized string representation of the operator.
 */
+(NSString *)localizedStringFromOperator:(CriteriaOperator)op
{
	NSString * operatorString = nil;
	switch (op)
	{
		case MA_CritOper_Is:					operatorString = NSLocalizedString(@"is", @"test for a value"); break;
		case MA_CritOper_IsNot:					operatorString = NSLocalizedString(@"is not", @"test for a value"); break;
		case MA_CritOper_IsAfter:				operatorString = NSLocalizedString(@"is after", @"test for a date"); break;
		case MA_CritOper_IsBefore:				operatorString = NSLocalizedString(@"is before", @"test for a date"); break;
		case MA_CritOper_IsOnOrAfter:			operatorString = NSLocalizedString(@"is on or after", @"test for a date"); break;
		case MA_CritOper_IsOnOrBefore:			operatorString = NSLocalizedString(@"is on or before", @"test for a date"); break;
		case MA_CritOper_Contains:				operatorString = NSLocalizedString(@"contains",@"test for a string"); break;
		case MA_CritOper_NotContains:			operatorString = NSLocalizedString(@"does not contain", @"test for a string"); break;
		case MA_CritOper_Under:					operatorString = NSLocalizedString(@"under", @"test for a folder (not operational as of Vienna 3.2)"); break;
		case MA_CritOper_NotUnder:				operatorString = NSLocalizedString(@"not under", @"test for a folder (not operational as of Vienna 3.2)"); break;
		case MA_CritOper_IsLessThan:			operatorString = NSLocalizedString(@"is less than", @"test for a numeric value"); break;
		case MA_CritOper_IsGreaterThan:			operatorString = NSLocalizedString(@"is greater than", @"test for a numeric value"); break;
		case MA_CritOper_IsLessThanOrEqual:		operatorString = NSLocalizedString(@"is less than or equal to", @"test for a numeric value"); break;
		case MA_CritOper_IsGreaterThanOrEqual:	operatorString = NSLocalizedString(@"is greater than or equal to", @"test for a numeric value"); break;
	}
	return operatorString;
}

/* arrayOfOperators
 * Returns an array of NSNumbers that represent all supported operators.
 */
+(NSArray *)arrayOfOperators
{
	return @[
			 @(MA_CritOper_Is),
			 @(MA_CritOper_IsNot),
			 @(MA_CritOper_IsAfter),
			 @(MA_CritOper_IsBefore),
			 @(MA_CritOper_IsOnOrAfter),
			 @(MA_CritOper_IsOnOrBefore),
			 @(MA_CritOper_Contains),
			 @(MA_CritOper_NotContains),
			 @(MA_CritOper_IsLessThan),
			 @(MA_CritOper_IsLessThanOrEqual),
			 @(MA_CritOper_IsGreaterThan),
			 @(MA_CritOper_IsGreaterThanOrEqual),
			 @(MA_CritOper_Under),
			 @(MA_CritOper_NotUnder)
			 ];
}

/* setField
 * Sets the field element of a criteria.
 */
-(void)setField:(NSString *)newField
{
	field = [newField copy];
}

/* setOperator
 * Sets the operator element of a criteria.
 */
-(void)setOperator:(CriteriaOperator)newOperator
{
	// Convert deprecated under/not-under operators
	// to is/is-not.
	if (newOperator == MA_CritOper_Under)
		newOperator = MA_CritOper_Is;
	if (newOperator == MA_CritOper_NotUnder)
		newOperator = MA_CritOper_IsNot;
	operator = newOperator;
}

/* setValue
 * Sets the value element of a criteria.
 */
-(void)setValue:(NSString *)newValue
{
	value = [newValue copy];
}

/* field
 * Returns the field element of a criteria.
 */
-(NSString *)field
{
	return field;
}

/* operator
 * Returns the operator element of a criteria
 */
-(CriteriaOperator)operator
{
	return operator;
}

/* value
 * Returns the value element of a criteria.
 */
-(NSString *)value
{
	return value;
}

@end


@implementation CriteriaTree

/* init
 * Initialise an empty CriteriaTree
 */
-(instancetype)init
{
	return [self initWithString:@""];
}

/* initWithString
 * Initialises an criteria tree object with the specified string. The caller is responsible for
 * releasing the tree.
 */
-(instancetype)initWithString:(NSString *)string
{
	if ((self = [super init]) != nil)
	{
		criteriaTree = [[NSMutableArray alloc] init];
		condition = MA_CritCondition_All;
        NSError *error = nil;
        NSXMLDocument *criteriaTreeDoc = [[NSXMLDocument alloc]
                                          initWithXMLString:string
                                          options:NSXMLNodeOptionsNone
                                          error:&error];
        
		if (!error)
		{
            NSArray *criteriaArray = [criteriaTreeDoc.rootElement elementsForName:@"criteria"];
            condition = [CriteriaTree conditionFromString:[criteriaTreeDoc.rootElement attributeForName:@"condition"].stringValue];
            if (condition == MA_CritCondition_Invalid) {
                // For backward compatibility, the absence of the condition attribute
                // assumes that we're matching ALL conditions.
                condition = MA_CritCondition_All;
            }
            
            for (NSXMLElement *criteriaElement in criteriaArray) {
                NSString *fieldname = [criteriaElement attributeForName:@"field"].stringValue;
                NSString *operator = [criteriaElement elementsForName:@"operator"].firstObject.stringValue;
                NSString *value = [criteriaElement elementsForName:@"value"].firstObject.stringValue;
                
                Criteria *newCriteria = [[Criteria alloc]
                                         initWithField:fieldname
                                         withOperator:operator.integerValue
                                         withValue:value];
                [self addCriteria:newCriteria];
                
            }
        }
	}
	return self;
}

/* conditionFromString
 * Converts a condition string to its condition value. Returns -1 if the
 * string is invalid.
 * Note: the strings which are written to the XML file are NOT localized.
 */
+(CriteriaCondition)conditionFromString:(NSString *)string
{
	if (string != nil)
	{
		if ([string.lowercaseString isEqualToString:@"any"])
			return MA_CritCondition_Any;
		if ([string.lowercaseString isEqualToString:@"all"])
			return MA_CritCondition_All;
	}
	return MA_CritCondition_Invalid;
}

/* conditionToString
 * Returns the string representation of the specified condition.
 * Note: Do NOT localise these strings. They're written to the XML file.
 */
+(NSString *)conditionToString:(CriteriaCondition)condition
{
	if (condition == MA_CritCondition_Any)
		return @"any";
	if (condition == MA_CritCondition_All)
		return @"all";
	return @"";
}

/* condition
 * Return the criteria condition.
 */
-(CriteriaCondition)condition
{
	return condition;
}

/* setCondition
 * Sets the criteria condition.
 */
-(void)setCondition:(CriteriaCondition)newCondition
{
	condition = newCondition;
}

/* criteriaEnumerator
 * Returns an enumerator that will iterate over the criteria
 * object. We do it this way because we can't necessarily guarantee
 * that the criteria will be stored in an NSArray or any other collection
 * object for which NSEnumerator is supported.
 */
-(NSEnumerator *)criteriaEnumerator
{
	return [criteriaTree objectEnumerator];
}

/* addCriteria
 * Adds the specified criteria to the criteria array.
 */
-(void)addCriteria:(Criteria *)newCriteria
{
	[criteriaTree addObject:newCriteria];
}

/* string
 * Returns the complete criteria tree as a string.
 */
-(NSString *)string
{
    NSXMLDocument *criteriaDoc = [NSXMLDocument document];
    [criteriaDoc setStandalone:YES];
    criteriaDoc.characterEncoding = @"UTF-8";
    criteriaDoc.version = @"1.0";
    
    NSDictionary * conditionDict = @{@"condition": [CriteriaTree conditionToString:condition]};
    NSXMLElement *criteriaGroup = [[NSXMLElement alloc] initWithName:@"criteriagroup"];
    [criteriaGroup setAttributesWithDictionary:conditionDict];
    
    for (Criteria *criteria in criteriaTree) {
        NSDictionary * criteriaDict = @{@"field": criteria.field};
        NSXMLElement *criteriaElement = [[NSXMLElement alloc] initWithName:@"criteria"];
        [criteriaElement setAttributesWithDictionary:criteriaDict];
        NSXMLElement *operatorElement = [[NSXMLElement alloc]
                                        initWithName:@"operator"
                                        stringValue:[NSString stringWithFormat:
                                                     @"%lu", (unsigned long)criteria.operator]];
        NSXMLElement *valueElement = [[NSXMLElement alloc]
                                        initWithName:@"value"
                                        stringValue:criteria.value];
        
        [criteriaGroup addChild:criteriaElement];
        [criteriaElement addChild:operatorElement];
        [criteriaElement addChild:valueElement];
        
    }
    [criteriaDoc addChild:criteriaGroup];
    
	return criteriaDoc.XMLString;
}

@end
