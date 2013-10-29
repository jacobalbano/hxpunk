package net.hxpunk;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.Stage;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;
#if flash
import flash.media.SoundMixer;
#end
import flash.media.SoundTransform;
import flash.text.Font;
import flash.utils.ByteArray;
import net.hxpunk.debug.Console;
import net.hxpunk.Screen;
import net.hxpunk.tweens.misc.Alarm;
import openfl.Assets;


typedef PointLike = { var x:Dynamic; var y:Dynamic; }

/**
 * Static catch-all class used to access global properties and functions.
 */
class HP 
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * The FlashPunk major version.
	 */
	public static inline var VERSION:String = "1.7.2";
	
	/**
	 * Width of the game.
	 */
	public static var width:Int = 0;
	
	/**
	 * Height of the game.
	 */
	public static var height:Int = 0;
	
	/**
	 * Half width of the game.
	 */
	public static var halfWidth:Float = 0;
	
	/**
	 * Half height of the game.
	 */
	public static var halfHeight:Float = 0;
	
	/**
	 * If the game is running at a fixed framerate.
	 */
	public static var fixed:Bool;
	
	/**
	 * If times should be given in frames (as opposed to seconds).
	 * Default is true in fixed timestep mode and false in variable timestep mode.
	 */
	public static var timeInFrames:Bool;
	
	/**
	 * The framerate assigned to the stage.
	 */
	public static var frameRate:Float = 0;
	
	/**
	 * The framerate assigned to the stage.
	 */
	public static var assignedFrameRate:Float = 0;
	
	/**
	 * Time elapsed since the last frame (in seconds).
	 */
	public static var elapsed:Float = 0;
	
	/**
	 * Timescale applied to HP.elapsed.
	 */
	public static var rate:Float = 1;
	
	/**
	 * The Screen object, use to transform or offset the Screen.
	 */
	public static var screen:Screen;
	
	/**
	 * The current screen buffer, drawn to in the render loop.
	 */
	public static var buffer:BitmapData;
	
	/**
	 * A rectangle representing the size of the screen.
	 */
	public static var bounds:Rectangle;
	
	/**
	 * Point used to determine drawing offset in the render loop.
	 */
	public static var camera:Point = new Point();
	
	/**
	 * Global Tweener for tweening values across multiple worlds.
	 */
	public static var tweener:Tweener;
	
	/**
	 * If the game currently has input focus or not. Note: may not be correct initially.
	 */
	public static var focused:Bool = true;
	
	/**
	 * The default font file to use.
	 * See DefaultFont
	 */
	public static var defaultFontName:String;	
	public static var defaultFont:Font;

	
	private static inline function initStaticVars():Bool 
	{
		// Tweener
		tweener = new Tweener();

		// Bitmap storage.
		_bitmap = new Map<String, BitmapData>();
		
		// Volume control.
		_soundTransform = new SoundTransform();
		
		// Global objects used for rendering, collision, etc.
		point = new Point();
		point2 = new Point();
		zero = new Point();
		rect = new Rectangle();
		matrix = new Matrix();
		sprite = new Sprite();
		entity = new Entity();

		// Default Font
		defaultFont = new DefaultFont();
		defaultFontName = defaultFont.fontName;
		
		return true;
	}
	
	/**
	 * Resize the screen.
	 * @param width		New width.
	 * @param height	New height.
	 */
	public static function resize(width:Int, height:Int):Void
	{
		HP.width = width;
		HP.height = height;
		HP.halfWidth = width/2;
		HP.halfHeight = height/2;
		HP.bounds.width = width;
		HP.bounds.height = height;
		HP.screen.resize();
	}
	
	/**
	 * The currently active World object. When you set this, the World is flagged
	 * to switch, but won't actually do so until the end of the current frame.
	 */
	public static var world(get, set):World;
	private static inline function get_world() { return _world; }
	private static inline function set_world(value:World):World
	{
		if (_goto != null) {
			if (_goto == value) return value;
		} else {
			if (_world == value) return value;
		}
		_goto = value;
		return value;
	}
	
	/**
	 * Sets the camera position.
	 * @param	x	X position.
	 * @param	y	Y position.
	 */
	public static inline function setCamera(x:Float = 0, y:Float = 0):Void
	{
		camera.x = x;
		camera.y = y;
	}
	
	/**
	 * Resets the camera position.
	 */
	public static inline function resetCamera():Void
	{
		camera.x = camera.y = 0;
	}
	
	/**
	 * Global volume factor for all sounds, a value from 0 to 1.
	 */
	public static var volume(get, set):Float;
	private static inline function get_volume() { return _volume; }
	private static inline function set_volume(value:Float):Float
	{
		if (value < 0) value = 0;
		if (_volume == value) return value;
		_soundTransform.volume = _volume = value;
	#if flash
		SoundMixer.soundTransform = _soundTransform;
	#end
		return value;
	}
	
	/**
	 * Global panning factor for all sounds, a value from -1 to 1.
	 */
	public static var pan(get, set):Float;
	private static inline function get_pan() { return _pan; }
	private static inline function set_pan(value:Float):Float
	{
		if (value < -1) value = -1;
		if (value > 1) value = 1;
		if (_pan == value) return value;
		_soundTransform.pan = _pan = value;
	#if flash
		SoundMixer.soundTransform = _soundTransform;
	#end
		return value;
	}
	
	/**
	 * Remove all elements from an array
	 * @param	array	The array to clear.
	 */
	public static inline function removeAll(array:Array<Dynamic>):Void
	{
	#if !(cpp || php)
		untyped array.length = 0;
	#else
		array.splice(0, array.length);
	#end
	}
	
	/**
	 * Remove an element from an array
	 * @return	True if element existed and has been removed, false if element was not in array.
	 */
	public static inline function remove(array:Array<Dynamic>, toRemove:Dynamic):Bool
	{
		var i:Int = Lambda.indexOf(array, toRemove);
		
		if (i >= 0) {
			array.splice(i, 1);
		
			return true;
		} else {
			return false;
		}
	}
	
	/**
	 * Randomly chooses and returns one of the provided values.
	 * @param	objs		The Objects you want to randomly choose from. Can be Ints, Floats, Points, etc.
	 * @return	A randomly chosen one of the provided parameters.
	 */
	public static var choose(get, null):Dynamic;
	private static inline function get_choose():Dynamic 
	{
		return Reflect.makeVarArgs(_choose);
	}
	
	
	private static inline function _choose(objects:Array<Dynamic>):Dynamic 
	{
		if (objects.length == 1) return objects[0][Std.random(objects[0].length)];
		return objects[Std.random(objects.length)];
	}
	
	/**
	 * Finds the sign of the provided value.
	 * @param	value		The Float to evaluate.
	 * @return	1 if value &gt; 0, -1 if value &lt; 0, and 0 when value == 0.
	 */
	public static inline function sign(value:Float):Int
	{
		return value < 0 ? -1 : (value > 0 ? 1 : 0);
	}
	
	/**
	 * Approaches the value towards the target, by the specified amount, without overshooting the target.
	 * @param	value	The starting value.
	 * @param	target	The target that you want value to approach.
	 * @param	amount	How much you want the value to approach target by.
	 * @return	The new value.
	 */
	public static inline function approach(value:Float, target:Float, amount:Float):Float
	{
		if (value < target - amount) {
			return value + amount;
		} else if (value > target + amount) {
			return value - amount;
		} else {
			return target;
		}
	}
	
	/**
	 * Linear Interpolation between two values.
	 * @param	a		First value.
	 * @param	b		Second value.
	 * @param	t		Interpolation factor.
	 * @return	When t=0, returns a. When t=1, returns b. When t=0.5, will return halfway between a and b. Etc.
	 */
	public static inline function lerp(a:Float, b:Float, t:Float = 1):Float
	{
		return a + (b - a) * t;
	}
	
	/**
	 * Linear Interpolation between two colors.
	 * @param	fromColor		First color.
	 * @param	toColor			Second color.
	 * @param	t				Interpolation value. Clamped to the range [0, 1].
	 * return	RGB component-interpolated color value.
	 */
	public static inline function colorLerp(fromColor:Int, toColor:Int, t:Float = 1):Int
	{
		if (t <= 0) { return fromColor; }
		if (t >= 1) { return toColor; }
		var a:Int = fromColor >> 24 & 0xFF,
			r:Int = fromColor >> 16 & 0xFF,
			g:Int = fromColor >> 8 & 0xFF,
			b:Int = fromColor & 0xFF,
			dA:Int = (toColor >> 24 & 0xFF) - a,
			dR:Int = (toColor >> 16 & 0xFF) - r,
			dG:Int = (toColor >> 8 & 0xFF) - g,
			dB:Int = (toColor & 0xFF) - b;
		a += Std.int(dA * t);
		r += Std.int(dR * t);
		g += Std.int(dG * t);
		b += Std.int(dB * t);
		return a << 24 | r << 16 | g << 8 | b;
	}
	
	/**
	 * Steps the object towards a point.
	 * @param	object		Object to move (must have an x and y property).
	 * @param	x			X position to step towards.
	 * @param	y			Y position to step towards.
	 * @param	distance	The distance to step (will not overshoot target).
	 */
	public static function stepTowards(object:PointLike, x:Float, y:Float, distance:Float = 1):Void
	{
		point.x = x - object.x;
		point.y = y - object.y;
		if (point.length <= distance)
		{
			object.x = x;
			object.y = y;
			return;
		}
		point.normalize(distance);
		object.x += point.x;
		object.y += point.y;
	}
	
	/**
	 * Anchors the object to a position.
	 * @param	object		The object to anchor.
	 * @param	anchor		The anchor object.
	 * @param	distance	The max distance object can be anchored to the anchor.
	 */
	public static inline function anchorTo(object:PointLike, anchor:PointLike, distance:Float = 0):Void
	{
		point.x = object.x - anchor.x;
		point.y = object.y - anchor.y;
		if (point.length > distance) point.normalize(distance);
		object.x = anchor.x + point.x;
		object.y = anchor.y + point.y;
	}
	
	/**
	 * Finds the angle (in degrees) from point 1 to point 2.
	 * @param	x1		The first x-position.
	 * @param	y1		The first y-position.
	 * @param	x2		The second x-position.
	 * @param	y2		The second y-position.
	 * @return	The angle from (x1, y1) to (x2, y2).
	 */
	public static inline function angle(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var a:Float = Math.atan2(y2 - y1, x2 - x1) * DEG;
		return a < 0 ? a + 360 : a;
	}
	
	/**
	 * Sets the x/y values of the provided object to a vector of the specified angle and length.
	 * @param	object		The object whose x/y properties should be set.
	 * @param	angle		The angle of the vector, in degrees.
	 * @param	length		The distance to the vector from (0, 0).
	 * @param	x			X offset.
	 * @param	y			Y offset.
	 */
	public static inline function angleXY(object:PointLike, angle:Float, length:Float = 1, x:Float = 0, y:Float = 0):Void
	{
		angle *= RAD;
		object.x = Math.cos(angle) * length + x;
		object.y = Math.sin(angle) * length + y;
	}
	
	/**
	 * Rotates the object around the anchor by the specified amount.
	 * @param	object		Object to rotate around the anchor.
	 * @param	anchor		Anchor to rotate around.
	 * @param	angle		The amount of degrees to rotate by.
	 */
	public static inline function rotateAround(object:PointLike, anchor:PointLike, angle:Float = 0, relative:Bool = true):Void
	{
		if (relative) angle += HP.angle(anchor.x, anchor.y, object.x, object.y);
		HP.angleXY(object, angle, HP.distance(anchor.x, anchor.y, object.x, object.y), anchor.x, anchor.y);
	}
	
	/**
	 * Gets the difference of two angles, wrapped around to the range -180 to 180.
	 * @param	a	First angle in degrees.
	 * @param	b	Second angle in degrees.
	 * @return	Difference in angles, wrapped around to the range -180 to 180.
	 */
	public static inline function angleDiff(a:Float, b:Float):Float
	{
		var diff:Float = b - a;

		while (diff > 180) { diff -= 360; }
		while (diff <= -180) { diff += 360; }

		return diff;
	}
	/**
	 * Find the distance between two points.
	 * @param	x1		The first x-position.
	 * @param	y1		The first y-position.
	 * @param	x2		The second x-position.
	 * @param	y2		The second y-position.
	 * @return	The distance.
	 */
	public static inline function distance(x1:Float, y1:Float, x2:Float = 0, y2:Float = 0):Float
	{
		return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
	}
	
	/**
	 * Find the distance between two rectangles. Will return 0 if the rectangles overlap.
	 * @param	x1		The x-position of the first rect.
	 * @param	y1		The y-position of the first rect.
	 * @param	w1		The width of the first rect.
	 * @param	h1		The height of the first rect.
	 * @param	x2		The x-position of the second rect.
	 * @param	y2		The y-position of the second rect.
	 * @param	w2		The width of the second rect.
	 * @param	h2		The height of the second rect.
	 * @return	The distance.
	 */
	public static function distanceRects(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Float
	{
		if (x1 < x2 + w2 && x2 < x1 + w1)
		{
			if (y1 < y2 + h2 && y2 < y1 + h1) return 0;
			if (y1 > y2) return y1 - (y2 + h2);
			return y2 - (y1 + h1);
		}
		if (y1 < y2 + h2 && y2 < y1 + h1)
		{
			if (x1 > x2) return x1 - (x2 + w2);
			return x2 - (x1 + w1);
		}
		if (x1 > x2)
		{
			if (y1 > y2) return distance(x1, y1, (x2 + w2), (y2 + h2));
			return distance(x1, y1 + h1, x2 + w2, y2);
		}
		if (y1 > y2) return distance(x1 + w1, y1, x2, y2 + h2);
		return distance(x1 + w1, y1 + h1, x2, y2);
	}
	
	/**
	 * Find the distance between a point and a rectangle. Returns 0 if the point is within the rectangle.
	 * @param	px		The x-position of the point.
	 * @param	py		The y-position of the point.
	 * @param	rx		The x-position of the rect.
	 * @param	ry		The y-position of the rect.
	 * @param	rw		The width of the rect.
	 * @param	rh		The height of the rect.
	 * @return	The distance.
	 */
	public static function distanceRectPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Float
	{
		if (px >= rx && px <= rx + rw)
		{
			if (py >= ry && py <= ry + rh) return 0;
			if (py > ry) return py - (ry + rh);
			return ry - py;
		}
		if (py >= ry && py <= ry + rh)
		{
			if (px > rx) return px - (rx + rw);
			return rx - px;
		}
		if (px > rx)
		{
			if (py > ry) return distance(px, py, rx + rw, ry + rh);
			return distance(px, py, rx + rw, ry);
		}
		if (py > ry) return distance(px, py, rx, ry + rh);
		return distance(px, py, rx, ry);
	}
	
	/**
	 * Clamps the value within the minimum and maximum values.
	 * @param	value		The Float to evaluate.
	 * @param	min			The minimum range.
	 * @param	max			The maximum range.
	 * @return	The clamped value.
	 */
	public static inline function clamp(value:Float, min:Float, max:Float):Float
	{
		if (max > min)
		{
			if (value < min) return min;
			else if (value > max) return max;
			else return value;
		} else {
			// Min/max swapped
			if (value < max) return max;
			else if (value > min) return min;
			else return value;
		}
	}
	
	/**
	 * Clamps the object inside the rectangle.
	 * @param	object		The object to clamp (must have an x and y property).
	 * @param	x			Rectangle's x.
	 * @param	y			Rectangle's y.
	 * @param	width		Rectangle's width.
	 * @param	height		Rectangle's height.
	 */
	public static inline function clampInRect(object:PointLike, x:Float, y:Float, width:Float, height:Float, padding:Float = 0):Void
	{
		object.x = clamp(object.x, x + padding, x + width - padding);
		object.y = clamp(object.y, y + padding, y + height - padding);
	}
	
	/**
	 * Transfers a value from one scale to another scale. For example, scale(.5, 0, 1, 10, 20) == 15, and scale(3, 0, 5, 100, 0) == 40.
	 * @param	value		The value on the first scale.
	 * @param	min			The minimum range of the first scale.
	 * @param	max			The maximum range of the first scale.
	 * @param	min2		The minimum range of the second scale.
	 * @param	max2		The maximum range of the second scale.
	 * @return	The scaled value.
	 */
	public static inline function scale(value:Float, min:Float, max:Float, min2:Float, max2:Float):Float
	{
		return min2 + ((value - min) / (max - min)) * (max2 - min2);
	}
	
	/**
	 * Transfers a value from one scale to another scale, but clamps the return value within the second scale.
	 * @param	value		The value on the first scale.
	 * @param	min			The minimum range of the first scale.
	 * @param	max			The maximum range of the first scale.
	 * @param	min2		The minimum range of the second scale.
	 * @param	max2		The maximum range of the second scale.
	 * @return	The scaled and clamped value.
	 */
	public static function scaleClamp(value:Float, min:Float, max:Float, min2:Float, max2:Float):Float
	{
		value = min2 + ((value - min) / (max - min)) * (max2 - min2);
		if (max2 > min2)
		{
			value = value < max2 ? value : max2;
			return value > min2 ? value : min2;
		}
		value = value < min2 ? value : min2;
		return value > max2 ? value : max2;
	}
	
	/**
	 * The random seed used by FP's random functions.
	 */
	public static var randomSeed(get, set):Int;
	private static inline function get_randomSeed() { return _getSeed; }
	private static inline function set_randomSeed(value:Int):Int
	{
		_seed = Std.int(clamp(value, 1, 2147483646));
		_getSeed = _seed;
		return value;
	}
	
	/**
	 * Randomizes the random seed using Flash's Math.random() function.
	 */
	public static inline function randomizeSeed():Void
	{
		randomSeed = Std.int(2147483647 * Math.random());
	}
	
	/**
	 * A pseudo-random Float produced using FP's random seed, where 0 &lt;= Float &lt; 1.
	 */
	public static var random(get, null):Float;
	private static inline function get_random()
	{
		_seed = (_seed * 16807) % 2147483647;
		return _seed / 2147483647;
	}
	
	/**
	 * Returns a pseudo-random Int.
	 * @param	amount		The returned Int will always be 0 &lt;= Int &lt; amount.
	 * @return	The Int.
	 */
	public static inline function rand(amount:Int):Int
	{
		_seed = (_seed * 16807) % 2147483647;
		return Std.int((_seed / 2147483647) * amount);
	}
	
	/**
	 * Returns the next item after current in the list of options.
	 * @param	current		The currently selected item (must be one of the options).
	 * @param	options		An array of all the items to cycle through.
	 * @param	loop		If true, will jump to the first item after the last item is reached.
	 * @return	The next item in the list.
	 */
	public static inline function next(current:Dynamic, options:Array<Dynamic>, loop:Bool = true):Dynamic
	{
		if (loop) return options[(Lambda.indexOf(options, current) + 1) % options.length];
		return options[Std.int(Math.max(Lambda.indexOf(options, current) + 1, options.length - 1))];
	}
	
	/**
	 * Returns the item previous to the current in the list of options.
	 * @param	current		The currently selected item (must be one of the options).
	 * @param	options		An array of all the items to cycle through.
	 * @param	loop		If true, will jump to the last item after the first is reached.
	 * @return	The previous item in the list.
	 */
	public static inline function prev(current:Dynamic, options:Array<Dynamic>, loop:Bool = true):Dynamic
	{
		if (loop) return options[((Lambda.indexOf(options, current) - 1) + options.length) % options.length];
		return options[Std.int(Math.max(Lambda.indexOf(options, current) - 1, 0))];
	}
	
	/**
	 * Swaps the current item between a and b. Useful for quick state/string/value swapping.
	 * @param	current		The currently selected item.
	 * @param	a			Item a.
	 * @param	b			Item b.
	 * @return	Returns a if current is b, and b if current is a.
	 */
	public static inline function swap(current:Dynamic, a:Dynamic, b:Dynamic):Dynamic
	{
		return current == a ? b : a;
	}
	
	/**
	 * Creates a color value by combining the chosen RGB values.
	 * @param	R		The red value of the color, from 0 to 255.
	 * @param	G		The green value of the color, from 0 to 255.
	 * @param	B		The blue value of the color, from 0 to 255.
	 * @return	The color Int.
	 */
	public static inline function getColorRGB(R:Int = 0, G:Int = 0, B:Int = 0):Int
	{
		return R << 16 | G << 8 | B;
	}
	
	/**
	 * Creates a color value with the chosen HSV values.
	 * @param	h		The hue of the color (from 0 to 1).
	 * @param	s		The saturation of the color (from 0 to 1).
	 * @param	v		The value of the color (from 0 to 1).
	 * @return	The color Int.
	 */
	public static inline function getColorHSV(h:Float, s:Float, v:Float):Int
	{
		h = h < 0 ? 0 : (h > 1 ? 1 : h);
		s = s < 0 ? 0 : (s > 1 ? 1 : s);
		v = v < 0 ? 0 : (v > 1 ? 1 : v);
		h = Std.int(h * 360);
		var hi:Int = Std.int(h / 60) % 6,
			f:Float = h / 60 - Std.int(h / 60),
			p:Float = (v * (1 - s)),
			q:Float = (v * (1 - f * s)),
			t:Float = (v * (1 - (1 - f) * s));
		switch (hi)
		{
			case 0: return Std.int(v * 255) << 16 | Std.int(t * 255) << 8 | Std.int(p * 255);
			case 1: return Std.int(q * 255) << 16 | Std.int(v * 255) << 8 | Std.int(p * 255);
			case 2: return Std.int(p * 255) << 16 | Std.int(v * 255) << 8 | Std.int(t * 255);
			case 3: return Std.int(p * 255) << 16 | Std.int(q * 255) << 8 | Std.int(v * 255);
			case 4: return Std.int(t * 255) << 16 | Std.int(p * 255) << 8 | Std.int(v * 255);
			case 5: return Std.int(v * 255) << 16 | Std.int(p * 255) << 8 | Std.int(q * 255);
			default: return 0;
		}
	}
	
	public static inline function getColorHue(color:Int):Float
	{
		var r:Int = (color >> 16) & 0xFF;
		var g:Int = (color >> 8) & 0xFF;
		var b:Int = color & 0xFF;
		
		var max:Int = Std.int(Math.max(r, Math.max(g, b)));
		var min:Int = Std.int(Math.min(r, Math.min(g, b)));
		
		var hue:Int = 0;
		 
		if (max == min) {
			hue = 0;
		} else if (max == r) {
			hue = Std.int((60 * (g-b) / (max-min) + 360) % 360);
		} else if (max == g) {
			hue = Std.int(60 * (b-r) / (max-min) + 120);
		} else if (max == b) {
			hue = Std.int(60 * (r-g) / (max-min) + 240);
		}
		
		return hue / 360;
	}
	
	public static inline function getColorSaturation(color:Int):Float
	{
		var r:Int = (color >> 16) & 0xFF;
		var g:Int = (color >> 8) & 0xFF;
		var b:Int = color & 0xFF;
		
		var max:Int = Std.int(Math.max(r, Math.max(g, b)));
		var min:Int = Std.int(Math.min(r, Math.min(g, b)));
		
		if (max == 0) {
			return 0;
		} else {
			return (max - min) / max;
		}
	}
	
	public static inline function getColorValue(color:Int):Float
	{
		var r:Int = (color >> 16) & 0xFF;
		var g:Int = (color >> 8) & 0xFF;
		var b:Int = color & 0xFF;
		
		return Math.max(r, Math.max(g, b)) / 255;
	}
	
	/**
	 * Finds the red factor of a color.
	 * @param	color		The color to evaluate.
	 * @return	A Int from 0 to 255.
	 */
	public static inline function getRed(color:Int):Int
	{
		return color >> 16 & 0xFF;
	}
	
	/**
	 * Finds the green factor of a color.
	 * @param	color		The color to evaluate.
	 * @return	A Int from 0 to 255.
	 */
	public static inline function getGreen(color:Int):Int
	{
		return color >> 8 & 0xFF;
	}
	
	/**
	 * Finds the blue factor of a color.
	 * @param	color		The color to evaluate.
	 * @return	A Int from 0 to 255.
	 */
	public static inline function getBlue(color:Int):Int
	{
		return color & 0xFF;
	}
	
	/**
	 * Fetches a stored BitmapData object represented by the source.
	 * @param	source		Embedded Bitmap class.
	 * @return	The stored BitmapData object.
	 */
public static function getBitmap(source:Dynamic):BitmapData
{
	var name:String = Std.string(source);
	if (_bitmap.exists(name))
		return _bitmap.get(name);

#if (openfl || nme)
	var data:BitmapData = Assets.getBitmapData(source);
#else
	var data:BitmapData = source.bitmapData;
#end
	if (data != null)
		_bitmap.set(name, data);

	return data;
}
	
	/**
	 * Clears the cache of BitmapData objects used by the getBitmap method.
	 */
	public static inline function clearBitmapCache():Void
	{
		_bitmap = new Map<String, BitmapData>();
	}
	
	/**
	 * Sets a time flag.
	 * @return	Time elapsed (in milliseconds) since the last time flag was set.
	 */
	public static inline function timeFlag():Float
	{
		var t:Float = Lib.getTimer(),
			e:Float = t - _time;
		_time = t;
		return e;
	}
	
	/**
	 * The global Console object.
	 */
	public static var console(get, null):Console;
	private static inline function get_console()
	{
		if (_console == null) _console = new Console();
		return _console;
	}
	
	/**
	 * Logs data to the console.
	 * @param	data		The data parameters to log, can be variables, objects, etc. Parameters will be separated by a space (" ").
	 */
	public static var log(get, null):Dynamic;
	private static inline function get_log()
	{
		return Reflect.makeVarArgs(_log);
	}

	private static function _log(data:Array<Dynamic>):Dynamic
	{
		if (_console != null)
		{
			if (data.length > 1)
			{
				var i:Int = 0, s:String = "";
				while (i < data.length)
				{
					if (i > 0) s += " ";
					s += Std.string(data[i ++]);
				}
				_console.log(s);
			}
			else _console.log(data[0]);
		}
		return null;
	}
	
	/**
	 * Adds properties to watch in the console's debug panel.
	 * @param	properties		The properties (strings) to watch.
	 */
	public static var watch(get, null):Dynamic;
	private static inline function get_watch()
	{
		return Reflect.makeVarArgs(_watch);
	}

	private static function _watch(properties:Array<Dynamic>):Dynamic
	{
		if (_console != null)
		{
			if (properties.length > 1) _console.watch(properties);
			else _console.watch(properties[0]);
		}
		return null;
	}
	
	/**
	 * Loads the file as an XML object.
	 * @param	file		The embedded file to load.
	 * @return	An XML object representing the file.
	 */
	public static inline function getXML(file:Class<ByteArray>):Xml
	{
		var bytes:ByteArray = Type.createInstance(file, []);
		return cast(bytes.readUTFBytes(bytes.length), Xml);
	}
	
	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a MultiVarTween tween, starting it and adding it to a Tweener.
	 * @param	object		The object containing the properties to tween.
	 * @param	values		An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween.
	 * @param	options		An object containing key/value pairs of the following optional parameters:
	 * 						type		Tween type.
	 * 						complete	Optional completion callback function.
	 * 						ease		Optional easer function.
	 * 						tweener		The Tweener to add this Tween to.
	 * 						delay		A length of time to wait before starting this tween.
	 * @return	The added MultiVarTween object.
	 * 
	 * Example: HP.tween(object, { x: 500, y: 350 }, 2.0, { ease: easeFunction, complete: onComplete } );
	 */
	/*public static function tween(object:Dynamic, values:Dynamic, duration:Float, options:Dynamic = null):MultiVarTween
	{
		var type:Int = Tween.ONESHOT,
			complete:Function = null,
			ease:Function = null,
			tweener:Tweener = HP.tweener,
			delay:Float = 0;
		if (Std.is(object, Tweener)) tweener = cast(object, Tweener);
		if (options)
		{
			if (Std.is(options, Function)) complete = cast(options, Function);
			if (Reflect.hasField(options, "type")) type = options.type;
			if (Reflect.hasField(options, "complete")) complete = options.complete;
			if (Reflect.hasField(options, "ease")) ease = options.ease;
			if (Reflect.hasField(options, "tweener")) tweener = options.tweener;
			if (Reflect.hasField(options, "delay")) delay = options.delay;
		}
		var tween:MultiVarTween = new MultiVarTween(complete, type);
		tween.tween(object, values, duration, ease, delay);
		tweener.addTween(tween);
		return tween;
	}*/
	
	/**
	 * Schedules a callback for the future. Shorthand for creating an Alarm tween, starting it and adding it to a Tweener.
	 * @param	delay		The duration to wait before calling the callback.
	 * @param	callback	The function to be called.
	 * @param	type		The tween type (PERSIST, LOOPING or ONESHOT). Defaults to ONESHOT.
	 * @param	tweener		The Tweener object to add this Alarm to. Defaults to HP.tweener.
	 * @return	The added Alarm object.
	 * 
	 * Example: HP.alarm(5.0, callbackFunction, Tween.LOOPING); // Calls callbackFunction every 5 seconds
	 */
	public static inline function alarm(delay:Float, callback:Void -> Void, type:Int = 2, tweener:Tweener = null):Alarm
	{
		if (tweener == null) tweener = HP.tweener;
		
		var alarm:Alarm = new Alarm(delay, callback, type);
		
		tweener.addTween(alarm, true);
		
		return alarm;
	}
	
	/**
	 * Gets an array of frame indices.
	 * @param	from	Starting frame.
	 * @param	to		Ending frame.
	 * @param	skip	Skip amount every frame (eg. use 1 for every 2nd frame).
	 */
	public static inline function frames(from:Int, to:Int, skip:Int = 0):Array<Int>
	{
		var a:Array<Int> = new Array<Int>();
		skip ++;
		if (from < to)
		{
			while (from <= to)
			{
				a.push(from);
				from += skip;
			}
		}
		else
		{
			while (from >= to)
			{
				a.push(from);
				from -= skip;
			}
		}
		return a;
	}
	
	/**
	 * Shuffles the elements in the array.
	 * @param	a		The Object to shuffle (an Array or Vector).
	 */
	public static inline function shuffle(a:Array<Dynamic>):Void
	{
		var i:Int = a.length, j:Int, t:Dynamic;
		while (-- i > 0)
		{
			t = a[i];
			a[i] = a[j = HP.rand(i + 1)];
			a[j] = t;
		}
	}
	
	/**
	 * Sorts the elements in the array.
	 * @param	object		The Object to sort (an Array or Vector).
	 * @param	ascending	If it should be sorted ascending (true) or descending (false).
	 */
	public static function sort<T>(object:Array<T>, ascending:Bool = true):Void
	{
		// Only need to sort the array if it has more than one item.
		if (object.length > 1)
		{
			quicksort(object, 0, object.length - 1, ascending);
		}
	}
	
	/**
	 * Sorts the elements in the array by a property of the element.
	 * @param	object		The Object to sort (an Array or Vector).
	 * @param	property	The numeric property of object's elements to sort by.
	 * @param	ascending	If it should be sorted ascending (true) or descending (false).
	 */
	public static function sortBy(object:Array<Dynamic>, property:String, ascending:Bool = true):Void
	{
		// Only need to sort the array if it has more than one item.
		if (object.length > 1)
		{
			quicksortBy(object, 0, object.length - 1, ascending, property);
		}
	}
	
	/** @private Quicksorts the array. */ 
	private static function quicksort<T>(a:Array<T>, left:Int, right:Int, ascending:Bool):Void
	{		
		var i:Int = left, j:Int = right, t:T,
			p:T = a[Math.round((left + right) * .5)];
		if (ascending)
		{
			while (i <= j)
			{
				while (Reflect.compare(a[i], p) < 0) i ++;
				while (Reflect.compare(a[j], p) > 0) j --;
				if (i <= j)
				{
					t = a[i];
					a[i ++] = a[j];
					a[j --] = t;
				}
			}
		}
		else
		{
			while (i <= j)
			{
				while (Reflect.compare(a[i], p) > 0) i ++;
				while (Reflect.compare(a[j], p) < 0) j --;
				if (i <= j)
				{
					t = a[i];
					a[i ++] = a[j];
					a[j --] = t;
				}
			}
		}
		if (left < j) quicksort(a, left, j, ascending);
		if (i < right) quicksort(a, i, right, ascending);
	}
	
	/** @private Quicksorts the array by the property. */ 
	private static function quicksortBy(a:Array<Dynamic>, left:Int, right:Int, ascending:Bool, property:String):Void
	{			
		var i:Int = left, j:Int = right, t:Dynamic,
			p:Dynamic = Reflect.getProperty(a[Math.round((left + right) * .5)], property);
		if (ascending)
		{
			while (i <= j)
			{
				while (Reflect.getProperty(a[i], property) < p) i ++;
				while (Reflect.getProperty(a[j], property) > p) j --;
				if (i <= j)
				{
					t = a[i];
					a[i ++] = a[j];
					a[j --] = t;
				}
			}
		}
		else
		{
			while (i <= j)
			{
				while (Reflect.getProperty(a[i], property) > p) i ++;
				while (Reflect.getProperty(a[j], property) < p) j --;
				if (i <= j)
				{
					t = a[i];
					a[i ++] = a[j];
					a[j --] = t;
				}
			}
		}
		if (left < j) quicksortBy(a, left, j, ascending, property);
		if (i < right) quicksortBy(a, i, right, ascending, property);
	}
	
	// TODO : update with Math.floor & Math.ceil
	public static function toFixed(x:Float, ?decimalPlaces:Int = 20, ?paddingZeroes:Bool = true):String 
	{
		if (Math.isNaN(x) || decimalPlaces <= 0) return Std.string(Std.int(x));
		var factor:Float = Math.pow(10, decimalPlaces);
		var str:String = Std.string((x * factor) / factor);
		var dotPos:Int = str.indexOf('.');
		if (dotPos <= 0) {
			dotPos = str.length;
			str + '.';
		}
		for (i in dotPos...dotPos + decimalPlaces) str += '0';
		return str.substr(0, dotPos + decimalPlaces + 1);
	}
	
	// World information.
	/** @private */ public static var _world:World;
	/** @private */ public static var _goto:World;
	
	// Console information.
	/** @private */ public static var _console:Console;
	
	// Time information.
	/** @private */ public static var _time:Float = 0;
	/** @private */ public static var _updateTime:Float = 0;
	/** @private */ public static var _renderTime:Float = 0;
	/** @private */ public static var _logicTime:Float = 0;
	/** @private */ public static var _systemTime:Float = 0;
	
	// Bitmap storage.
	/** @private */ private static var _bitmap:Map<String, BitmapData>;
	
	// Pseudo-random number generation (the seed is set in Engine's constructor).
	/** @private */ private static var _seed:Int = 0;
	/** @private */ private static var _getSeed:Int = 0;
	
	// Volume control.
	/** @private */ private static var _volume:Float = 1;
	/** @private */ private static var _pan:Float = 0;
	/** @private */ private static var _soundTransform:SoundTransform;
	
	// Used for rad-to-deg and deg-to-rad conversion.
	/** @private */ public static inline var DEG:Float = -57.295779513082320876798154814105; // -180 / Math.PI;
	/** @private */ public static inline var RAD:Float = -0.01745329251994329576923690768489; // Math.PI / -180; 
	
	// Global Flash objects.
	/** @private */ public static var stage:Stage;
	/** @private */ public static var engine:Engine;
	
	// Global objects used for rendering, collision, etc.
	/** @private */ public static var point:Point;
	/** @private */ public static var point2:Point;
	/** @private */ public static var zero:Point;
	/** @private */ public static var rect:Rectangle;
	/** @private */ public static var matrix:Matrix;
	/** @private */ public static var sprite:Sprite;
	/** @private */ public static var entity:Entity;
}

// Embedded default font
@:font("assets/hxpunk/04B_03__.ttf") class DefaultFont extends Font { }

