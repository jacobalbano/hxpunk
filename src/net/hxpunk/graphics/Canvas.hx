package net.hxpunk.graphics;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Graphic;
import net.hxpunk.HP;

/**
 * A  multi-purpose drawing canvas, can be sized beyond the normal Flash BitmapData limits.
 */
class Canvas extends Graphic
{
	/**
	 * Optional blend mode to use (see flash.display.BlendMode for blending modes).
	 */
	public var blend:BlendMode;
	
	/**
	 * Constructor.
	 * @param	width		Width of the canvas.
	 * @param	height		Height of the canvas.
	 */
	public function new(width:Int, height:Int) 
	{
		super();
		
		// init vars
		_buffers = new Array<BitmapData>();
		_bitmap = new Bitmap();
		
		// Color tinting information.
		_colorTransform = new ColorTransform();
		_matrix = new Matrix();
		
		// Global objects.
		_rect = HP.rect;
		_graphics = HP.sprite.graphics;

		
		_width = width;
		_height = height;
		_refWidth = Math.ceil(width / _maxWidth);
		_refHeight = Math.ceil(height / _maxHeight);
		_ref = new BitmapData(_refWidth, _refHeight, false, 0);
		var x:Int = 0, y:Int = 0, w:Int = 0, h:Int = 0, i:Int = 0,
			ww:Int = _width % _maxWidth,
			hh:Int = _height % _maxHeight;
		if (ww <= 0) ww = _maxWidth;
		if (hh <= 0) hh = _maxHeight;
		while (y < _refHeight)
		{
			h = y < _refHeight - 1 ? _maxHeight : hh;
			while (x < _refWidth)
			{
				w = x < _refWidth - 1 ? _maxWidth : ww;
				_ref.setPixel(x, y, i);
				_buffers[i] = new BitmapData(w, h, true, 0);
				i ++; x ++;
			}
			x = 0; y ++;
		}
	}
	
