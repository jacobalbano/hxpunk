package net.hxpunk.utils;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import net.hxpunk.HP;


/**
 * Static class updated by Engine. Use for defining and checking keyboard/mouse input.
 */
class Input
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * An updated string containing the last 100 characters pressed on the keyboard.
	 * Useful for creating text input fields, such as highscore entries, etc.
	 */
	public static var keyString:String = "";
	
	/**
	 * The last key pressed.
	 */
	public static var lastKey:Int = 0;
	
	/**
	 * The mouse cursor. Set to "hide" to hide the cursor. See the flash.ui.MouseCursor class for a list of all other possible values. Common values: "auto" or "button".
	 */
	public static var mouseCursor:String = "auto";
	
	/**
	 * If the mouse button is down.
	 */
	public static var mouseDown:Bool = false;
	
	/**
	 * If the mouse button is up.
	 */
	public static var mouseUp:Bool = true;
	
	/**
	 * If the mouse button was pressed this frame.
	 */
	public static var mousePressed:Bool = false;
	
	/**
	 * If the mouse button was released this frame.
	 */
	public static var mouseReleased:Bool = false;
	
	/**
	 * If the mouse wheel was moved this frame.
	 */
	public static var mouseWheel:Bool = false; 
	
	
	public static inline function initStaticVars():Bool 
	{
		_key = new Array<Bool>();
		_press = new Array<Int>();
		_release = new Array<Int>();
		
		for (i in 0...256) {
			_key.push(false);
			_press.push(0);
			_release.push(0);
		}
		_control = new Map < String, Array<Int> > ();
	
		return true;
	}
	
	/**
	 * If the mouse wheel was moved this frame, this was the delta.
	 */
	public static var mouseWheelDelta(get, null):Int;
	private static inline function get_mouseWheelDelta()
	{
		if (mouseWheel)
		{
			mouseWheel = false;
			return _mouseWheelDelta;
		}
		return 0;
	}  
	
	/**
	 * X position of the mouse on the screen.
	 */
	public static var mouseX(get, null):Int;
	private static inline function get_mouseX()
	{
		return HP.screen.mouseX;
	}
	
	/**
	 * Y position of the mouse on the screen.
	 */
	public static var mouseY(get, null):Int;
	private static inline function get_mouseY()
	{
		return HP.screen.mouseY;
	}
	
	/**
	 * The absolute mouse x position on the screen (unscaled).
	 */
	public static var mouseFlashX(get, null):Int;
	private static inline function get_mouseFlashX():Int
	{
		return Std.int(HP.stage.mouseX);
	}
	
	/**
	 * The absolute mouse y position on the screen (unscaled).
	 */
	public static var mouseFlashY(get, null):Int;
	private static inline function get_mouseFlashY():Int
	{
		return Std.int(HP.stage.mouseY);
	}
	
	/**
	 * Defines a new input.
	 * @param	name		String to map the input to.
	 * @param	keys		The keys to use for the Input.
	 */
	public static function define(name:String, keys:Array<Int>):Void
	{
		_control[name] = keys;
	}
	
	/**
	 * If the input or key is held down.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function check(input:Dynamic):Bool
	{
		if (Std.is(input, String))
		{
			var strInput:String = cast(input, String);
			if (_control[strInput] == null || _control[strInput].length == 0) return false;
			var v:Array<Int> = _control[strInput],
				i:Int = v.length;
			while (i -- > 0)
			{
				if (v[i] < 0)
				{
					if (_keyNum > 0) return true;
					continue;
				}
				if (_key[v[i]]) return true;
			}
			return false;
		}
		return input < 0 ? _keyNum > 0 : _key[input];
	}
	
	/**
	 * If the input or key was pressed this frame.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function pressed(input:Dynamic):Bool
	{
		if (Std.is(input, String))
		{
			var strInput:String = cast(input, String);
			if (_control[strInput] == null || _control[strInput].length == 0) return false;
			var v:Array<Int> = _control[strInput],
				i:Int = v.length;
			while (i -- > 0)
			{
				if ((v[i] < 0) ? _pressNum > 0 : Lambda.indexOf(_press, v[i]) >= 0) return true;
			}
			return false;
		}
		return (input < 0) ? (_pressNum > 0): Lambda.indexOf(_press, input) >= 0;
	}
	
	/**
	 * If the input or key was released this frame.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function released(input:Dynamic):Bool
	{
		if (Std.is(input, String))
		{
			var strInput:String = cast(input, String);
			if (_control[strInput] == null || _control[strInput].length == 0) return false;
			var v:Array<Int> = _control[strInput],
				i:Int = v.length;
			while (i -- > 0)
			{
				if ((v[i] < 0) ? _releaseNum > 0 : Lambda.indexOf(_release, v[i]) >= 0) return true;
			}
			return false;
		}
		return (input < 0) ? (_releaseNum > 0) : Lambda.indexOf(_release, input) >= 0;
	}
	
	/**
	 * Returns the keys mapped to the input name.
	 * @param	name		The input name.
	 * @return	A Vector of keys.
	 */
	public static function keys(name:String):Array<Int>
	{
		return _control[name];
	}
	
	/** @private Called by Engine to enable keyboard input on the stage. */
	public static function enable():Void
	{
		if (!_enabled && HP.stage != null)
		{
			HP.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			HP.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			HP.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			HP.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			HP.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			HP.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_enabled = true;
		}
	}
	
	/** @private Called by Engine to update the input. */
	public static function update():Void
	{
		while (_pressNum -- > 0) _press[_pressNum] = -1;
		_pressNum = 0;
		while (_releaseNum -- > 0) _release[_releaseNum] = -1;
		_releaseNum = 0;
		if (mousePressed) mousePressed = false;
		if (mouseReleased) mouseReleased = false;
		
		if (mouseCursor == null || mouseCursor == "") {
			if (mouseCursor == "hide") {
				if (_mouseVisible) Mouse.hide();
				_mouseVisible = false;
			} else {
				if (! _mouseVisible) Mouse.show();
			#if flash
				if (Mouse.cursor != mouseCursor) Mouse.cursor = mouseCursor;
			#end
				_mouseVisible = true;
			}
		}
	}
	
	/**
	 * Clears all input states.
	 */
	public static function clear():Void
	{
		HP.removeAll(_press);
		HP.removeAll(_release);
		
		_pressNum = 0;
		_releaseNum = 0;
		var i:Int = _key.length;
		while (i -- > 0) _key[i] = false;
		_keyNum = 0;
	}
	
	/** @private Event handler for key press. */
	private static function onKeyDown(e:KeyboardEvent = null):Void
	{
		// get the keycode
		var code:Int = lastKey = e.keyCode;
		
		// update the keystring
		if (code == Key.BACKSPACE) keyString = keyString.substring(0, keyString.length - 1);
		else if (e.charCode > 31 && e.charCode != 127) // 127 is delete
		{
			if (keyString.length > KEYSTRING_MAX) keyString = keyString.substring(1);
			keyString += String.fromCharCode(e.charCode);
		}
		
		if (code < 0 || code > 255) return;
		
		// update the keystate
		if (!_key[code])
		{
			_key[code] = true;
			_keyNum ++;
			_press[_pressNum ++] = code;
		}
	}
	
	/** @private Event handler for key release. */
	private static function onKeyUp(e:KeyboardEvent):Void
	{
		// get the keycode and update the keystate
		var code:Int = e.keyCode;
		
		if (code < 0 || code > 255) return;
		
		if (_key[code])
		{
			_key[code] = false;
			_keyNum --;
			_release[_releaseNum ++] = code;
		}
	}
	
	/** @private Event handler for mouse press. */
	private static function onMouseDown(e:MouseEvent):Void
	{
		if (!mouseDown)
		{
			mouseDown = true;
			mouseUp = false;
			mousePressed = true;
		}
	}
	
	/** @private Event handler for mouse release. */
	private static function onMouseUp(e:MouseEvent):Void
	{
		mouseDown = false;
		mouseUp = true;
		mouseReleased = true;
	}
	
	/** @private Event handler for mouse wheel events */
	private static function onMouseWheel(e:MouseEvent):Void
	{
		mouseWheel = true;
		_mouseWheelDelta = e.delta;
	}
	
	/** @private Event handler for mouse move events: only here for a bug workaround. */
	private static function onMouseMove(e:MouseEvent):Void
	{
		if (mouseCursor == "hide") {
			Mouse.show();
			Mouse.hide();
		}
		
		HP.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	
	// Max amount of characters stored by the keystring.
	/** @private */ private static inline var KEYSTRING_MAX:Int = 100;
	
	// Input information.
	/** @private */ private static var _enabled:Bool = false;
	/** @private */ private static var _key:Array<Bool>;
	/** @private */ private static var _keyNum:Int = 0;
	/** @private */ private static var _press:Array<Int>;
	/** @private */ private static var _release:Array<Int>;
	/** @private */ private static var _pressNum:Int = 0;
	/** @private */ private static var _releaseNum:Int = 0;
	/** @private */ private static var _control:Map<String, Array<Int>>;
	/** @private */ private static var _mouseWheelDelta:Int = 0;
	/** @private */ private static var _mouseVisible:Bool = true;
}

