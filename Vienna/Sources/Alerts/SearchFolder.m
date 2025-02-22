//
//  SearchFolder.m
//  Vienna
//
//  Created by Steve on Sun Apr 18 2004.
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

#import "SearchFolder.h"
#import "StringExtensions.h"
#import "AppController.h"
#import "HelperFunctions.h"
#import "Article.h"
#import "Folder.h"
#import "Criteria.h"
#import "Field.h"
#import "Database.h"
#import "Vienna-Swift.h"

// Tags for the three fields that define a criteria. We set these here
// rather than in IB to be consistent.
#define MA_SFEdit_FieldTag			1000
#define MA_SFEdit_OperatorTag		1001
#define MA_SFEdit_ValueTag			1002
#define MA_SFEdit_FlagValueTag		1003
#define MA_SFEdit_DateValueTag		1004
#define MA_SFEdit_NumberValueTag	1005
#define MA_SFEdit_AddTag			1006
#define MA_SFEdit_RemoveTag			1007
#define MA_SFEdit_FolderValueTag	1008

@interface SmartFolder ()

-(void)initFolderValueField:(NSInteger)parentId atIndent:(NSInteger)indentation;
-(void)initSearchSheet:(NSString *)folderName;
-(void)displaySearchSheet:(NSWindow *)window;
-(void)initForField:(NSString *)fieldName inRow:(NSView *)row;
-(void)setOperatorsPopup:(NSPopUpButton *)popUpButton operators:(NSArray *)operators;
-(void)addCriteria:(NSUInteger)index;
-(void)addDefaultCriteria:(NSInteger)index;
-(void)removeCriteria:(NSInteger)index;
-(void)removeAllCriteria;
-(void)resizeSearchWindow;

@end

@implementation SmartFolder

/* initWithDatabase
 * Just init the search criteria class.
 */
-(instancetype)initWithDatabase:(Database *)newDb
{
	if ((self = [super init]) != nil)
	{
		totalCriteria = 0;
		smartFolderId = -1;
		db = newDb;
		onScreen = NO;
		parentId = VNAFolderTypeRoot;
		arrayOfViews = [[NSMutableArray alloc] init];
	}
	return self;
}

/* newCriteria
 * Initialises the smart folder panel with a single default criteria to get
 * started.
 */
-(void)newCriteria:(NSWindow *)window underParent:(NSInteger)itemId
{
	[self initSearchSheet:@""];
	smartFolderId = -1;
	parentId = itemId;
	[smartFolderName setEnabled:YES];

	// Add a default criteria.
	[self addDefaultCriteria:0];
	[self displaySearchSheet:window];
}

/* loadCriteria
 * Loads the criteria for the specified folder,
 * then display the search sheet.
 */
-(void)loadCriteria:(NSWindow *)window folderId:(NSInteger)folderId
{
	Folder * folder = [db folderFromID:folderId];
	if (folder != nil)
	{
		NSInteger index = 0;

		[self initSearchSheet:folder.name];
		smartFolderId = folderId;
		[smartFolderName setEnabled:YES];

		// Load the criteria into the fields.
		CriteriaTree * criteriaTree = [db searchStringForSmartFolder:folderId];

		// Set the criteria condition
		[criteriaConditionPopup selectItemWithTag:criteriaTree.condition];

		for (Criteria * criteria in criteriaTree.criteriaEnumerator)
		{
			[self initForField:criteria.field inRow:searchCriteriaView];

            [operatorPopup selectItemWithTitle:[Criteria localizedStringFromOperator:criteria.operator]];

			Field * field = [nameToFieldMap valueForKey:criteria.field];
			[fieldNamePopup selectItemWithTitle:field.displayName];
			switch (field.type)
			{
				case VNAFieldTypeFlag: {
					NSInteger tag;
					if([criteria.value isEqualToString:@"Yes"]) {
						tag=1;
					} else {
						tag=2;
					}
					BOOL found = [flagValueField selectItemWithTag:tag];
					NSAssert (found, @"No menu item selected");
					break;
				}

				case VNAFieldTypeFolder: {
					Folder * folder = [db folderFromName:criteria.value];
					if (folder != nil)
						[folderValueField selectItemWithTitle:folder.name];
					break;
				}

				case VNAFieldTypeString: {
					valueField.stringValue = criteria.value;
					break;
				}

				case VNAFieldTypeInteger: {
					numberValueField.stringValue = criteria.value;
					break;
				}

				case VNAFieldTypeDate: {
					[dateValueField selectItemAtIndex:[dateValueField indexOfItemWithRepresentedObject:criteria.value]];
					break;
				}
			}

			[self addCriteria:index++];
		}

		// We defer sizing the window until all the criteria are
		// added and displayed, otherwise it looks crap.
		[self displaySearchSheet:window];
		[self resizeSearchWindow];
	}
}

