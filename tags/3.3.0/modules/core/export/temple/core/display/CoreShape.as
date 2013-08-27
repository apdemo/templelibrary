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

package temple.core.display 
{
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Point;
	import temple.core.debug.Registry;
	import temple.core.debug.log.Log;
	import temple.core.debug.log.LogLevel;
	import temple.core.debug.objectToString;
	import temple.core.destruction.DestructEvent;
	import temple.core.events.EventListenerManager;
	import temple.core.templelibrary;


	/**
	 * @eventType temple.core.destruction.DestructEvent.DESTRUCT
	 */
	[Event(name = "DestructEvent.destruct", type = "temple.core.destruction.DestructEvent")]
	
	/**
	 * Base class for all Shapes in the Temple. The CoreShape handles some core features of the Temple:
	 * <ul>
	 * 	<li>Registration to the Registry class.</li>
	 * 	<li>Global reference to the stage trough the StageProvider.</li>
	 * 	<li>Corrects a timeline bug in Flash (see <a href="http://www.tyz.nl/2009/06/23/weird-parent-thing-bug-in-flash/" target="_blank">http://www.tyz.nl/2009/06/23/weird-parent-thing-bug-in-flash/</a>).</li>
	 * 	<li>Event dispatch optimization.</li>
	 * 	<li>Easy remove of all EventListeners.</li>
	 * 	<li>Wrapper for Log class for easy logging.</li>
	 * 	<li>Completely destructible.</li>
	 * 	<li>Tracked in Memory (of this feature is enabled).</li>
	 * 	<li>Some useful extra properties like autoAlpha, position and scale.</li>
	 * </ul>
	 * 
	 * <p>You should always use and/or extend the CoreShape instead of Shape if you want to make use of the Temple features.</p>
	 * 
	 * @see temple.core.Temple#registerObjectsInMemory
	 * 
	 * @includeExample CoreDisplayObjectsExample.as
	 * 
	 * @author Thijs Broerse
	 */
	public class CoreShape extends Shape implements ICoreDisplayObject 
	{
		/**
		 * The current version of the Temple Library
		 */
		templelibrary static const VERSION:String = "3.3.0";
		
		/**
		 * @private
		 * 
		 * Protected namespace for construct method. This makes overriding of constructor possible.
		 */
		protected namespace construct;
		
		private const _toStringProps:Vector.<String> = Vector.<String>(['name']);
		private var _eventListenerManager:EventListenerManager;
		private var _isDestructed:Boolean;
		private var _onStage:Boolean;
		private var _onParent:Boolean;
		private var _registryId:uint;
		private var _destructOnUnload:Boolean = true;
		private var _emptyPropsInToString:Boolean = true;

		public function CoreShape(name:String = null)
		{
			if (name) this.name = name;
			super();
			
			construct::coreShape(name);
		}
		
		/**
		 * @private
		 */
		construct function coreShape(name:String):void
		{
			if (this.loaderInfo) this.loaderInfo.addEventListener(Event.UNLOAD, this.handleUnload, false, 0, true);
			
			this._registryId = Registry.add(this);
			
			// Set listeners to keep track of object is on stage, since we can't trust the .parent property
			super.addEventListener(Event.ADDED, this.handleAdded);
			super.addEventListener(Event.ADDED_TO_STAGE, this.handleAddedToStage);
			super.addEventListener(Event.REMOVED, this.handleRemoved);
			super.addEventListener(Event.REMOVED_FROM_STAGE, this.handleRemovedFromStage);
			
			name;
		}
		
		[Temple]
		/**
		 * @inheritDoc
		 */
		public final function get registryId():uint
		{
			return this._registryId;
		}
		
		/**
		 * Checks for a <code>scrollRect</code> and returns the width of the <code>scrollRect</code>.
		 * Otherwise the <code>super.width</code> is returned. This fixes a FlashPlayer bug; Flash doesn't immediatly
		 * update the objects width when a scrollRect is set on a DisplayObject.
		 */
		override public function get width():Number
		{
			return this.scrollRect ? this.scrollRect.width : super.width;
		}
		
		/**
		 * If the object does not have a width and is not scaled to 0 the object is empty, 
		 * setting the width is useless and can only cause weird errors, so we don't.
		 */
		override public function set width(value:Number):void
		{
			if (super.width || !this.scaleX) super.width = value;
		}
		
		/**
		 * Checks for a <code>scrollRect</code> and returns the height of the <code>scrollRect</code>.
		 * Otherwise the <code>super.height</code> is returned. This fixes a FlashPlayer bug; Flash doesn't immediatly
		 * update the objects height when a scrollRect is set on a DisplayObject.
		 */
		override public function get height():Number
		{
			return this.scrollRect ? this.scrollRect.height : super.height;
		}

		/**
		 * If the object does not have a height and is not scaled to 0 the object is empty, 
		 * setting the height is useless and can only cause weird errors, so we don't. 
		 */
		override public function set height(value:Number):void
		{
			if (super.height || !this.scaleY) super.height = value;
		}
		
		/**
		 * When object is not on the stage it gets the stage reference from the StageProvider. So therefore this object
		 * will always has a reference to the stage.
		 */
		override public function get stage():Stage
		{
			return super.stage || StageProvider.stage;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get onStage():Boolean
		{
			return this._onStage;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get hasParent():Boolean
		{
			return this._onParent;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeFromParent():void
		{
			if (this.parent && this._onParent) this.parent.removeChild(this);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get autoAlpha():Number
		{
			return this.visible ? this.alpha : 0;
		}

		/**
		 * @inheritDoc
		 */
		public function set autoAlpha(value:Number):void
		{
			this.alpha = value;
			this.visible = this.alpha > 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get position():Point
		{
			return new Point(this.x, this.y);
		}
		
		/**
		 * @inheritDoc
		 */
		public function set position(value:Point):void
		{
			this.x = value.x;
			this.y = value.y;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get scale():Number
		{
			return this.scaleX == this.scaleY ? this.scaleX : NaN;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set scale(value:Number):void
		{
			this.scaleX = this.scaleY = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get destructOnUnload():Boolean
		{
			return this._destructOnUnload;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set destructOnUnload(value:Boolean):void
		{
			this._destructOnUnload = value;
		}
		
		/**
		 * @inheritDoc
		 * 
		 * Checks if this object has event listeners of this event before dispatching the event. Should speed up the
		 * application.
		 */
		override public function dispatchEvent(event:Event):Boolean 
		{
			if (this.hasEventListener(event.type) || event.bubbles) 
			{
				return super.dispatchEvent(event);
			}
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void 
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			if (this.getEventListenerManager()) this._eventListenerManager.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * @inheritDoc
		 */
		public function addEventListenerOnce(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0):void
		{
			if (this.getEventListenerManager()) this._eventListenerManager.addEventListenerOnce(type, listener, useCapture, priority);
		}

		/**
		 * @inheritDoc
		 */
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void 
		{
			super.removeEventListener(type, listener, useCapture);
			if (this._eventListenerManager) this._eventListenerManager.removeEventListener(type, listener, useCapture);
		}

		/**
		 * @inheritDoc
		 */
		public function removeAllStrongEventListenersForType(type:String):void 
		{
			if (this._eventListenerManager) this._eventListenerManager.removeAllStrongEventListenersForType(type);
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeAllOnceEventListenersForType(type:String):void
		{
			if (this._eventListenerManager) this._eventListenerManager.removeAllOnceEventListenersForType(type);
		}

		/**
		 * @inheritDoc
		 */
		public function removeAllStrongEventListenersForListener(listener:Function):void 
		{
			if (this._eventListenerManager) this._eventListenerManager.removeAllStrongEventListenersForListener(listener);
		}

		/**
		 * @inheritDoc
		 */
		public function removeAllEventListeners():void 
		{
			if (this._eventListenerManager) this._eventListenerManager.removeAllEventListeners();
		}
		
		
		[Temple]
		/**
		 * @inheritDoc
		 */
		public function get eventListenerManager():EventListenerManager
		{
			return this._eventListenerManager;
		}
		
		private function getEventListenerManager():EventListenerManager
		{
			if (this._isDestructed)
			{
				this.logError("Object is destructed, don't add event listeners");
				return null;
			}
			return this._eventListenerManager ||= new EventListenerManager(this);
		}
		
		/**
		 * Does a Log.debug, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#debug()
		 * @see temple.core.debug.log.LogLevel#DEBUG
		 */
		protected final function logDebug(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.DEBUG, this._registryId);
		}
		
		/**
		 * Does a Log.error, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#error()
		 * @see temple.core.debug.log.LogLevel#ERROR
		 */
		protected final function logError(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.ERROR, this._registryId);
		}
		
		/**
		 * Does a Log.fatal, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#fatal()
		 * @see temple.core.debug.log.LogLevel#FATAL
		 */
		protected final function logFatal(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.FATAL, this._registryId);
		}
		
		/**
		 * Does a Log.info, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#info()
		 * @see temple.core.debug.log.LogLevel#INFO
		 */
		protected final function logInfo(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.INFO, this._registryId);
		}
		
		/**
		 * Does a Log.status, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#status()
		 * @see temple.core.debug.log.LogLevel#STATUS
		 */
		protected final function logStatus(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.STATUS, this._registryId);
		}
		
		/**
		 * Does a Log.warn, but has already filled in some known data.
		 * @param data the data to be logged
		 * 
		 * @see temple.core.debug.log.Log#warn()
		 * @see temple.core.debug.log.LogLevel#WARN
		 */
		protected final function logWarn(data:*):void
		{
			Log.templelibrary::send(data, this.toString(), LogLevel.WARN, this._registryId);
		}

		private function handleUnload(event:Event):void
		{
			if (this._destructOnUnload) this.destruct();
		}
		
		private function handleAdded(event:Event):void
		{
			if (event.currentTarget == this) this._onParent = true;
		}

		private function handleAddedToStage(event:Event):void
		{
			this._onStage = true;
			StageProvider.stage ||= super.stage;
		}

		private function handleRemoved(event:Event):void
		{
			if (event.target == this)
			{
				this._onParent = false;
				if (!this._isDestructed) super.addEventListener(Event.ENTER_FRAME, this.handleDestructedFrameDelay);
			}
		}
		
		private function handleDestructedFrameDelay(event:Event):void
		{
			super.removeEventListener(Event.ENTER_FRAME, this.handleDestructedFrameDelay);
			this.checkParent();
		}

		/**
		 * Check objects parent, after being removed. If the object still has a parent, the object has been removed by a timeline animation.
		 * If an object is removed by a timeline animation, the object is not used anymore and can be destructed
		 */
		private function checkParent():void
		{
			if (this.parent && !this._onParent) this.destruct();
		}

		private function handleRemovedFromStage(event:Event):void
		{
			this._onStage = false;
		}		
		
		/**
		 * List of property names which are output in the toString() method.
		 */
		protected final function get toStringProps():Vector.<String>
		{
			return this._toStringProps;
		}
		
		/**
		 * @private
		 *
		 * Possibility to modify the toStringProps array from outside, using the templelibrary namespace.
		 */
		templelibrary final function get toStringProps():Vector.<String>
		{
			return this._toStringProps;
		}
		
		/**
		 * A Boolean which indicates if empty properties are output in the toString() method.
		 */
		protected final function get emptyPropsInToString():Boolean
		{
			return this._emptyPropsInToString;
		}

		/**
		 * @private
		 */
		protected final function set emptyPropsInToString(value:Boolean):void
		{
			this._emptyPropsInToString = value;
		}

		/**
		 * @private
		 * 
		 * Possibility to modify the emptyPropsInToString value from outside, using the templelibrary namespace.
		 */
		templelibrary final function get emptyPropsInToString():Boolean
		{
			return this._emptyPropsInToString;
		}
		
		/**
		 * @private
		 */
		templelibrary final function set emptyPropsInToString(value:Boolean):void
		{
			this._emptyPropsInToString = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function toString():String
		{
			return objectToString(this, this.toStringProps, !this.emptyPropsInToString);
		}
		
		[Temple]
		/**
		 * @inheritDoc
		 */
		public final function get isDestructed():Boolean
		{
			return this._isDestructed;
		}

		/**
		 * @inheritDoc
		 */
		public function destruct():void 
		{
			if (this._isDestructed) return;
			
			this.dispatchEvent(new DestructEvent(DestructEvent.DESTRUCT));
			
			// clear mask, so it won't keep a reference to an other object
			this.mask = null;
			
			if (this.loaderInfo) this.loaderInfo.removeEventListener(Event.UNLOAD, this.handleUnload);
			
			this.removeEventListener(Event.ENTER_FRAME, this.handleDestructedFrameDelay);
			
			if (this._eventListenerManager)
			{
				this._eventListenerManager.destruct();
				this._eventListenerManager = null;
			}
			
			super.removeEventListener(Event.ENTER_FRAME, this.handleDestructedFrameDelay);
			super.removeEventListener(Event.ADDED, this.handleAdded);
			super.removeEventListener(Event.ADDED_TO_STAGE, this.handleAddedToStage);
			super.removeEventListener(Event.REMOVED, this.handleRemoved);
			super.removeEventListener(Event.REMOVED_FROM_STAGE, this.handleRemovedFromStage);
			
			if (this.parent)
			{
				if (this.parent is Loader)
				{
					Loader(this.parent).unload();
				}
				else
				{
					if (this._onParent)
					{
						if (this.name && this.parent.hasOwnProperty(this.name)) this.parent[this.name] = null;
						this.parent.removeChild(this);
					}
					else
					{
						// something weird happened, since we have a parent but didn't receive an ADDED event. So do the try-catch thing
						try
						{
							if (this.name && this.parent.hasOwnProperty(this.name)) this.parent[this.name] = null;
							this.parent.removeChild(this);
						}
						catch (e:Error){}
					}
				}
			}
			this._isDestructed = true;
		}
	}
}