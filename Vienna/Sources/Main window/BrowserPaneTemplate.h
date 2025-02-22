//
//  BrowserPaneTemplate.h
//  Vienna
//
//  Created by Steve on 3/5/06.
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
// 

@import Cocoa;

#import "BrowserPane.h"

@interface BrowserPaneTemplate : NSWindowController {
	IBOutlet BrowserPane * browserPane;
}

@property NSArray * topObjects;

@property (nonatomic, readonly) BrowserPane *mainView;
@end