/* initSearchSheet
 */
-(void)initSearchSheet:(NSString *)folderName
{
	// Clean up from any last run.
	if (totalCriteria > 0)
		[self removeAllCriteria];

	// Initialize UI
	if (!searchWindow)
	{
		NSArray * objects;
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"SearchFolder" owner:self topLevelObjects:&objects];
		self.topObjects = objects;

		// Register our notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextDidChange:) name:NSControlTextDidChangeNotification object:smartFolderName];

		// Create a mapping for field to column names
		nameToFieldMap = [[NSMutableDictionary alloc] init];

		// Initialize the search criteria view popups with all the
		// fields in the database.

		[fieldNamePopup removeAllItems];
		for (Field * field in [db arrayOfFields])
		{
			if (field.tag != ArticleFieldIDHeadlines &&
				field.tag != ArticleFieldIDGUID &&
				field.tag != ArticleFieldIDLink &&
				field.tag != ArticleFieldIDComments &&
				field.tag != ArticleFieldIDSummary &&
				field.tag != ArticleFieldIDParent &&
				field.tag != ArticleFieldIDEnclosure &&
				field.tag != ArticleFieldIDEnclosureDownloaded)
			{
				[fieldNamePopup addItemWithTitle:field.displayName representedObject:field];
				[nameToFieldMap setValue:field forKey:field.name];
			}
		}
		
		// Set Yes/No values on flag fields
		[flagValueField removeAllItems];
		[flagValueField addItemWithTitle:NSLocalizedString(@"Yes", nil) tag:1 representedObject:@"Yes"];
		[flagValueField addItemWithTitle:NSLocalizedString(@"No", nil) tag:2 representedObject:@"No"];

		// Set date popup values
		[dateValueField removeAllItems];
		[dateValueField addItemWithTitle:NSLocalizedString(@"Today", nil) representedObject:@"today"];
		[dateValueField addItemWithTitle:NSLocalizedString(@"Yesterday", nil) representedObject:@"yesterday"];
		[dateValueField addItemWithTitle:NSLocalizedString(@"Last Week", nil) representedObject:@"last week"];

		// Set the tags on the controls
		[fieldNamePopup setTag:MA_SFEdit_FieldTag];
		[operatorPopup setTag:MA_SFEdit_OperatorTag];
		[valueField setTag:MA_SFEdit_ValueTag];
		[flagValueField setTag:MA_SFEdit_FlagValueTag];
		[dateValueField setTag:MA_SFEdit_DateValueTag];
		[folderValueField setTag:MA_SFEdit_FolderValueTag];
		[numberValueField setTag:MA_SFEdit_NumberValueTag];
		[removeCriteriaButton setTag:MA_SFEdit_RemoveTag];
		[addCriteriaButton setTag:MA_SFEdit_AddTag];
	}

	// Initialise the folder control with a list of all folders
	// in the database.
	[folderValueField removeAllItems];
	[self initFolderValueField:VNAFolderTypeRoot atIndent:0];
	
	// Init the folder name field and disable the Save button if it is blank
	smartFolderName.stringValue = folderName;
	saveButton.enabled = !folderName.vna_isBlank;
}

/* initFolderValueField
 * Fill the folder value field popup menu with a list of all RSS and group
 * folders in the database under the specified folder ID. The indentation value
 * is used to indent the items in the menu when they are part of a group. I've used
 * an increment of 2 which looks clearer than 1 in the UI.
 */
-(void)initFolderValueField:(NSInteger)fromId atIndent:(NSInteger)indentation
{
	for (Folder * folder in [[db arrayOfFolders:fromId] sortedArrayUsingSelector:@selector(folderNameCompare:)])
	{
		if (folder.type == VNAFolderTypeRSS||folder.type == VNAFolderTypeOpenReader||folder.type == VNAFolderTypeGroup)
		{
			[folderValueField addItemWithTitle:folder.name];
			NSMenuItem * menuItem = [folderValueField itemWithTitle:folder.name];
			// Workaround for an exception in -addCriteria:. The reason is that
			// SF Symbol images cannot be encoded with NSArchiver.
			menuItem.image = folder.archivableImage;
			menuItem.indentationLevel = indentation;
			if (folder.type == VNAFolderTypeGroup)
				[self initFolderValueField:folder.itemId atIndent:indentation + 2];
		}
	}
}

