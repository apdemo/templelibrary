/*
 *	Temple Library for ActionScript 3.0
 *	Copyright © MediaMonks B.V.
 *	All rights reserved.
 *	
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are met:
 *	1. Redistributions of source code must retain the above copyright
 *	   notice, this list of conditions and the following disclaimer.
 *	2. Redistributions in binary form must reproduce the above copyright
 *	   notice, this list of conditions and the following disclaimer in the
 *	   documentation and/or other materials provided with the distribution.
 *	3. All advertising materials mentioning features or use of this software
 *	   must display the following acknowledgement:
 *	   This product includes software developed by MediaMonks B.V.
 *	4. Neither the name of MediaMonks B.V. nor the
 *	   names of its contributors may be used to endorse or promote products
 *	   derived from this software without specific prior written permission.
 *	
 *	THIS SOFTWARE IS PROVIDED BY MEDIAMONKS B.V. ''AS IS'' AND ANY
 *	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *	DISCLAIMED. IN NO EVENT SHALL MEDIAMONKS B.V. BE LIABLE FOR ANY
 *	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 *	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *	
 *	
 *	Note: This license does not apply to 3rd party classes inside the Temple
 *	repository with their own license!
 */


/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
 */
package temple.utils.types
{
	import temple.common.enum.Align;
	import temple.core.debug.objectToString;

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Utility functions for use with DisplayObjects.
	 * 
	 * @author Josh Tynjala, Thijs Broerse
	 */
	public final class DisplayObjectUtils
	{
		/**
		 * Converts a point from the local coordinate system of one DisplayObject to
		 * the local coordinate system of another DisplayObject.
		 *
		 * @param point the point to convert
		 * @param firstDisplayObject the original coordinate system
		 * @param secondDisplayObject the new coordinate system
		 */
		public static function localToLocal(point:Point, firstDisplayObject:DisplayObject, secondDisplayObject:DisplayObject):Point
		{
			point = firstDisplayObject.localToGlobal(point);
			return secondDisplayObject.globalToLocal(point);
		}

		/**
		 * Aligns a DisplayObject vertically and horizontally within specific bounds.
		 * 
		 * @param target The DisplayObject to align.
		 * @param bounds The rectangle in which to align the target DisplayObject.
		 * @param horizontalAlign The alignment position along the horizontal axis. If null, the target's horizontal position will not change.
		 * @param verticalAlign The alignment position along the vertical axis. If null, the target's vertical position will not change.
		 */
		public static function align(target:DisplayObject, bounds:Rectangle, horizontalAlign:String = null, verticalAlign:String = null):void
		{	
			var horizontalDifference:Number = bounds.width - target.width;
			switch (horizontalAlign)
			{
				case Align.LEFT:
				{
					target.x = bounds.x;
					break;
				}
				case Align.CENTER:
				{
					target.x = bounds.x + horizontalDifference * .5;
					break;
				}
				case Align.RIGHT:
				{
					target.x = bounds.x + horizontalDifference;
					break;
				}
			}
					
			var verticalDifference:Number = bounds.height - target.height;
			switch (verticalAlign)
			{
				case Align.TOP:
				{
					target.y = bounds.y;
					break;
				}
				case Align.MIDDLE:
				{
					target.y = bounds.y + verticalDifference * .5;
					break;
				}
				case Align.BOTTOM:
				{
					target.y = bounds.y + verticalDifference;
					break;
				}
			}
		}

		/**
		 * Resizes a DisplayObject to fit into specified bounds such that the
		 * aspect ratio of the target's width and height does not change.
		 * 
		 * @param target The DisplayObject to resize.
		 * @param width The desired width for the target.
		 * @param height The desired height for the target.
		 * @param aspectRatio The desired aspect ratio. If NaN, the aspect ratio is calculated from the target's current width and height.
		 */
		public static function resizeAndMaintainAspectRatio(target:DisplayObject, width:Number, height:Number, aspectRatio:Number = NaN):void
		{
			var currentAspectRatio:Number = !isNaN(aspectRatio) ? aspectRatio : target.width / target.height;
			var boundsAspectRatio:Number = width / height;
			
			if (currentAspectRatio < boundsAspectRatio)
			{
				target.width = Math.floor(height * currentAspectRatio);
				target.height = height;
			}
			else
			{
				target.width = width;
				target.height = Math.floor(width / currentAspectRatio);
			}
		}

		/**
		 * Centers a DisplayObject to the stage. 
		 * @param displayObject DisplayObject to center
		 * @param offsetX (optional) x offset
		 * @param offsetY (optional) y offset
		 * @param shouldCenter (optional) whether the object should be centered itself, assuming a origin at the upper left; when set to true, the position of the object is moved left and up by half its width and height
		 * @example
		 * This example centers the DisplayObject on the stage, with an offset of 50 and 0:
		 * <listing version="3.0">
		 * DisplayObjectUtils.centerOnStage(my_mc, false, 50, 0);
		 * </listing>
		 */
		public static function centerOnStage(displayObject:DisplayObject, offsetX:Number = Number.NaN, offsetY:Number = Number.NaN, shouldCenter:Boolean = false):void 
		{
			var x:Number = displayObject.stage.stageWidth / 2;
			var y:Number = displayObject.stage.stageHeight / 2;
			if (!(isNaN(offsetX))) x += offsetX;
			if (!(isNaN(offsetY))) y += offsetY;
			if (shouldCenter) 
			{
				x -= (displayObject.width / 2);
				y -= (displayObject.height / 2);
			}
			displayObject.x = x;
			displayObject.y = y;
		}

		/**
		 * Returns the distance from the registration point of the specified object to the right-most visible pixel, ignoring any region
		 * that is not visible due to masking. For example, if a display object contains a 100-pixel-wide shape and a 50-pixel-wide mask,
		 * getVisibleWidth() will return 50, whereas DisplayObject's "width" variable would yield 100. 
		 * 
		 * The maximum measureable dimensions of the supplied object is 2000x2000.
		 * 
		 * From: http://www.moock.org/blog/archives/000292.html
		 */
		public static function getVisibleWidth(displayObject:DisplayObject):Number 
		{
			var bitmapDataSize:int = 2000;
			var bounds:Rectangle;
			var bitmapData:BitmapData = new BitmapData(bitmapDataSize, bitmapDataSize, true, 0);
			bitmapData.draw(displayObject);
			bitmapData.threshold(bitmapData, new Rectangle(0, 0, bitmapDataSize, bitmapDataSize), new Point(0, 0), ">=", 0x80000000, 0xFF000000, 0xFF000000);
			bounds = bitmapData.getColorBoundsRect(0xFF000000, 0xFF000000);
			bitmapData.dispose(); 
			return bounds.x + bounds.width;
		}

		/**
		 * Returns the distance from the registration point of the specified object to the bottom-most visible pixel, ignoring any region
		 * that is not visible due to masking. For example, if a display object contains a 100-pixel-high shape and a 50-pixel-high mask,
		 * getVisibleHeight() will return 50, whereas DisplayObject's "height" variable would yield 100. 
		 * 
		 * The maximum measureable dimensions of the supplied object is 2000x2000.
		 * 
		 * From: http://www.moock.org/blog/archives/000292.html
		 */
		public static function getVisibleHeight(displayObject:DisplayObject):Number 
		{
			var bitmapDataSize:int = 2000;
			var bounds:Rectangle;
			var bitmapData:BitmapData = new BitmapData(bitmapDataSize, bitmapDataSize, true, 0);
			bitmapData.draw(displayObject);
			bitmapData.threshold(bitmapData, new Rectangle(0, 0, bitmapDataSize, bitmapDataSize), new Point(0, 0), ">=", 0x80000000, 0xFF000000, 0xFF000000);
			bounds = bitmapData.getColorBoundsRect(0xFF000000, 0xFF000000);
			bitmapData.dispose(); 
			return bounds.y + bounds.height;
		}
		
		/**
		 * getBounds with added visible/alpha0/mask check, recursive on DisplayObjectContainer, but DisplayObject for power (add treshhold-for-bitmaps-option?)
		 */
		public static function getVisibleBounds(target:DisplayObject, space:DisplayObject = null, recurse:int = 0):Rectangle
		{
			space = space ? space : target;

			if(target is DisplayObjectContainer)
			{
				var i:int;
				var rect:Rectangle;
				var container:DisplayObjectContainer = DisplayObjectContainer(target);
				var disp:DisplayObject;
				if (recurse > 0)
				{
					for(i = 0;i < container.numChildren;i++)
					{
						disp = container.getChildAt(i);
						if(disp.mask)
						{
							disp = disp.mask;
						}
						if(disp.visible && disp.alpha > 0)
						{
							if(rect)
							{
								rect = rect.union(DisplayObjectUtils.getVisibleBounds(disp, space, recurse - 1));
							}
							else
							{
								rect = DisplayObjectUtils.getVisibleBounds(disp, space, recurse - 1);
							}
						}
					}
				}
				else
				{
					for(i = 0;i < container.numChildren;i++)
					{
						disp = container.getChildAt(i);
						if(disp.mask)
						{
							disp = disp.mask;
						}
						if(disp.visible && disp.alpha > 0)
						{
							if(rect)
							{
								rect = rect.union(disp.getBounds(space));
							}
							else
							{
								rect = disp.getBounds(space);
							}
						}
					}
				}
				if(rect)
				{
					return rect;
				}
			}
			// fallback
			return target.getBounds(space);
		}
		

		/**
		 * Clears all the content of a displayObject. Removes all children and clears graphic.
		 * Note: this method doesn't destruct the children.
		 */
		public static function clearContent(displayObject:DisplayObject):void
		{
			if (displayObject is DisplayObjectContainer)
			{
				while ((displayObject as DisplayObjectContainer).numChildren > 0)
				{
					(displayObject as DisplayObjectContainer).removeChildAt(0);
				}
			}
			if (displayObject is Sprite)
			{
				(displayObject as Sprite).graphics.clear();
			}
			else if (displayObject is Shape)
			{
				(displayObject as Shape).graphics.clear();
			}
		}

		/**
		 * Checks if a display object is the application root.
		 * Application root means that the display object is a document class and the SWF file is not loaded inside an other SWF, but runs standalone.
		 */
		public static function isApplicationRoot(displayObject:DisplayObject):Boolean 
		{
			return displayObject.stage && displayObject.stage == displayObject.parent;
		}
		
		/**
		 * Convert the Transform Matrix of the source to the target manipulated by their parents Transform Matrices.
		 * So the position, scale and rotation of the returned Matrix will be exactly the same as the source, when used in the target.
		 * @param source the source DisplayObject to get the Transform Matrix from.
		 * @param target the target DisplayObject to apply the Matrix to.
		 */
		public static function convertTransformMatrix(source:DisplayObject, target:DisplayObject):Matrix
		{
			if (!source || !source.transform || !source.parent || !target) return null;
			
			var sourceConcatenatedMatrix:Matrix = source.transform.concatenatedMatrix;
			var targetConcatenatedMatrix:Matrix = target.transform.concatenatedMatrix;
			var targetMatrix:Matrix = target.transform.matrix;
			
			targetConcatenatedMatrix.invert();
			
			sourceConcatenatedMatrix.concat(targetConcatenatedMatrix);
			
			targetMatrix.concat(sourceConcatenatedMatrix);
			
			return targetMatrix;
		}
		
		/**
		 * Applies the Transform Matrix of the source on the target manipulated by their parents Transform Matrices.
		 * So the position, scale and rotation of the target will look exactly the same as the source.
		 * @param source the source DisplayObject to get the Transform Matrix from.
		 * @param target the target DisplayObject to apply the Matrix to.
		 */
		public static function mimicTransformMatrix(source:DisplayObject, target:DisplayObject):void
		{
			target.transform.matrix = DisplayObjectUtils.convertTransformMatrix(source, target);
		}

		/**
		 * Moves an Object to a new parent, but keeps the same (visible) scaling, rotation and position
		 */
		public static function reparent(displayObject:DisplayObject, newParent:DisplayObjectContainer):void
		{
			if (!displayObject || !displayObject.transform) return;
			displayObject.transform.matrix = DisplayObjectUtils.convertTransformMatrix(displayObject, newParent);
			newParent.addChild(displayObject);
		}

		/**
		 * Moves an Object to a new parent, but keeps the same (visible) scaling, rotation and position
		 */
		public static function reparentAt(displayObject:DisplayObject, newParent:DisplayObjectContainer, index:int):void
		{
			if (!displayObject || !displayObject.transform) return;
			displayObject.transform.matrix = DisplayObjectUtils.convertTransformMatrix(displayObject, newParent);
			newParent.addChildAt(displayObject, index);
		}
		
		/**
		 * Gets the absolute scaleX (his scaleX multiplied the scaleX of all his parents)
		 */
		public static function getAbsoluteScaleX(displayObject:DisplayObject):Number
		{
			var scaleX:Number = displayObject.scaleX;
			displayObject = displayObject.parent;
			while (displayObject)
			{
				scaleX *= displayObject.scaleX;
				displayObject = displayObject.parent;
			}
			return scaleX;
		}

		/**
		 * Gets the absolute scaleY (his scaleY multiplied the scaleY of all his parents)
		 */
		public static function getAbsoluteScaleY(displayObject:DisplayObject):Number
		{
			var scaleY:Number = displayObject.scaleY;
			displayObject = displayObject.parent;
			while (displayObject)
			{
				scaleY *= displayObject.scaleY;
				displayObject = displayObject.parent;
			}
			return scaleY;
		}

		/**
		 * Searches in the parent tree for a parent with a specific name and returns this parent
		 */
		public static function getAncestorByName(displayObject:DisplayObject, name:String):DisplayObjectContainer
		{
			var parent:DisplayObjectContainer = displayObject.parent;
			
			while (parent)
			{
				if (parent.name == name) return parent;
				parent = parent.parent;
			}
			return null;
		}

		/**
		 * Checks if the displayObject can be seen on a specific point on the stage.
		 */
		public static function isAbsoluteVisible(displayObject:DisplayObject, offset:Point = null):Boolean
		{
			if (displayObject.stage)
			{
				var objects:Array = displayObject.stage.getObjectsUnderPoint(displayObject.localToGlobal(offset || new Point(displayObject.width * .5, displayObject.height * .5)));
				
				if (objects.length)
				{
					var object:DisplayObject = objects[objects.length - 1];
					if (object == displayObject)
					{
						return true;
					}
					else if (displayObject is DisplayObjectContainer)
					{
						return DisplayObjectContainer(displayObject).contains(object);
					}
				}
			}
			return false;
		}

		/**
		 * @private
		 */
		public static function toString():String
		{
			return objectToString(DisplayObjectUtils);
		}
	}
}