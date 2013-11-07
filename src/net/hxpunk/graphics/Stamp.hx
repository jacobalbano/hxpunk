package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Graphic;
import net.hxpunk.HP;

/**
 * A simple non-transformed, non-animated graphic.
 */
class Stamp extends Graphic
{
	/**
	 * Constructor.
	 * @param	source		Source image.
	 * @param	x			X offset.
	 * @param	y			Y offset.
	 */
	public function new(source:Dynamic, x:Int = 0, y:Int = 0) 
	{
		super();
		
		// set the origin
		this.x = x;
		this.y = y;
		
		// set the graphic
		_source = HP.getBitmapData(source);
		if (_source == null) throw new Error("Invalid source image.");
		_sourceRect = _source.rect;
	}
	
	/** @private Renders the Graphic. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		if (_source == null) return;
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;
		target.copyPixels(_source, _sourceRect, _point, null, null, true);
	}
	
	/**
	 * Source BitmapData image.
	 */
	public var source(get, set):BitmapData;
	private inline function get_source():BitmapData { return _source; }
	private inline function set_source(value:BitmapData):BitmapData
	{
		_source = value;
		if (_source != null) _sourceRect = _source.rect;
		return value;
	}
	
	/**
	 * Width of the stamp.
	 */
	public var width(get, null):Int;
	private inline function get_width():Int { return _source.width; }
	
	/**
	 * Height of the stamp.
	 */
	public var height(get, null):Int;
	private inline function get_height():Int { return _source.height; }
	
	/**
	 * Creates a new rectangle Stamp.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @return	A new Stamp object.
	 */
	public static function createRect(width:Int, height:Int, color:Int = 0xFFFFFF, alpha:Float = 1):Stamp
	{
		color = (0xFFFFFF & color) | Std.int(alpha * 255) << 24;
		
		var source:BitmapData = new BitmapData(width, height, true, color);
		
		return new Stamp(source);
	}
	
	// Stamp information.
	/** @private */ private var _source:BitmapData;
	/** @private */ private var _sourceRect:Rectangle;
}