/* displaySearchSheet
 * Display the search sheet.
 */
-(void)displaySearchSheet:(NSWindow *)window
{
	// Begin the sheet
	onScreen = YES;
	[window beginSheet:searchWindow completionHandler:nil];
	// Remember the initial size of the dialog sheet
	// before addition of any criteria that would
	// cause it to be resized. We need to know this
	// to shrink it back to its default size.
	searchWindowFrame = [NSWindow contentRectForFrameRect:searchWindow.frame styleMask:searchWindow.styleMask];
}

/* removeCurrentCriteria
 * Remove the current criteria row
 */
-(IBAction)removeCurrentCriteria:(id)sender
{
	NSInteger index = [arrayOfViews indexOfObject:[sender superview]];
	NSAssert(index >= 0 && index < totalCriteria, @"Got an out of bounds index of view in superview");
	[self removeCriteria:index];
	[self resizeSearchWindow];
}

/* addNewCriteria
 * Add another criteria row.
 */
-(IBAction)addNewCriteria:(id)sender
{
	NSInteger index = [arrayOfViews indexOfObject:[sender superview]];
	NSAssert(index >= 0 && index < totalCriteria, @"Got an out of bounds index of view in superview");
	[self addDefaultCriteria:index + 1];
	[self resizeSearchWindow];
}

/* addDefaultCriteria
 * Add a new default criteria row. For this we use the static defaultField declared at
 * the start of this source and the default operator for that field, and an empty value.
 */
-(void)addDefaultCriteria:(NSInteger)index
{
	Field * defaultField = [db fieldByName:MA_Field_Read];

	[self initForField:defaultField.name inRow:searchCriteriaView];
	[fieldNamePopup selectItemWithTitle:defaultField.displayName];
	valueField.stringValue = @"";
	[self addCriteria:index];
}

/* fieldChanged
 * Handle the case where the field has changed. Update the valid list of
 * operators for the selected field.
 */
- (IBAction)fieldChanged:(NSPopUpButton *)sender {
	Field *field = sender.selectedItem.representedObject;
	[self initForField:field.name inRow:sender.superview];
}

/* initForField
 * Initialise the operator and value fields for the specified field.
 */
-(void)initForField:(NSString *)fieldName inRow:(NSView *)row
{
	Field * field = [nameToFieldMap valueForKey:fieldName];
	NSAssert1(field != nil, @"Got nil field for field '%@'", fieldName);

	// Need to flip on the operator popup for the field that changed
	NSPopUpButton * theOperatorPopup = [row viewWithTag:MA_SFEdit_OperatorTag];
	[theOperatorPopup removeAllItems];	
	switch (field.type)
	{
		case VNAFieldTypeFlag:
			[self setOperatorsPopup:theOperatorPopup operators:@[
									@(MA_CritOper_Is)]
									];
			break;

		case VNAFieldTypeFolder:
			[self setOperatorsPopup:theOperatorPopup operators:@[
									@(MA_CritOper_Is),
									@(MA_CritOper_IsNot)]
									];
			break;

		case VNAFieldTypeString:
			[self setOperatorsPopup:theOperatorPopup operators:@[
									@(MA_CritOper_Is),
									@(MA_CritOper_IsNot),
									@(MA_CritOper_Contains),
									@(MA_CritOper_NotContains)]
									];
			break;

		case VNAFieldTypeInteger:
			[self setOperatorsPopup:theOperatorPopup operators:@[
									@(MA_CritOper_Is),
									@(MA_CritOper_IsNot),
									@(MA_CritOper_IsGreaterThan),
									@(MA_CritOper_IsGreaterThanOrEqual),
									@(MA_CritOper_IsLessThan),
									@(MA_CritOper_IsLessThanOrEqual)]
									];
			break;

		case VNAFieldTypeDate:
			[self setOperatorsPopup:theOperatorPopup operators:@[
									@(MA_CritOper_Is),
									@(MA_CritOper_IsAfter),
									@(MA_CritOper_IsBefore),
									@(MA_CritOper_IsOnOrAfter),
									@(MA_CritOper_IsOnOrBefore)]
									];
			break;
	}

	// Show and hide the value fields depending on the type
	NSView * theValueField = [row viewWithTag:MA_SFEdit_ValueTag];
	NSView * theFlagValueField = [row viewWithTag:MA_SFEdit_FlagValueTag];
	NSView * theNumberValueField = [row viewWithTag:MA_SFEdit_NumberValueTag];
	NSView * theDateValueField = [row viewWithTag:MA_SFEdit_DateValueTag];
	NSView * theFolderValueField = [row viewWithTag:MA_SFEdit_FolderValueTag];

	theFlagValueField.hidden = field.type != VNAFieldTypeFlag;
	theValueField.hidden = field.type != VNAFieldTypeString;
	theDateValueField.hidden = field.type != VNAFieldTypeDate;
	theNumberValueField.hidden = field.type != VNAFieldTypeInteger;
	theFolderValueField.hidden = field.type != VNAFieldTypeFolder;
}

