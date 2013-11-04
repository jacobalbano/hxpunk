package net.hxpunk.graphics;

import flash.display.BitmapData;
import net.hxpunk.graphics.Spritemap.VoidCallback;
import net.hxpunk.HP;


/**
 * Special Spritemap object that can display blocks of animated sprites.
 */
class TiledSpritemap extends Spritemap
{
	/**
	 * Constructs the tiled spritemap.
	 * @param	source			Source image.
	 * @param	frameWidth		Frame width.
	 * @param	frameHeight		Frame height.	
	 * @param	width			Width of the block to render.
	 * @param	height			Height of the block to render.
	 * @param	callback		Optional callback function for animation end.
	 */
	public function new(source:Dynamic, frameWidth:Int = 0, frameHeight:Int = 0, width:Int = 0, height:Int = 0, callback:VoidCallback = null) 
	{
		_imageWidth = width;
		_imageHeight = height;
		super(source, frameWidth, frameHeight, callback);
	}
	
	/** @private Creates the buffer. */
	override private function createBuffer():Void 
	{
		if (_buffer != null) {
			_buffer.dispose();
			_buffer = null;
		}
		if (_imageWidth <= 0) _imageWidth = Std.int(_sourceRect.width);
		if (_imageHeight <= 0) _imageHeight = Std.int(_sourceRect.height);
		_buffer = new BitmapData(_imageWidth, _imageHeight, true, 0);
		_bufferRect = _buffer.rect;
		_bitmap.bitmapData = _buffer;
	}
	
	/** @private Updates the buffer. */
	override public function updateBuffer(clearBefore:Bool = false):Void 
	{
		// get position of the current frame
		_rect.x = _rect.width * _frame;
		_rect.y = Std.int(_rect.x / _width) * _rect.height;
		_rect.x %= _width;
		if (_flipped) _rect.x = (_width - _rect.width) - _rect.x;
		
		// render it repeated to the buffer
		var xx:Int = Std.int(_offsetX) % _imageWidth,
			yy:Int = Std.int(_offsetY) % _imageHeight;
		if (xx >= 0) xx -= _imageWidth;
		if (yy >= 0) yy -= _imageHeight;
		HP.point.x = xx;
		HP.point.y = yy;
		while (HP.point.y < _imageHeight)
		{
			while (HP.point.x < _imageWidth)
			{
				_buffer.copyPixels(_source, _sourceRect, HP.point);
				HP.point.x += _sourceRect.width;
			}
			HP.point.x = xx;
			HP.point.y += _sourceRect.height;
		}
		
		// tint the buffer
		if (_tint != null) _buffer.colorTransform(_bufferRect, _tint);
	}
	
	/**
	 * The x-offset of the texture.
	 */
	public var offsetX(get, set):Float;
	private inline function get_offsetX():Float { return _offsetX; }
	private function set_offsetX(value:Float):Float
	{
		if (_offsetX != value) {
			_offsetX = value;
			updateBuffer();
		}
		return value;
	}
	
	/**
	 * The y-offset of the texture.
	 */
	public var offsetY(get, set):Float;
	private inline function get_offsetY():Float { return _offsetY; }
	private function set_offsetY(value:Float):Float
	{
		if (_offsetY != value) {
			_offsetY = value;
			updateBuffer();
		}
		return value;
	}
	
	/**
	 * Sets the texture offset.
	 * @param	x		The x-offset.
	 * @param	y		The y-offset.
	 */
	public function setOffset(x:Float, y:Float):Void
	{
		if (_offsetX == x && _offsetY == y) return;
		_offsetX = x;
		_offsetY = y;
		updateBuffer();
	}
	
	/** @private */ private var _imageWidth:Int = 0;
	/** @private */ private var _imageHeight:Int = 0;
	/** @private */ private var _offsetX:Float = 0;
	/** @private */ private var _offsetY:Float = 0;
}

