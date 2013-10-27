package net.hxpunk;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.geom.Matrix;
import net.hxpunk.graphics.Image;
import net.hxpunk.HP;

/**
 * Container for the main screen buffer. Can be used to transform the screen.
 */
class Screen
{
	/**
	 * Constructor.
	 */
	public function new() 
	{
		// init vars
		_sprite = new Sprite();
		_bitmap = new Array<Bitmap>();
		_matrix = new Matrix();

		HP.engine.addChild(_sprite);
		resize();
		update();
	}
	
	/**
	 * Initialise buffers to current screen size.
	 */
	public function resize():Void
	{
		if (_bitmap[0] != null) {
			_sprite.removeChild(_bitmap[0]);
			_sprite.removeChild(_bitmap[1]);
			
			_bitmap[0].bitmapData.dispose();
			_bitmap[1].bitmapData.dispose();
		}
		
		// create screen buffers
		_bitmap.push(new Bitmap(new BitmapData(HP.width, HP.height, false, _color), PixelSnapping.NEVER));
		_bitmap.push(new Bitmap(new BitmapData(HP.width, HP.height, false, _color), PixelSnapping.NEVER));
		_sprite.addChild(_bitmap[0]).visible = true;
		_sprite.addChild(_bitmap[1]).visible = false;
		HP.buffer = _bitmap[0].bitmapData;
		_width = HP.width;
		_height = HP.height;
		_current = 0;
	}
	
	/**
	 * Swaps screen buffers.
	 */
	public function swap():Void
	{
		_current = 1 - _current;
		HP.buffer = _bitmap[_current].bitmapData;
	}
	
	/**
	 * Refreshes the screen.
	 */
	public function refresh():Void
	{
		// refreshes the screen
		HP.buffer.fillRect(HP.bounds, _color);
	}
	
	/**
	 * Redraws the screen.
	 */
	public function redraw():Void
	{
		// refresh the buffers
		_bitmap[_current].visible = true;
		_bitmap[1 - _current].visible = false;
	}
	
	/** @private Re-applies transformation matrix. */
	public function update():Void
	{
		_matrix.b = _matrix.c = 0;
		_matrix.a = _scaleX * _scale;
		_matrix.d = _scaleY * _scale;
		_matrix.tx = -_originX * _matrix.a;
		_matrix.ty = -_originY * _matrix.d;
		if (_angle != 0) _matrix.rotate(_angle);
		_matrix.tx += _originX * _scaleX * _scale + _x;
		_matrix.ty += _originY * _scaleX * _scale + _y;
		_sprite.transform.matrix = _matrix;
	}
	
	/**
	 * Refresh color of the screen.
	 */
	public var color(get, set):UInt = 0;
	public function get_color() { return _color; }
	public function set_color(value:UInt):UInt { 
		_color = 0xFF000000 | value; 
		return _color;
	}
	
	/**
	 * X offset of the screen.
	 */
	public var x(get, set):Int = 0;
	public function get_x() { return _x; }
	public function set_x(value:Int):Int
	{
		if (_x == value) return value;
		_x = value;
		update();
		return value;
	}
	
	/**
	 * Y offset of the screen.
	 */
	public var y(get, set):Int = 0;
	public function get_y() { return _y; }
	public function set_y(value:Int):Int
	{
		if (_y == value) return value;
		_y = value;
		update();
		return value;
	}
	
	/**
	 * X origin of transformations.
	 */
	public var originX(get, set):Int = 0;
	public function get_originX() { return _originX; }
	public function set_originX(value:Int):Int
	{
		if (_originX == value) return value;
		_originX = value;
		update();
		return value;
	}
	
	/**
	 * Y origin of transformations.
	 */
	public var originY(get, set):Int = 0;
	public function get_originY() { return _originY; }
	public function set_originY(value:Int):Int
	{
		if (_originY == value) return value;
		_originY = value;
		update();
		return value;
	}
	
	/**
	 * X scale of the screen.
	 */
	public var scaleX(get, set):Float = 0;
	public function get_scaleX() { return _scaleX; }
	public function set_scaleX(value:Float):Float
	{
		if (_scaleX == value) return value;
		_scaleX = value;
		update();
		return value;
	}
	
	/**
	 * Y scale of the screen.
	 */
	public var scaleY(get, set):Float = 0;
	public function get_scaleY() { return _scaleY; }
	public function set_scaleY(value:Float):Float
	{
		if (_scaleY == value) return value;
		_scaleY = value;
		update();
		return value;
	}
	
	/**
	 * Scale factor of the screen. Final scale is scaleX * scale by scaleY * scale, so
	 * you can use this factor to scale the screen both horizontally and vertically.
	 */
	public var scale(get, set):Float = 0;
	public function get_scale() { return _scale; }
	public function set_scale(value:Float):Float
	{
		if (_scale == value) return value;
		_scale = value;
		update();
		return value;
	}
	
	/**
	 * Rotation of the screen, in degrees.
	 */
	public var angle(get, set):Float = 0;
	public function get_angle() { return _angle * HP.DEG; }
	public function set_angle(value:Float):Float
	{
		if (_angle == value * HP.RAD) return value;
		_angle = value * HP.RAD;
		update();
		return _angle;
	}
	
	/**
	 * Whether screen smoothing should be used or not.
	 */
	public var smoothing(get, set):Bool;
	public function get_smoothing() { return _bitmap[0].smoothing; }
	public function set_smoothing(value) { 
		_bitmap[0].smoothing = value; 
		_bitmap[1].smoothing = value; 
		return value;
	}
	
	/**
	 * Width of the screen.
	 */
	public var width(get, null):UInt = 0;
	public function get_width() { return _width; }
	
	/**
	 * Height of the screen.
	 */
	public var height(get, null):UInt = 0;
	public function get_height() { return _height; }
	
	/**
	 * X position of the mouse on the screen.
	 */
	public var mouseX(get, null):Int = 0;
	public function get_mouseX() { return Std.int(_sprite.mouseX); }
	
	/**
	 * Y position of the mouse on the screen.
	 */
	public var mouseY(get, null):Int = 0;
	public function get_mouseY() { return Std.int(_sprite.mouseY); }
	
	/**
	 * Captures the current screen as an Image object.
	 * @return	A new Image object.
	 */
	public function capture():Image
	{
		return new Image(_bitmap[_current].bitmapData.clone());
	}
	
	// Screen information.
	/** @private */ private var _sprite:Sprite;
	/** @private */ private var _bitmap:Array<Bitmap>;
	/** @private */ private var _current:Int = 0;
	/** @private */ private var _matrix:Matrix;
	/** @private */ private var _x:Int = 0;
	/** @private */ private var _y:Int = 0;
	/** @private */ private var _width:UInt = 0;
	/** @private */ private var _height:UInt = 0;
	/** @private */ private var _originX:Int = 0;
	/** @private */ private var _originY:Int = 0;
	/** @private */ private var _scaleX:Float = 1;
	/** @private */ private var _scaleY:Float = 1;
	/** @private */ private var _scale:Float = 1;
	/** @private */ private var _angle:Float = 0;
	/** @private */ private var _color:UInt = 0xFF202020;
}