/* setOperatorsPopup
 * Fills the specified pop up button field with a list of valid operators.
 */
-(void)setOperatorsPopup:(NSPopUpButton *)popUpButton operators:(NSArray *)operators
{
	for ( NSNumber * number in operators )
	{
        CriteriaOperator operator = number.integerValue;
		NSString * operatorString = [Criteria localizedStringFromOperator:operator];
        [popUpButton addItemWithTitle:operatorString tag:operator];
	}
}

/* doSave
 * Create a CriteriaTree from the criteria rows and save this to the
 * database.
 */
-(IBAction)doSave:(id)sender
{
	NSString * folderName = (smartFolderName.stringValue).vna_trimmed;
	NSAssert(![folderName vna_isBlank], @"doSave called with empty folder name");
	NSUInteger  c;

	// Check whether there is another folder with the same name.
	Folder * folder = [db folderFromName:folderName];
	if (folder != nil && folder.itemId != smartFolderId)
	{
		runOKAlertPanel(NSLocalizedString(@"Cannot rename folder", nil), NSLocalizedString(@"A folder with that name already exists", nil));
		return;
	}

	// Build the criteria string
	CriteriaTree * criteriaTree = [[CriteriaTree alloc] init];
	for (c = 0; c < arrayOfViews.count; ++c)
	{
		NSView * row = arrayOfViews[c];
		NSPopUpButton * theField = [row viewWithTag:MA_SFEdit_FieldTag];
		NSPopUpButton * theOperator = [row viewWithTag:MA_SFEdit_OperatorTag];

		Field * field = theField.selectedItem.representedObject;
		CriteriaOperator operator = theOperator.selectedItem.tag;
		NSString * valueString;

		if (field.type == VNAFieldTypeFlag)
		{
			NSPopUpButton * theValue = [row viewWithTag:MA_SFEdit_FlagValueTag];
			valueString = theValue.selectedItem.representedObject;
		}
		else if (field.type == VNAFieldTypeDate)
		{
			NSPopUpButton * theValue = [row viewWithTag:MA_SFEdit_DateValueTag];
			valueString = theValue.selectedItem.representedObject;
		}
		else if (field.type == VNAFieldTypeFolder)
		{
			NSPopUpButton * theValue = [row viewWithTag:MA_SFEdit_FolderValueTag];
			valueString = theValue.titleOfSelectedItem;
		}
		else if (field.type == VNAFieldTypeInteger)
		{
			NSTextField * theValue = [row viewWithTag:MA_SFEdit_NumberValueTag];
			valueString = theValue.stringValue;
		}
		else
		{
			NSTextField * theValue = [row viewWithTag:MA_SFEdit_ValueTag];
			valueString = theValue.stringValue;
		}

		Criteria * newCriteria = [[Criteria alloc] initWithField:field.name withOperator:operator withValue:valueString];
		[criteriaTree addCriteria:newCriteria];
	}

	// Set the criteria condition
	criteriaTree.condition = criteriaConditionPopup.selectedTag;
	
	if (smartFolderId == -1)
	{
		AppController * controller = APPCONTROLLER;
		smartFolderId = [[Database sharedManager] addSmartFolder:folderName underParent:parentId withQuery:criteriaTree];
		[controller selectFolder:smartFolderId];
	}
	else
    {
		[[Database sharedManager] updateSearchFolder:smartFolderId withFolder:folderName withQuery:criteriaTree];
    }

	
	[searchWindow.sheetParent endSheet:searchWindow];
	[searchWindow orderOut:self];
	onScreen = NO;
}

/* doCancel
 */
