package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Rectangle;
import net.hxpunk.HP;

/**
 * Special Image object that can display blocks of tiles.
 */
class TiledImage extends Image
{
	/**
	 * Constructs the TiledImage.
	 * @param	texture		Source texture. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	width		The width of the image (the texture will be drawn to fill this area).
	 * @param	height		The height of the image (the texture will be drawn to fill this area).
	 * @param	clipRect	An optional area of the source texture to use (eg. a tile from a tileset).
	 */
	public function new(texture:Dynamic, width:Int = 0, height:Int = 0, clipRect:Rectangle = null)
	{
		_graphics = HP.sprite.graphics;
		_width = width;
		_height = height;
		super(texture, clipRect);
	}
	
	/** Creates the buffer. */
	override private function createBuffer():Void 
	{
		if (_buffer != null) {
			_buffer.dispose();
			_buffer = null;
		}
		if (_width <= 0) _width = Std.int(_sourceRect.width);
		if (_height <= 0) _height = Std.int(_sourceRect.height);
		_buffer = new BitmapData(_width, _height, true, 0);
		_bufferRect = _buffer.rect;
		_bitmap.bitmapData = _buffer;
	}
	
	/** Updates the buffer. */
	override public function updateBuffer(clearBefore:Bool = false):Void
	{
		if (_source == null) return;
		if (_texture == null)
		{
			_texture = new BitmapData(Std.int(_sourceRect.width), Std.int(_sourceRect.height), true, 0);
			_texture.copyPixels(_source, _sourceRect, HP.zero);
		}
		_buffer.fillRect(_bufferRect, 0);
		_graphics.clear();
		if (_offsetX != 0 || _offsetY != 0)
		{
			HP.matrix.identity();
			HP.matrix.tx = Math.round(_offsetX);
			HP.matrix.ty = Math.round(_offsetY);
			_graphics.beginBitmapFill(_texture, HP.matrix);
		}
		else _graphics.beginBitmapFill(_texture);
		_graphics.drawRect(0, 0, _width, _height);
		_buffer.draw(HP.sprite, null, _tint);
	}
	
	/**
	 * The x-offset of the texture.
	 */
	public var offsetX(get, set):Float;
	private inline function get_offsetX():Float { return _offsetX; }
	private function set_offsetX(value:Float):Float
	{
		if (_offsetX == value) return value;
		_offsetX = value;
		updateBuffer();
		return value;
	}
	
	/**
	 * The y-offset of the texture.
	 */
	public var offsetY(get, set):Float;
	private inline function get_offsetY():Float { return _offsetY; }
	private function set_offsetY(value:Float):Float
	{
		if (_offsetY == value) return value;
		_offsetY = value;
		updateBuffer();
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
	
	// Drawing information.
	private var _graphics:Graphics;
	private var _texture:BitmapData;
	private var _width:Int = 0;
	private var _height:Int = 0;
	private var _offsetX:Float = 0;
	private var _offsetY:Float = 0;
}
