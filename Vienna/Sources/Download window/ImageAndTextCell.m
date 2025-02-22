//
//  ImageAndTextCell.m
//  Vienna
//
//  Created by Steve on Sat Jan 24 2004.
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

#import "ImageAndTextCell.h"

#import "TreeNode.h"

/* All of this stuff taken from public stuff published
 * by Apple.
 */
@implementation ImageAndTextCell

@synthesize image = image;

/* init
 * Initialise a default instance of our cell.
 */
-(instancetype)init
{
	if ((self = [super init]) != nil)
	{
		image = nil;
		auxiliaryImage = nil;
		offset = 0;
		hasCount = NO;
		count = 0;
        countLabelShadow = [self defaultCountLabelShadow];
		[self setCountBackgroundColour:NSColor.systemGrayColor];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
	cell->image = image;
	cell->auxiliaryImage = auxiliaryImage;
	cell->offset = offset;
	cell->hasCount = hasCount;
	cell->count = count;
	cell->inProgress = inProgress;
	cell->countBackgroundColour = countBackgroundColour;
    cell->countBackgroundColourGradientEnd = countBackgroundColourGradientEnd;
    cell->countLabelShadow = countLabelShadow;
	cell->item = item;

	return cell;
}

/* setOffset
 * Sets the new offset at which the cell contents will be drawn.
 */
-(void)setOffset:(NSInteger)newOffset
{
	offset = newOffset;
}

/* offset
 * Returns the current cell offset in effect.
 */
-(NSInteger)offset
{
	return offset;
}

/* setAuxiliaryImage
 * Sets the auxiliary image to be displayed. Nil removes any existing
 * auxiliary image.
 */
-(void)setAuxiliaryImage:(NSImage *)newAuxiliaryImage
{
	auxiliaryImage = newAuxiliaryImage;
}

/* auxiliaryImage
 * Returns the current auxiliary image.
 */
-(NSImage *)auxiliaryImage
{
	return auxiliaryImage;;
}

/* setCount
 * Sets the value to be displayed in the count button.
 */
-(void)setCount:(NSInteger)newCount
{
	count = newCount;
	hasCount = YES;
}

/* clearCount
 * Removes the count button.
 */
-(void)clearCount
{
	hasCount = NO;
}

/* setCountBackgroundColour
 * Sets the colour used for the count button background.
 */
-(void)setCountBackgroundColour:(NSColor *)newColour
{
	countBackgroundColour = newColour;

    NSColor *newColourRGB = [newColour colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    
    if (newColourRGB)
    {
        countBackgroundColourGradientEnd = [NSColor colorWithHue:newColourRGB.hueComponent
                                                      saturation:newColourRGB.saturationComponent - 0.07
                                                      brightness:newColourRGB.brightnessComponent + 0.07
                                                           alpha:newColourRGB.alphaComponent];
    }
    else
    {
        countBackgroundColourGradientEnd = countBackgroundColour.copy;
    }
}

/* setInProgress
 * Set whether an active progress should be shown for the item. This should be used in a willDisplayCell: style method.
 */
-(void)setInProgress:(BOOL)newInProgress
{
	inProgress = newInProgress;
}

/* setItem
 * Set the item which is being displayed. This should be used in a willDisplayCell: style method.
 */
-(void)setItem:(TreeNode *)newItem
{
	item = newItem;
}

/* drawCellImage
 * Just draw the cell image.
 */
-(void)drawCellImage:(NSRect *)cellFrame inView:(NSView *)controlView
{
	if (image != nil)
	{
		NSSize imageSize;
		NSRect imageFrame;
		
		imageSize = image.size;
		NSDivideRect(*cellFrame, &imageFrame, cellFrame, 3 + imageSize.width, NSMinXEdge);
		imageFrame.origin.x += 3;
		imageFrame.size = imageSize;
		// vertically center
		imageFrame.origin.y += (cellFrame->size.height - imageSize.height) / 2.0;
		
        [image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f respectFlipped:YES hints:NULL];

	}
}

/* drawInteriorWithFrame:inView:
 * Draw the cell complete the image and count button if specified.
 */
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// If the cell has an image, draw the image and then reduce
	// cellFrame to move the text to the right of the image.
	if (image != nil)
		[self drawCellImage:&cellFrame inView:controlView];

	// If we have an error image, it appears on the right hand side.
	if (auxiliaryImage)
	{
		NSSize imageSize;
		NSRect imageFrame;
		
		imageSize = auxiliaryImage.size;
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMaxXEdge);
		imageFrame.size = imageSize;
		// vertically center
		imageFrame.origin.y += (cellFrame.size.height - imageSize.height) / 2.0;
		
        [auxiliaryImage drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f respectFlipped:YES hints:NULL];

	}
	
	// If the cell has a count button, draw the count
	// button on the right of the cell.
	if (hasCount)
	{
		NSString * number = [NSString stringWithFormat:@"%li", (long)count];

		// Use the current font point size as a guide for the count font size
		CGFloat pointSize = self.font.pointSize;

		// Create attributes for drawing the count.
		NSDictionary * attributes = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:pointSize],
			NSForegroundColorAttributeName: [NSColor whiteColor]};
		NSSize numSize = [number sizeWithAttributes:attributes];

		// Compute the dimensions of the count rectangle.
		CGFloat cellWidth = MAX(numSize.width + 6.0, numSize.height + 1.0) + 1.0;

		NSRect countFrame;
		NSDivideRect(cellFrame, &countFrame, &cellFrame, cellWidth, NSMaxXEdge);
        
        // Provide a small amount of additional visual padding beyond the actual
        // count rectangle to ensure the text does not hit the edge of the count bubble
        cellFrame.size.width -= 4.0;

		countFrame.origin.y += 1;
		countFrame.size.height -= 2;

        NSBezierPath *bp = [NSBezierPath bezierPath];
        CGFloat radius = MIN(numSize.height / 2, 0.5f * MIN(NSWidth(countFrame), NSHeight(countFrame)));
        NSRect rect = NSInsetRect(countFrame, radius, radius);
        [bp appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
        [bp appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
        [bp appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
        [bp appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
        [bp closePath];

        NSGradient * countLabelGradient = [[NSGradient alloc] initWithStartingColor:countBackgroundColour endingColor:countBackgroundColourGradientEnd];
        [countLabelGradient drawInBezierPath:bp angle:-90.0];

        // Push new graphics state so we can draw using a shadow if needed
        [NSGraphicsContext saveGraphicsState];
        {
            if (countLabelShadow)
                [countLabelShadow set];
            
            // Draw the count in the rounded rectangle we just created.
            NSPoint point = NSMakePoint(NSMidX(countFrame) - numSize.width / 2.0f,  NSMidY(countFrame) - numSize.height / 2.0f );
            [number drawAtPoint:point withAttributes:attributes];
        }
        [NSGraphicsContext restoreGraphicsState];
	}

	// Draw the text
	cellFrame.origin.x += 2;
	cellFrame.size.height -= 1;
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSString *)accessibilityLabel {
    NSMutableArray *bits = [NSMutableArray arrayWithCapacity:3];

    if (auxiliaryImage && auxiliaryImage.accessibilityDescription) {
        [bits addObject:auxiliaryImage.accessibilityDescription];
    }

    if (hasCount) {
        [bits addObject:[NSString stringWithFormat:NSLocalizedString(@"%d unread articles", nil), (int)count]];
    }

    if (inProgress) {
        [bits addObject:NSLocalizedString(@"Loading", nil)];
    }

    if (bits.count) {
        return [bits componentsJoinedByString:@", "];
    } else {
        return [super accessibilityLabel];
    }
}

-(NSShadow *)defaultCountLabelShadow
{
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.1];
    shadow.shadowBlurRadius = 1.0;
    shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    
    return shadow;
}

@end