-(IBAction)doCancel:(id)sender
{
	[searchWindow.sheetParent endSheet:searchWindow];
	[searchWindow orderOut:self];
	onScreen = NO;
}

/* handleTextDidChange [delegate]
 * This function is called when the contents of the input field is changed.
 * We disable the Save button if the input field is empty or enable it otherwise.
 */
-(void)handleTextDidChange:(NSNotification *)aNotification
{
	NSString * folderName = smartFolderName.stringValue;
	saveButton.enabled = !folderName.vna_isBlank;
}

/* removeAllCriteria
 * Remove all existing criteria (i.e. reset the views back to defaults).
 */
-(void)removeAllCriteria
{
	NSInteger c;

	NSArray * subviews = searchCriteriaSuperview.subviews;
	for (c = subviews.count - 1; c >= 0; --c)
	{
		NSView * row = subviews[c];
		[row removeFromSuperview];
	}
	[arrayOfViews removeAllObjects];
	totalCriteria = 0;
	// reset the dialog sheet size
	[searchWindow setFrame:searchWindowFrame display:NO];
}

/* removeCriteria
 * Remove the criteria at the specified index.
 */
-(void)removeCriteria:(NSInteger)index
{
	NSInteger rowHeight = searchCriteriaView.frame.size.height;
	NSInteger c;

	// Do nothing if there's just one criteria
	if (totalCriteria <= 1)
		return;
	
	// Remove the view from the parent view
	NSView * row = arrayOfViews[index];
	[row removeFromSuperview];
	[arrayOfViews removeObject:row];
	--totalCriteria;
	
	// Shift up the remaining subviews
	for (c = index ; c < arrayOfViews.count; ++c) {
		NSView * row = arrayOfViews[c];
		NSPoint origin = row.frame.origin;
		[row setFrameOrigin:NSMakePoint(origin.x, origin.y + rowHeight)];
	}
}

/* addCriteria
 * Add a new criteria clause. Before calling this function, initialise the
 * searchView with the settings to be added.
 */
-(void)addCriteria:(NSUInteger)index
{
	NSData * archRow;
	NSInteger rowHeight = searchCriteriaView.frame.size.height;
	NSUInteger  c;

	if (index > arrayOfViews.count)
		index = arrayOfViews.count;

	// Now add the new subview
    //
    // FIXME: NSArchiver and NSUnarchiver are deprecated since macOS 10.13
    //
    // NSArchiver and NSUnarchiver are used here to copy searchCriteriaView.
    // NSKeyedArchiver is not a replacement for this.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	archRow = [NSArchiver archivedDataWithRootObject:searchCriteriaView];
	NSRect bounds = searchCriteriaSuperview.bounds;
	NSView * row = (NSView *)[NSUnarchiver unarchiveObjectWithData:archRow];
#pragma clang diagnostic pop
	if (onScreen) {
		[row setFrameOrigin:NSMakePoint(bounds.origin.x, bounds.origin.y + (NSInteger)(totalCriteria - 1 - index) * rowHeight)];
	} else {  // computation is affected by resizeSearchWindow being called only once, after the search panel is displayed
		[row setFrameOrigin:NSMakePoint(bounds.origin.x, bounds.origin.y  - index * rowHeight)];
	}
	[searchCriteriaSuperview addSubview:row];
	[arrayOfViews insertObject:row atIndex:index];

	// Shift down the existing subviews by rowHeight
	for (c = index + 1; c < arrayOfViews.count; ++c) {
		NSView * row = arrayOfViews[c];
		NSPoint origin = row.frame.origin;
		[row setFrameOrigin:NSMakePoint(origin.x, origin.y - rowHeight)];
	}
	// Bump up the criteria count
	++totalCriteria;
}

/* resizeSearchWindow
 * Resize the search window for the number of criteria 
 */
-(void)resizeSearchWindow
{
	NSRect newFrame;

	newFrame = searchWindowFrame;
	if (totalCriteria > 0)
	{
		NSInteger rowHeight = searchCriteriaView.frame.size.height;
		NSInteger additionalHeight = rowHeight * (totalCriteria - 1);
		newFrame.origin.y -= additionalHeight;
		newFrame.size.height += additionalHeight;
		newFrame = [NSWindow frameRectForContentRect:newFrame styleMask:searchWindow.styleMask];
	}
	[searchWindow setFrame:newFrame display:YES animate:YES];
}

/* dealloc
 * Clean up and release resources.
 */
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
