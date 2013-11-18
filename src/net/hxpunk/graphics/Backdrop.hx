package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.geom.Point;
import net.hxpunk.graphics.Canvas;
import net.hxpunk.HP;

/**
 * A background texture that can be repeated horizontally and vertically
 * when drawn. Really useful for parallax backgrounds, textures, etc.
 */
class Backdrop extends Canvas
{
	/**
	 * Constructor.
	 * @param	texture		Source texture. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	repeatX		Repeat horizontally.
	 * @param	repeatY		Repeat vertically.
	 */
	override public function new(texture:Dynamic, repeatX:Bool = true, repeatY:Bool = true) 
	{
		_texture = HP.getBitmapData(texture);
		if (_texture == null) _texture = new BitmapData(HP.width, HP.height, true, 0);
		
		_repeatX = repeatX;
		_repeatY = repeatY;
		_textWidth = _texture.width;
		_textHeight = _texture.height;
		
		super(HP.width * (repeatX ? 1 : 0) + _textWidth, HP.height * (repeatY ? 1 : 0) + _textHeight);
		
		HP.rect.x = HP.rect.y = 0;
		HP.rect.width = _width;
		HP.rect.height = _height;
		fillTexture(HP.rect, _texture);
	}
	
	/** @private Renders the Backdrop. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;
		
		if (_repeatX)
		{
			_point.x %= _textWidth;
			if (_point.x > 0) _point.x -= _textWidth;
		}
		
		if (_repeatY)
		{
			_point.y %= _textHeight;
			if (_point.y > 0) _point.y -= _textHeight;
		}
		
		_x = x; _y = y;
		x = y = 0;
		super.render(target, _point, HP.zero);
		x = _x; y = _y;
	}
	
	// Backdrop information.
	private var _texture:BitmapData;
	private var _textWidth:Int = 0;
	private var _textHeight:Int = 0;
	private var _repeatX:Bool = false;
	private var _repeatY:Bool = false;
	private var _x:Float = 0;
	private var _y:Float = 0;
}
