/*
 *	 
 *	Temple Library for ActionScript 3.0
 *	Copyright © 2010 MediaMonks B.V.
 *	All rights reserved.
 *	
 *	http://code.google.com/p/templelibrary/
 *	
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are met:
 *	
 *	- Redistributions of source code must retain the above copyright notice,
 *	this list of conditions and the following disclaimer.
 *	
 *	- Redistributions in binary form must reproduce the above copyright notice,
 *	this list of conditions and the following disclaimer in the documentation
 *	and/or other materials provided with the distribution.
 *	
 *	- Neither the name of the Temple Library nor the names of its contributors
 *	may be used to endorse or promote products derived from this software
 *	without specific prior written permission.
 *	
 *	
 *	Temple Library is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU Lesser General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *	
 *	Temple Library is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU Lesser General Public License for more details.
 *	
 *	You should have received a copy of the GNU Lesser General Public License
 *	along with Temple Library.  If not, see <http://www.gnu.org/licenses/>.
 *	
 *	
 *	Note: This license does not apply to 3rd party classes inside the Temple
 *	repository with their own license!
 *	
 */

package temple.data.xml 
{
	import temple.data.collections.HashMap;
	import temple.data.encoding.IDecoder;
	import temple.data.url.URLData;
	import temple.data.url.URLManager;
	import temple.debug.DebugManager;
	import temple.debug.IDebuggable;
	import temple.debug.errors.TempleError;
	import temple.debug.errors.throwError;
	import temple.utils.FrameDelay;
	import temple.utils.types.FunctionUtils;

	import flash.events.Event;
	import flash.net.URLRequestMethod;

	/**
	 * The XMLManager loads XML files and parses them directly to typed data objects.
	 * <p>The XMLManager can use the URLManager for urls, so it's possible to use names instead of urls. The XMLManager automatically detects if the
	 * URLManager has already loaded the urls.xml, and will call 'loadURLs' if it hasn't.</p>
	 * 
	 * <p>By setting the cache options (XMLManager.cacheXML and/or XMLManager.cacheObject) to true you can use the XMLManager as a DataManager,
	 * since it will store loaded XML files and parsed object in cache. When loading and / or parsing a XML file again, it will take the data
	 * from cache. This allows you to call a load method several times, without make it actually reloads the XML's. This will increase performance.</p>
	 * 
	 * @see temple.data.url.URLManager;
	 * 
	 * @example If you want "persons.xml" loaded and parsed to PersonData objects:
	 * 
	 * @includeExample xml/persons.xml
	 * 
	 * @includeExample vo/PersonData.as
	 * 
	 * @includeExample XMLManagerExample.as
	 * 
	 * @author Thijs Broerse
	 */
	public final class XMLManager extends XMLService implements IDebuggable
	{
		/**
		 * Use default cache settings.
		 * @see #cacheXML()
		 * @see #cacheObject()
		 */
		public static const DEFAULT_CACHE_SETTING:int = 0;
		
		/**
		 * Cache XML or Objects
		 */
		public static const CACHE:int = 1;
		
		/**
		 * Do not cache XML or Objects 
		 */
		public static const NO_CACHE:int = 2;

		// Singleton
		private static var _instance:XMLManager;

		// Settings
		private static var _CACHE_XML:Boolean = false;
		private static var _CACHE_OBJECT:Boolean = false;

		/**
		 * Loads a XML and parses the result to a class. When ready the callback function is called with the parsed object as argument.
		 * 
		 * @param url The URL of the XML file
		 * @param objectClass the class which the xml is parses to. 
		 * 		<strong>NOTE:</strong> Class must implement IXMLParsable!
		 * @param node the node in the xml file. Use '.' for nested nodes: "node.node.node"
		 * @param callback the function that needs to be called when loading and parsing is complete. 
		 * 		<strong>NOTE:</strong> the function must accept one (and only one) argument of type objectClass (2nd argument), since the parsed object is returned
		 * @param sendData an object (name - value) to send with the request
		 * 		<strong>NOTE:</strong> sendData is not used by compare previous loads. So always set forceReload to true with a different sendData
		 * @param method Method to send the sendData object (GET of POST)
		 * @param forceReload if set to true the xml file is loaded even when it has been loaded before. If set to false, the xml file won't be loaded again
		 * @param cacheXML indicates if the XML should be keept in memory so won't be loaded again (unless forceReload is not true)
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache XML file</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache XML file</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheXML)</li>
		 * 		</ul>
		 * @param cacheObject indicates if the Object should be keept in memory so won't be parsed again (unless forceReload is not true)
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache object</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache object</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheObject)</li>
		 * 		</ul>
		 * @param decoder an object that decodes the loaded data before parsing. Needed when de XML is encrypted.
		 */
		public static function loadObject(url:String, objectClass:Class, node:String = null, callback:Function = null, sendData:Object = null, method:String = URLRequestMethod.GET, forceReload:Boolean = false, cacheXML:int = XMLManager.DEFAULT_CACHE_SETTING, cacheObject:int = XMLManager.DEFAULT_CACHE_SETTING, decoder:IDecoder = null):XMLLoadItem
		{
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("loadObject: '" + url + "' to " + objectClass + ", callback:" + FunctionUtils.functionToString(callback) + ", sendData:" + sendData + ", method: '" + method + "', forceReload:" + forceReload + ", cacheXML:" + cacheXML + ", cacheObject:" + cacheObject + ", decoder:" + decoder);
			
			return XMLManager.getInstance()._load(XMLObjectData.OBJECT, url, url, objectClass, node, callback, sendData, method, forceReload, cacheXML, cacheObject, decoder);
		}

		/**
		 * Loads a XML and parses the result to a list of objects. When ready the callback function is called with the parsed objects as array argument.
		 * 
		 * @param url The URL of the XML file
		 * @param objectClass the class which the xml is parses to. 
		 * 		<strong>NOTE:</strong> Class must implement IXMLParsable!
		 * @param repeatingNode the repeating node in the xml file. Use '.' for nested nodes: "node.node.node".
		 * @param callback the function that needs to be called when loading and parsing is complete. 
		 * 		<strong>NOTE:</strong> the function must accept one (and only one) argument of type array (2nd argument), since the parsed object is returned
		 * @param sendData an object (name - value) to send with the request.
		 * 		<strong>NOTE:</strong> sendData is not used by compare previous loads. So always set forceReload to true with a different sendData.
		 * @param method Method to send the sendData object (GET of POST)
		 * @param forceReload if set to true the xml file is loaded even when it has been loaded before. If set to false, the xml file won't be loaded again
		 * @param cacheXML indicates if the XML should be keept in memory so won't be loaded again (unless forceReload is not true).
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache XML file.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache XML file.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheXML).</li>
		 * 		</ul>
		 * @param cacheObject indicates if the List should be keept in memory so won't be parsed again (unless forceReload is not true).
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache list.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache list.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheObject).</li>
		 * 		</ul>
		 * @param decoder an object that decodes the loaded data before parsing. Needed when de XML is encrypted.
		 */
		public static function loadList(url:String, objectClass:Class, repeatingNode:String, callback:Function = null, sendData:Object = null, method:String = URLRequestMethod.GET, forceReload:Boolean = false, cacheXML:int = XMLManager.DEFAULT_CACHE_SETTING, cacheList:int = XMLManager.DEFAULT_CACHE_SETTING, decoder:IDecoder = null):XMLLoadItem
		{
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("loadList: '" + url + "' to " + objectClass + ", callback:" + FunctionUtils.functionToString(callback) + ", sendData:" + sendData + ", method: '" + method + "', forceReload:" + forceReload + ", cacheXML:" + cacheXML + ", cacheObject:" + cacheList + ", decoder:" + decoder);
			
			return XMLManager.getInstance()._load(XMLObjectData.LIST, url, url, objectClass, repeatingNode, callback, sendData, method, forceReload, cacheXML, cacheList, decoder);
		}

		/**
		 * Loads a XML and parses the result to a class. When ready the callback function is called with the parsed object as argument.
		 * 
		 * @param name The name as defined in de url.xml by the URLManager
		 * @param objectClass: the class which the xml is parses to. 
		 * 		<strong>NOTE:</strong> Class must implement IXMLParsable!
		 * @param node the node in the xml file. Use '.' for nested nodes: "node.node.node"
		 * @param callback the function that needs to be called when loading and parsing is complete. 
		 * 		<strong>NOTE:</strong> the function must accept one (and only one) argument of type objectClass (2nd argument), since the parsed object is returned
		 * @param sendData an object (name - value) to send with the request
		 * 		<strong>NOTE:</strong> sendData is not used by compare previous loads. So always set forceReload to true with a different sendData
		 * @param method  Method to send the sendData object (GET of POST)
		 * @param forceReload if set to true the xml file is loaded even when it has been loaded before. If set to false, the xml file won't be loaded again
		 * @param cacheXML  indicates if the XML should be keept in memory so won't be loaded again (unless forceReload is not true)
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache XML file.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache XML file.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheXML).</li>
		 * 		</ul>
		 * @param cacheObject indicates if the Object should be keept in memory so won't be parsed again (unless forceReload is not true)
		 * 		<p>Possible values are:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache object.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache object.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheObject).</li>
		 * 		</ul>
		 * @param decoder an object that decodes the loaded data before parsing. Needed when de XML is encrypted.
		 */
		public static function loadObjectByName(name:String, objectClass:Class, node:String = null, callback:Function = null, sendData:Object = null, method:String = URLRequestMethod.GET, forceReload:Boolean = false, cacheXML:int = XMLManager.DEFAULT_CACHE_SETTING, cacheObject:int = XMLManager.DEFAULT_CACHE_SETTING, decoder:IDecoder = null):XMLLoadItem
		{
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("loadObjectByName: '" + name + "' to " + objectClass + ", callback:" + FunctionUtils.functionToString(callback) + ", sendData:" + sendData + ", method: '" + method + "', forceReload:" + forceReload + ", cacheXML:" + cacheXML + ", cacheObject:" + cacheObject + ", decoder:" + decoder);
			
			return XMLManager.getInstance()._load(XMLObjectData.OBJECT, name, null, objectClass, node, callback, sendData, method, forceReload, cacheXML, cacheObject, decoder);
		}

		/**
		 * Loads a XML and parses the result to a list of objects. When ready the callback function is called with the parsed objects as array argument.
		 * 
		 * @param name The name as defined in de url.xml by the URLManager
		 * @param objectClass the class which the xml is parses to. 
		 * 		<strong>NOTE:</strong> Class must implement IXMLParsable!
		 * @param repeatingNode the repeating node in the xml file. Use '.' for nested nodes: "node.node.node"
		 * @param callback the function that needs to be called when loading and parsing is complete. 
		 * 		<strong>NOTE:</strong> the function must accept one (and only one) argument of type array (2nd argument), since the parsed object is returned
		 * @param sendData an object (name - value) to send with the request
		 * 		<strong>NOTE:</strong> sendData is not used by compare previous loads. So always set forceReload to true with a different sendData
		 * @param method Method to send the sendData object (GET of POST)
		 * @param forceReload if set to true the xml file is loaded even when it has been loaded before. If set to false, the xml file won't be loaded again
		 * @param cacheXML indicates if the XML should be keept in memory so won't be loaded again (unless forceReload is not true).
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache XML file.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache XML file.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheXML).</li>
		 * 		</ul>
		 * @param cacheObject indicates if the List should be keept in memory so won't be parsed again (unless forceReload is not true)
		 * 		<p>Possible values:</p>
		 * 		<ul>
		 * 			<li>XMLManager.CACHE = cache list.</li>
		 * 			<li>XMLManager.NO_CACHE = do not cache list.</li>
		 * 			<li>XMLManager.DEFAULT_CACHE_SETTING = use the default setting (can be set using XMLManager.cacheObject).</li>
		 * 		</ul>
		 * @param decoder an object that decodes the loaded data before parsing. Needed when de XML is encrypted.
		 */
		public static function loadListByName(name:String, objectClass:Class, repeatingNode:String, callback:Function = null, sendData:Object = null, method:String = URLRequestMethod.GET, forceReload:Boolean = false, cacheXML:int = XMLManager.DEFAULT_CACHE_SETTING, cacheList:int = XMLManager.DEFAULT_CACHE_SETTING, decoder:IDecoder = null):XMLLoadItem
		{
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("loadListByName: '" + name + "' to " + objectClass + ", callback:" + FunctionUtils.functionToString(callback) + ", sendData:" + sendData + ", method: '" + method + "', forceReload:" + forceReload + ", cacheXML:" + cacheXML + ", cacheObject:" + cacheList + ", decoder:" + decoder);
			
			return XMLManager.getInstance()._load(XMLObjectData.LIST, name, null, objectClass, repeatingNode, callback, sendData, method, forceReload, cacheXML, cacheList, decoder);
		}

		/**
		 * Indicates if cacheXML is enabled. CacheXML keeps the loaded XML file in cache and speeds up the process if this XML is used more once.
		 * This is only the default value and can can be overruled with every load.
		 */
		public static function get cacheXML():Boolean
		{
			return XMLManager._CACHE_XML;
		}

		/**
		 * @private
		 */
		public static function set cacheXML(value:Boolean):void
		{
			XMLManager._CACHE_XML = value;
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("cacheXML: " + XMLManager._CACHE_XML);
		}

		/**
		 * Indicates if cacheObject is enabled. CacheObject keeps the parsed object or list in cache and speeds up the process if this Object is used more once.
		 * This is only the default value and can can be overruled with every load.
		 */
		public static function get cacheObject():Boolean
		{
			return XMLManager._CACHE_OBJECT;
		}

		/**
		 * @private
		 */
		public static function set cacheObject(value:Boolean):void
		{
			XMLManager._CACHE_OBJECT = value;
			if (XMLManager.getInstance().debug) XMLManager.getInstance().logDebug("cacheObject: " + XMLManager._CACHE_OBJECT);
		}
		
		/**
		 * Wrapper function for XMLManager.getInstance().dispatchEvent
		 * 
		 * @see temple.core.CoreEventDispatcher#dispatchEvent
		 */
		public static function dispatchEvent(event:Event):Boolean 
		{
			return XMLManager.getInstance().dispatchEvent(event);
		}

		/**
		 * Wrapper function for XMLManager.getInstance().addEventListener
		 * 
		 * @see temple.core.CoreEventDispatcher#addEventListener
		 */
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void 
		{
			XMLManager.getInstance().addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		/**
		 * Wrapper function for XMLManager.getInstance().removeEventListener
		 * 
		 * @see temple.core.CoreEventDispatcher#removeEventListener
		 */
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void 
		{
			XMLManager.getInstance().removeEventListener(type, listener, useCapture);
		}

		/**
		 * Wrapper function for XMLManager.getInstance().removeAllEventListeners
		 * 
		 * @see temple.core.CoreEventDispatcher#removeAllEventListeners
		 */
		public static function removeAllEventListeners():void 
		{
			XMLManager.getInstance().removeAllEventListeners();
		}
		
		/**
		 * Returns the instance of the XMLManager
		 */
		public static function getInstance():XMLManager 
		{
			if (XMLManager._instance == null) XMLManager._instance = new XMLManager();
			return XMLManager._instance;
		}
		
		// a list of all XMLLoadData objects
		private var _xmlLoadDataList:HashMap;
		private var _dispatchAllCompleteEvent:Boolean;
		private var _delayedAllCompleteEventCall:FrameDelay;

		/**
		 * @private
		 */
		public function XMLManager() 
		{
			super();

			if (_instance) throwError(new TempleError(this, "Singleton, use XMLManager.getInstance() or use static functions"));
			this._xmlLoadDataList = new HashMap("XMLManager xmlLoadDataList");
			
			DebugManager.add(this);
		}

		/**
		 * @private
		 */
		override public function load(urlData:URLData, sendData:Object = null, method:String = URLRequestMethod.GET):void
		{
			throwError(new TempleError(this, "load function is not used in this class!"));
			
			// for warnings
			urlData;
			sendData;
			method;
		}

		/**
		 * @private
		 * 
		 * Data is loaded. If decoder is defined, decode data before parsing
		 */
		override protected function handleLoaderEvent(event:XMLLoaderEvent):void 
		{
			var xmlUrlData:XMLLoadItem = XMLLoadItem(this._xmlLoadDataList[event.name]);
			
			if (event.data && xmlUrlData.decoder)
			{
				if (this.debug) this.logDebug("handleLoaderEvent: data before decoding: " + event.data);
				event.data = XML(xmlUrlData.decoder.decode(event.data));
				if (this.debug) this.logDebug("handleLoaderEvent: data after decoding: " + event.data);
			}
			super.handleLoaderEvent(event);
		}

		/**
		 * @private
		 */
		override protected function processData(data:XML, name:String):void 
		{
			if (this.debug) this.logDebug("processData: '" + name + "' " + data);
			
			var xmlUrlData:XMLLoadItem = XMLLoadItem(this._xmlLoadDataList[name]);
			xmlUrlData._xml = data;
			
			for(var i:int = xmlUrlData.xmlObjectDataList.length - 1;i > -1; --i)
			{
				var xmlObjectData:XMLObjectData = xmlUrlData.xmlObjectDataList[i]; 
				var object:Object = this.getXMLNode(data, xmlObjectData.node, xmlObjectData.type == XMLObjectData.OBJECT ? XML : XMLList);
				
				if (object == null)
				{
					this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.PARSE_ERROR, null, null, null));
					this.logError("processData: node '" + xmlObjectData.node + "' does not exist");
				}
				else
				{
					if (this.debug && xmlObjectData.node != null) this.logDebug("processData: node = '" + xmlObjectData.node + "' ");
					if (this.debug) this.logDebug("processData: object = '" + object + "' ");
					
					var callback:Function;
					
					switch(xmlObjectData.type)
					{
						case XMLObjectData.LIST:
						{
							xmlObjectData.setList(this.parseList(XMLList(object), xmlObjectData.objectClass, name));
							if (this.debug) this.logDebug("processData: Complete");
							this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.COMPLETE, name, xmlObjectData.list, null));
							if (xmlObjectData.callback != null)
							{
								// Do the callback. First empty the callback before calling it!
								callback = xmlObjectData.callback;
								xmlObjectData.callback = null;
								callback.call(null, xmlObjectData.list);
							}
							else if (this.debug) this.logDebug("processData: no callback");
							break;
						}
						case XMLObjectData.OBJECT:
						{
							xmlObjectData.setObject(XMLParser.parseXML(XML(object), xmlObjectData.objectClass, false, this.debug));
							if (xmlObjectData.object == null)
							{
								this.onDataParseError(name);
							}
							else
							{
								if (this.debug) this.logDebug("processData: Complete");
								this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.COMPLETE, name, null, xmlObjectData.object));
								if (xmlObjectData.callback != null)
								{
									// Do the callback. First empty the callback before calling it!
									callback = xmlObjectData.callback;
									xmlObjectData.callback = null;
									callback.call(null, xmlObjectData.object);
								}
								else if (this.debug) this.logDebug("processData: no callback");
							}
							break;
						}	
						default:
						{
							this.logError("processData: unknown XMLData type: '" + xmlObjectData.type + "'");
							break;
						}
					}
					
					if (xmlObjectData.cache == false){
						xmlUrlData.xmlObjectDataList.splice(i, 1);
						if (this.debug) this.logDebug("processData: cache for XMLObjectData disabled, remove XMLObjectData");
					}
				}
			}
			xmlUrlData.setLoaded();
			
			if (xmlUrlData.cache == false)
			{
				delete this._xmlLoadDataList[name];
				if (this.debug) this.logDebug("processData: cache for XMLUrlData disabled, remove XMLUrlData");
			}
		}
		
		/**
		 * @private
		 */
		override protected function handleLoadError(event:XMLLoaderEvent):void 
		{
			super.handleLoadError(event);
			delete this._xmlLoadDataList[event.name];
		}

		private function _load(type:int, name:String, url:String, objectClass:Class, node:String = null, callback:Function = null, sendData:Object = null, method:String = URLRequestMethod.GET, forceReload:Boolean = false, cacheXML:int = DEFAULT_CACHE_SETTING, cacheObject:int = DEFAULT_CACHE_SETTING, decoder:IDecoder = null):XMLLoadItem
		{
			// Check if we have allready loaded this file, and we don't have to reload (if xml of urlData is filled, it's loaded)
			var loadData:XMLLoadItem = this._xmlLoadDataList[name] as XMLLoadItem;
			var xmlObjectData:XMLObjectData;
			
			if (!forceReload && loadData && loadData.xml)
			{
				if (this.debug) this.logDebug("_load: get XML '" + name + "' from cache");
				
				// check if we have allready parsed this xml
				xmlObjectData = loadData.findXMLObjectData(objectClass, node);
				if (!xmlObjectData)
				{
					if (this.debug) this.logDebug("_load: parse data");
					
					// parse data
					xmlObjectData = new XMLObjectData(type, objectClass, node, this.getCacheSetting(cacheObject, XMLManager._CACHE_OBJECT));
					if (xmlObjectData.cache) loadData.addXMLObjectData(xmlObjectData);
				}
				else if (this.debug) this.logDebug("_load: get parsed object from cache");
				
				switch(type)
				{
					case XMLObjectData.OBJECT:
					{
						if (xmlObjectData.object == null)
						{
							var xml:XML = this.getXMLNode(loadData.xml, xmlObjectData.node, XML) as XML;
							if (xml == null)
							{
								this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.PARSE_ERROR, null, null, null));
								this.logError("processData: node '" + xmlObjectData.node + "' does not exist");
							}
							else
							{
								xmlObjectData.setObject(XMLParser.parseXML(xml, objectClass, false, this.debug));
							}
						}
						if (callback != null && xmlObjectData.object) callback(xmlObjectData.object as objectClass);
						break;
					}
					case XMLObjectData.LIST:
					{
						if (xmlObjectData.list == null)
						{
							var xmlList:XMLList = this.getXMLNode(loadData.xml, xmlObjectData.node, XMLList) as XMLList;
							if (xmlList == null)
							{
								this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.PARSE_ERROR, null, null, null));
								this.logError("processData: node '" + xmlObjectData.node + "' does not exists");
							}
							else
							{
								xmlObjectData.setList(XMLParser.parseList(xmlList, objectClass, false, this.debug));
							}
						}
						if (callback != null && xmlObjectData.list) callback(xmlObjectData.list);
						break;
					}
				}
				if (this.debug) this.logDebug("_load: Complete");
				this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.COMPLETE, name, xmlObjectData.list, xmlObjectData.object));
				
				// Wait a frame before dispatching 'all complete' event, maybe there are more loads
				if (!this._dispatchAllCompleteEvent)
				{
					this._dispatchAllCompleteEvent = true;
					this._delayedAllCompleteEventCall = new FrameDelay(this.dispatchAllCompleteEvent);
				}
			}
			else if (!forceReload && loadData)
			{
				// we have this object, but it's not loaded yet. Add to urlData for later parsing
				if (this.debug) this.logDebug("_load: loading current XML started, add to parse queue");
				loadData.addXMLObjectData(new XMLObjectData(type, objectClass, node, this.getCacheSetting(cacheXML, _CACHE_OBJECT), callback));
			}
			else
			{
				// we don't have the object or forceReload is true, so load it.

				if (this._delayedAllCompleteEventCall != null)
				{
					// We have to load stuff, but next frame the 'all complete' event is dispatched. Kill the call
					this._delayedAllCompleteEventCall.destruct();
				}
				
				if (loadData)
				{
					loadData._sendData = sendData;
					loadData._decoder = decoder;
					loadData._isLoaded = false;
					loadData._method = method;
					loadData._cache = this.getCacheSetting(cacheXML, _CACHE_OBJECT);

					xmlObjectData = loadData.findXMLObjectData(objectClass, node);
				}
				
				if (xmlObjectData == null)
				{
					xmlObjectData = new XMLObjectData(type, objectClass, node, this.getCacheSetting(cacheXML, _CACHE_OBJECT), callback);
					
					if (loadData)
					{
						loadData.addXMLObjectData(xmlObjectData);
					}
					else
					{
						loadData = this._xmlLoadDataList[name] = new XMLLoadItem(name, url, xmlObjectData, sendData, method, this.getCacheSetting(cacheXML, _CACHE_XML), decoder);
					}
				}
				else if (callback != null)
				{
					xmlObjectData.callback = callback;
				}
				
				if (url)
				{
					super.load(new URLData(url, url), sendData, method);
				}
				else if (URLManager.isLoaded())
				{
					super.load(URLManager.getURLDataByName(name), sendData, method);
				}
				else
				{
					URLManager.addEventListener(XMLServiceEvent.COMPLETE, handleURLManagerComplete);
					
					if (URLManager.isLoading() == false) URLManager.loadURLs();
				}
			}
			return loadData;
		}

		/**
		 * Finds a node in a XML. Function returns Object since the result can be of type XML of XMLList
		 * @param xml the XML object
		 * @param node the node to find as a String. The find nested noded you can separate the nodes with a dot, like 'node.node.node'
		 * @param returnType XML of XMLList, the return value is of this type
		 */
		private function getXMLNode(xml:XML, node:String, returnType:Class):Object
		{
			if (node == null) return xml;
			var a:Array = node.split(".");
			var n:Object = xml;
			var leni:int = a.length;
			for (var i:int = 0;i < leni; i++) 
			{
				n = n[a[i]];
			}
			
			if (n is XML && XML(n).toXMLString() == "" || n is XMLList && XMLList(n).toXMLString() == "")
			{
				this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.PARSE_ERROR, null, null, null));
				return null;
			}
			
			if (n is returnType) return n;
			
			if (returnType == XML) return n[0];
			
			var list:XMLList = new XMLList(); 
			list[0] = n;
			return list;
		}

		private function handleURLManagerComplete(event:XMLServiceEvent):void
		{
			URLManager.removeEventListener(XMLServiceEvent.COMPLETE, handleURLManagerComplete);
			
			for each (var xmlURLData : XMLLoadItem in this._xmlLoadDataList) 
			{
				if (xmlURLData.url == null && !xmlURLData.xml)
				{
					super.load(URLManager.getURLDataByName(xmlURLData.name), xmlURLData.sendData, xmlURLData.method);
				}
			}
		}
		
		private function dispatchAllCompleteEvent():void
		{
			if (this.debug) this.logDebug("dispatchAllCompleteEvent: ");
			this.dispatchEvent(new XMLServiceEvent(XMLServiceEvent.ALL_COMPLETE));
			this._dispatchAllCompleteEvent = false;
		}
		
		private function getCacheSetting(cacheXML:int, defaultSetting:Boolean):Boolean
		{
			switch(cacheXML){
				case XMLManager.DEFAULT_CACHE_SETTING:
				{
					return defaultSetting;
					break;
				}
				case XMLManager.CACHE:
				{
					return true;
					break;
				}
				case XMLManager.NO_CACHE:
				{
					return true;
					break;
				}
				default:
				{
					throwError(new TempleError(this, "Unknown cache setting."));
					break;
				}
			}
			return true;
		}
		
		/**
		 * Destructs the XMLManager
		 */
		override public function destruct():void
		{
			XMLManager._instance = null;
			this._xmlLoadDataList = null;
			this._delayedAllCompleteEventCall = null;
			
			super.destruct();
		}
	}
}