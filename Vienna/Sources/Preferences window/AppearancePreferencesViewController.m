//
//  AppearancePreferencesViewController.m
//  Vienna
//
//  Created by Joshua Pore on 22/11/2014.
//  Copyright (c) 2014 uk.co.opencommunity. All rights reserved.
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

#import "AppearancePreferencesViewController.h"
#import "Preferences.h"

// List of minimum font sizes. I picked the ones that matched the same option in
// Safari but you easily could add or remove from the list as needed.
static NSInteger const availableMinimumFontSizes[] = { 9, 10, 11, 12, 14, 18, 24 };
#define countOfAvailableMinimumFontSizes  (sizeof(availableMinimumFontSizes)/sizeof(availableMinimumFontSizes[0]))


@interface AppearancePreferencesViewController ()
-(void)initializePreferences;
-(void)selectUserDefaultFont:(NSString *)name size:(NSInteger)size control:(NSTextField *)control;

@end

@implementation AppearancePreferencesViewController

- (void)viewDidLoad {
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleReloadPreferences:) name:@"MA_Notify_ArticleListFontChange" object:nil];
    [nc addObserver:self selector:@selector(handleReloadPreferences:) name:kMA_Notify_MinimumFontSizeChange object:nil];
    [nc addObserver:self selector:@selector(handleReloadPreferences:) name:@"MA_Notify_PreferenceChange" object:nil];
}

- (void)viewWillAppear {
    [self initializePreferences];
}

#pragma mark - Vienna Preferences

/* handleReloadPreferences
 * This gets called when MA_Notify_PreferencesUpdated is broadcast. Just update the controls values.
 */
-(void)handleReloadPreferences:(NSNotification *)nc
{
    [self initializePreferences];
}

/* initializePreferences
 * Set the preference settings from the user defaults.
 */
-(void)initializePreferences
{
    Preferences * prefs = [Preferences standardPreferences];
    
    // Populate the drop downs with the font names and sizes
    [self selectUserDefaultFont:prefs.articleListFont size:prefs.articleListFontSize control:articleFontSample];

    // Show folder images option
    showFolderImagesButton.state = prefs.showFolderImages ? NSControlStateValueOn : NSControlStateValueOff;
    
    // Set minimum font size option
    enableMinimumFontSize.state = prefs.enableMinimumFontSize ? NSControlStateValueOn : NSControlStateValueOff;
    minimumFontSizes.enabled = prefs.enableMinimumFontSize;
    
    NSUInteger i;
    [minimumFontSizes removeAllItems];
    for (i = 0; i < countOfAvailableMinimumFontSizes; ++i)
        [minimumFontSizes addItemWithObjectValue:@(availableMinimumFontSizes[i])];
    minimumFontSizes.doubleValue = prefs.minimumFontSize;
}

/* changeShowFolderImages
 * Toggle whether or not the folder list shows folder images.
 */
-(IBAction)changeShowFolderImages:(id)sender
{
    BOOL showFolderImages = [sender state] == NSControlStateValueOn;
    [Preferences standardPreferences].showFolderImages = showFolderImages;
}

/* changeMinimumFontSize
 * Enable whether a minimum font size is used for article display.
 */
-(IBAction)changeMinimumFontSize:(id)sender
{
    BOOL useMinimumFontSize = [sender state] == NSControlStateValueOn;
    [Preferences standardPreferences].enableMinimumFontSize = useMinimumFontSize;
    minimumFontSizes.enabled = useMinimumFontSize;
}

/* selectMinimumFontSize
 * Changes the actual minimum font size for article display.
 */
-(IBAction)selectMinimumFontSize:(id)sender
{
    CGFloat newMinimumFontSize = minimumFontSizes.doubleValue;
    [Preferences standardPreferences].minimumFontSize = newMinimumFontSize;
}

/* selectUserDefaultFont
 * Display sample text in the specified font and size.
 */
-(void)selectUserDefaultFont:(NSString *)name size:(NSInteger)size control:(NSTextField *)control
{
    control.font = [NSFont fontWithName:name size:size];
    control.stringValue = [NSString stringWithFormat:@"%@ %li", name, (long)size];
}

/* selectArticleFont
 * Bring up the standard font selector for the article font.
 */
-(IBAction)selectArticleFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFontManager * fontManager = NSFontManager.sharedFontManager;
    fontManager.target = self;
    fontManager.action = @selector(changeArticleFont:);

    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel setPanelFont:[NSFont fontWithName:prefs.articleListFont size:prefs.articleListFontSize] isMultiple:NO];
    [fontPanel orderFront:self];
    fontPanel.enabled = YES;
}

/* changeArticleFont
 * Respond to changes to the article font.
 */
-(IBAction)changeArticleFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:prefs.articleListFont size:prefs.articleListFontSize];
    font = [sender convertFont:font];
    prefs.articleListFont = font.fontName;
    prefs.articleListFontSize = font.pointSize;
    [self selectUserDefaultFont:prefs.articleListFont size:prefs.articleListFontSize control:articleFontSample];
}

/* dealloc
 * Clean up and release resources. 
 */
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
