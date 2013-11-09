package net.hxpunk.utils;

import flash.net.SharedObject;

/**
 * Static helper class used for saving and loading data from stored cookies.
 */
class Data 
{
	/**
	 * If you want to share data between different SWFs on the same host, use this id.
	 */
	public static var id:String = "";
	
	/**
	 * Prefix to use for stored object files.
	 */
	public static var prefix:String = "hxpunk";

	/**
	 * Overwrites the current data with the file.
	 * @param	file		The filename to load.
	 */
	public static function load(file:String = ""):Void
	{
		var data:Dynamic = loadData(file);
		_dataMap = new Map<String, Dynamic>();
		for (i in Reflect.fields(data)) _dataMap[i] = Reflect.getProperty(data, i);
	}
	
	/**
	 * Overwrites the file with the current data. The current data will not be saved until this function is called.
	 * @param	file		The filename to save.
	 */
	public static function save(file:String = ""):Void
	{
		if (_shared != null) _shared.clear();
		var data:Dynamic = loadData(file);
		for (i in _dataMap.keys()) Reflect.setProperty(data, i, _dataMap[i]);
		_shared.flush(SIZE);
	}
	
	/**
	 * Reads an int from the current data.
	 * @param	name			Property to read.
	 * @param	defaultValue	Default value.
	 * @return	The property value, or defaultValue if the property is not assigned.
	 */
	public static function readInt(name:String, defaultValue:Int = 0):Int
	{
		return Std.int(read(name, defaultValue));
	}
	
	/**
	 * Reads a uint from the current data.
	 * @param	name			Property to read.
	 * @param	defaultValue	Default value.
	 * @return	The property value, or defaultValue if the property is not assigned.
	 */
	public static function readUInt(name:String, defaultValue:UInt = 0):UInt
	{
		return Std.int(read(name, defaultValue));
	}
	
	/**
	 * Reads a Boolean from the current data.
	 * @param	name			Property to read.
	 * @param	defaultValue	Default value.
	 * @return	The property value, or defaultValue if the property is not assigned.
	 */
	public static function readBool(name:String, defaultValue:Bool = true):Bool
	{
		return read(name, defaultValue);
	}
	
	/**
	 * Reads a String from the current data.
	 * @param	name			Property to read.
	 * @param	defaultValue	Default value.
	 * @return	The property value, or defaultValue if the property is not assigned.
	 */
	public static function readString(name:String, defaultValue:String = ""):String
	{
		return Std.string(read(name, defaultValue));
	}
	
	/**
	 * Writes an int to the current data.
	 * @param	name		Property to write.
	 * @param	value		Value to write.
	 */
	public static function writeInt(name:String, value:Int = 0):Void
	{
		_dataMap.set(name, value);
	}
	
	/**
	 * Writes a uint to the current data.
	 * @param	name		Property to write.
	 * @param	value		Value to write.
	 */
	public static function writeUInt(name:String, value:UInt = 0):Void
	{
		_dataMap.set(name, value);
	}
	
	/**
	 * Writes a Boolean to the current data.
	 * @param	name		Property to write.
	 * @param	value		Value to write.
	 */
	public static function writeBool(name:String, value:Bool = true):Void
	{
		_dataMap.set(name, value);
	}
	
	/**
	 * Writes a String to the current data.
	 * @param	name		Property to write.
	 * @param	value		Value to write.
	 */
	public static function writeString(name:String, value:String = ""):Void
	{
		_dataMap.set(name, value);
	}
	
	/** Reads a property from the data object. */
	public static function read(name:String, defaultValue:Dynamic = null):Dynamic
	{
		if (_dataMap.exists(name)) return _dataMap[name];
		return defaultValue;
	}
	
	/** @private Loads the data file, or return it if you're loading the same one. */
	private static function loadData(file:String = null):Dynamic
	{
		if (file == null || file == "") file = DEFAULT_FILE;
		if (id != "") _shared = SharedObject.getLocal(prefix + "/" + id + "/" + file, "/");
		else _shared = SharedObject.getLocal(prefix + "/" + file);
		return _shared.data;
	}

	/**
	 * Clears the current SharedObject contents (you must save() it for changes to take effect).
	 */
	public static function clear():Void 
	{
		_dataMap = new Map<String, Dynamic>();
	}
	
	/**
	 * Returns a string representation of the contents of the current SharedObject (might not be saved yet).
	 * 
	 * @param showPropertyClass		includes each property's class name to the string.
	 */
	public static function toString(showPropertyClass:Bool = true):String 
	{
		if (_dataMap == null || !_dataMap.keys().hasNext()) return "[]";
		var stringBuf:StringBuf = new StringBuf();
		var value:Dynamic;
		var type:String;
		stringBuf.add("[");
		for (i in _dataMap.keys()) {
			value = _dataMap[i];
			type = (showPropertyClass ? " [" + Type.getClassName(Type.getClass(value)) + "]" : "");
			stringBuf.add("\n  " + i + type + ": " + value);
		}
		stringBuf.add("\n]");
		return stringBuf.toString();
	}
	
	// Data information.
	/** @private */ private static var _shared:SharedObject;
	/** @private */ private static var _dataMap:Map<String, Dynamic>;
	/** @private */ private static var DEFAULT_FILE:String = "_file";
	/** @private */ private static var SIZE:UInt = 10000;
}