	/** @private Renders the canvas. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		// determine drawing location
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;
		
		_rect.x = _rect.y = 0;
		_rect.width = _maxWidth;
		_rect.height = _maxHeight;
		
		// render the buffers
		var xx:Int = 0, yy:Int = 0, buffer:BitmapData, px:Float = _point.x;
		while (yy < _refHeight)
		{
			while (xx < _refWidth)
			{
				buffer = _buffers[_ref.getPixel(xx, yy)];
				if (_tint != null || blend != null)
				{
					_matrix.identity();
					_matrix.tx = _point.x;
					_matrix.ty = _point.y;
					_bitmap.bitmapData = buffer;
					target.draw(_bitmap, _matrix, _tint, blend);
				}
				else target.copyPixels(buffer, _rect, _point, null, null, true);
				_point.x += _maxWidth;
				xx ++;
			}
			_point.x = px;
			_point.y += _maxHeight;
			xx = 0;
			yy ++;
		}
	}
	
	/**
	 * Draws to the canvas.
	 * @param	x			X position to draw.
	 * @param	y			Y position to draw.
	 * @param	source		Source BitmapData.
	 * @param	rect		Optional area of the source image to draw from. If null, the entire BitmapData will be drawn.
	 */
	public function draw(x:Int, y:Int, source:BitmapData, rect:Rectangle = null):Void
	{
		var xx:Int = 0, yy:Int = 0;
		for (buffer in _buffers)
		{
			_point.x = x - xx;
			_point.y = y - yy;
			buffer.copyPixels(source, rect != null ? rect : source.rect, _point, null, null, true);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
	}
	
	/**
	 * Mimics BitmapData's copyPixels method.
	 * @param	source			Source BitmapData.
	 * @param	rect			Area of the source image to draw from.
	 * @param	destPoint		Position to draw at.
	 * @param	alphaBitmapData	See BitmapData documentation for details.
	 * @param	alphaPoint		See BitmapData documentation for details.
	 * @param	mergeAlpha		See BitmapData documentation for details.
	 */
	public function copyPixels(source:BitmapData, rect:Rectangle, destPoint:Point, alphaBitmapData:BitmapData = null, alphaPoint:Point = null, mergeAlpha:Bool = false):Void
	{
		var destX:Float = destPoint.x;
		var destY:Float = destPoint.y;
		
		var ix1:Int = Std.int(destPoint.x / _maxWidth);
		var iy1:Int = Std.int(destPoint.y / _maxHeight);
		
		var ix2:Int = Std.int((destPoint.x + rect.width) / _maxWidth);
		var iy2:Int = Std.int((destPoint.y + rect.height) / _maxHeight);
		
		if (ix1 < 0) ix1 = 0;
		if (iy1 < 0) iy1 = 0;
		if (ix2 >= _refWidth) ix2 = _refWidth - 1;
		if (iy2 >= _refHeight) iy2 = _refHeight - 1;
		
		for (ix in ix1...ix2+1) {
			for (iy in iy1...iy2+1) {
				var buffer:BitmapData = _buffers[_ref.getPixel(ix, iy)];
				
				_point.x = destX - ix*_maxWidth;
				_point.y = destY - iy*_maxHeight;
		
				buffer.copyPixels(source, rect, _point, alphaBitmapData, alphaPoint, mergeAlpha);
			}
		}
				
	}
	
	/**
	 * Fills the rectangular area of the canvas. The previous contents of that area are completely removed.
	 * @param	rect		Fill rectangle.
	 * @param	color		Fill color.
	 * @param	alpha		Fill alpha.
	 */
	public function fill(rect:Rectangle, color:Int = 0, alpha:Float = 1):Void
	{
		var xx:Int = 0, yy:Int = 0, buffer:BitmapData;
		_rect.width = rect.width;
		_rect.height = rect.height;
		if (alpha >= 1) color |= 0xFF000000;
		else if (alpha <= 0) color = 0;
		else color = (Std.int(alpha * 255) << 24) | (0xFFFFFF & color);
		for (buffer in _buffers)
		{
			_rect.x = rect.x - xx;
			_rect.y = rect.y - yy;
			buffer.fillRect(_rect, color);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
	}
	
	/**
	 * Draws over a rectangular area of the canvas.
	 * @param	rect		Drawing rectangle.
	 * @param	color		Draw color.
	 * @param	alpha		Draw alpha. If &lt; 1, this rectangle will blend with existing contents of the canvas.
	 */
	public function drawRect(rect:Rectangle, color:Int = 0, alpha:Float = 1):Void
	{
		var xx:Int = 0, yy:Int = 0;
		if (alpha >= 1)
		{
			_rect.width = rect.width;
			_rect.height = rect.height;
			
			for (buffer in _buffers)
			{
				_rect.x = rect.x - xx;
				_rect.y = rect.y - yy;
				buffer.fillRect(_rect, 0xFF000000 | color);
				xx += _maxWidth;
				if (xx >= _width)
				{
					xx = 0;
					yy += _maxHeight;
				}
			}
			return;
		}
		for (buffer in _buffers)
		{
			_graphics.clear();
			_graphics.beginFill(color, alpha);
			_graphics.drawRect(rect.x - xx, rect.y - yy, rect.width, rect.height);
			buffer.draw(HP.sprite);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
		_graphics.endFill();
	}
	
	/**
	 * Fills the rectangle area of the canvas with the texture.
	 * @param	rect		Fill rectangle.
	 * @param	texture		Fill texture.
	 */
	public function fillTexture(rect:Rectangle, texture:BitmapData):Void
	{
		var xx:Int = 0, yy:Int = 0;
		for (buffer in _buffers)
		{
			_graphics.clear();
			_matrix.identity();
			_matrix.translate(rect.x - xx, rect.y - yy);
			_graphics.beginBitmapFill(texture, _matrix);
			_graphics.drawRect(rect.x - xx, rect.y - yy, rect.width, rect.height);
			buffer.draw(HP.sprite);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
		_graphics.endFill();
	}
	
	/**
	 * Draws the Graphic object to the canvas.
	 * @param	x			X position to draw.
	 * @param	y			Y position to draw.
	 * @param	source		Graphic to draw.
	 */
	public function drawGraphic(x:Int, y:Int, source:Graphic):Void
	{
		var xx:Int = 0, yy:Int = 0;
		for (buffer in _buffers)
		{
			_point.x = x - xx;
			_point.y = y - yy;
			source.render(buffer, _point, HP.zero);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
	}
	
	public function getPixel (x:Int, y:Int):Int
	{
		var buffer:BitmapData = _buffers[_ref.getPixel(Std.int(x / _maxWidth), Std.int(y / _maxHeight))];
		
		x %= _maxWidth;
		y %= _maxHeight;
		
		return buffer.getPixel32(x, y);
	}
	
	public function setPixel (x:Int, y:Int, color:Int):Void
	{
		var buffer:BitmapData = _buffers[_ref.getPixel(Std.int(x / _maxWidth), Std.int(y / _maxHeight))];
		
		x %= _maxWidth;
		y %= _maxHeight;
		
		buffer.setPixel32(x, y, color);
	}
	
	public function applyFilter(filter:BitmapFilter):Void
	{
		for (buffer in _buffers)
		{
			buffer.applyFilter(buffer, buffer.rect, HP.zero, filter);
		}
	}
	
	/**
	 * The tinted color of the Canvas. Use 0xFFFFFF to draw the it normally.
	 */
	public var color(get, set):Int;
	private inline function get_color():Int { return _color; }
	private function set_color(value:Int):Int
	{
		value &= 0xFFFFFF;
		if (_color == value) return value;
		_color = value;
		if (_alpha == 1 && _color == 0xFFFFFF)
		{
			_tint = null;
			return value;
		}
		_tint = _colorTransform;
		_tint.redMultiplier = (_color >> 16 & 0xFF) / 255;
		_tint.greenMultiplier = (_color >> 8 & 0xFF) / 255;
		_tint.blueMultiplier = (_color & 0xFF) / 255;
		_tint.alphaMultiplier = _alpha;
		return value;
	}
	
	/**
	 * Change the opacity of the Canvas, a value from 0 to 1.
	 */
	public var alpha(get, set):Float;
	private inline function get_alpha():Float { return _alpha; }
	private function set_alpha(value:Float):Float
	{
		if (value < 0) value = 0;
		if (value > 1) value = 1;
		if (_alpha == value) return value;
		_alpha = value;
		if (_alpha == 1 && _color == 0xFFFFFF)
		{
			_tint = null;
			return value;
		}
		_tint = _colorTransform;
		_tint.redMultiplier = (_color >> 16 & 0xFF) / 255;
		_tint.greenMultiplier = (_color >> 8 & 0xFF) / 255;
		_tint.blueMultiplier = (_color & 0xFF) / 255;
		_tint.alphaMultiplier = _alpha;
		return value;
	}
	
	/**
	 * Shifts the canvas' pixels by the offset.
	 * @param	x	Horizontal shift.
	 * @param	y	Vertical shift.
	 */
	public function shift(x:Int = 0, y:Int = 0):Void
	{
		drawGraphic(x, y, this);
	}
	
	/**
	 * Width of the canvas.
	 */
	public var width(get, null):Int;
	private inline function get_width():Int { return _width; }
	
	/**
	 * Height of the canvas.
	 */
	public var height(get, null):Int;
	private inline function get_height():Int { return _height; }
	
	// Buffer information.
	private var _buffers:Array<BitmapData>;
	private var _width:Int = 0;
	private var _height:Int = 0;
	private var _maxWidth:Int = 2880;
	private var _maxHeight:Int = 2880;
	private var _bitmap:Bitmap;
	
	// Color tinting information.
	private var _color:Int = 0xFFFFFF;
	private var _alpha:Float = 1;
	private var _tint:ColorTransform;
	private var _colorTransform:ColorTransform;
	private var _matrix:Matrix;
	
	// Canvas reference information.
	private var _ref:BitmapData;
	private var _refWidth:Int = 0;
	private var _refHeight:Int = 0;
	
	// Global objects.
	private var _rect:Rectangle;
	private var _graphics:Graphics;
}
