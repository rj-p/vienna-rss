//
//  MessageListView.m
//  Vienna
//
//  Created by Steve on Thu Mar 04 2004.
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

#import "MessageListView.h"
#import "AppController.h"

@implementation MessageListView

@dynamic delegate;

/* keyDown
 * Here is where we handle special keys when the article list view
 * has the focus so we can do custom things.
 */
-(void)keyDown:(NSEvent *)theEvent
{
	if (theEvent.characters.length == 1)
	{
		unichar keyChar = [theEvent.characters characterAtIndex:0];
		if ([APPCONTROLLER handleKeyDown:keyChar withFlags:theEvent.modifierFlags])
			return;
	}
	[super keyDown:theEvent];
}

/* copy
 * Handle the Copy action when the article list has focus.
 */
-(IBAction)copy:(id)sender
{
	if (self.selectedRow >= 0)
	{
		NSIndexSet * selectedRowIndexes = self.selectedRowIndexes;
		[self.delegate copyTableSelection:selectedRowIndexes toPasteboard:NSPasteboard.generalPasteboard];
	}
}

/* delete
 * Handle the Delete action when the article list has focus.
 */
-(IBAction)delete:(id)sender
{
	[APPCONTROLLER deleteMessage:self];
}

/* validateMenuItem
 * This is our override where we handle item validation for the
 * commands that we own.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(copy:))
	{
		return self.selectedRow >= 0;
	}
	if (menuItem.action == @selector(delete:))
	{
        return [self.delegate canDeleteMessageAtRow:self.selectedRow];
	}
	if (menuItem.action == @selector(selectAll:))
	{
		return YES;
	}
	return NO;
}

// Might as well allow text drags into other apps...
-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch(context) {
        case NSDraggingContextWithinApplication:
            return NSDragOperationCopy|NSDragOperationGeneric;
        default:
            return NSDragOperationCopy;
    }
}
@end
