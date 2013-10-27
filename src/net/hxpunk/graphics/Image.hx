package net.hxpunk.graphics;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.GradientType;
import flash.display.SpreadMethod;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Graphic;
import net.hxpunk.HP;

/**
 * Performance-optimized non-animated image. Can be drawn to the screen with transformations.
 */
class Image extends Graphic
{
	/**
	 * Rotation of the image, in degrees.
	 */
	public var angle:Float = 0;
	
	/**
	 * Scale of the image, affects both x and y scale.
	 */
	public var scale:Float = 1;
	
	/**
	 * X scale of the image.
	 */
	public var scaleX:Float = 1;
	
	/**
	 * Y scale of the image.
	 */
	public var scaleY:Float = 1;
	
	/**
	 * X origin of the image, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originX:Float = 0;
	
	/**
	 * Y origin of the image, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originY:Float = 0;
	
	/**
	 * Optional blend mode to use when drawing this image.
	 * Use constants from the flash.display.BlendMode class.
	 */
	public var blend:BlendMode;
	
	/**
	 * If the image should be drawn transformed with pixel smoothing.
	 * This will affect drawing performance, but look less pixelly.
	 * Defaults to not smoothed.
	 */
	public var smooth:Bool;
	
	/**
	 * tintMode value to tint in multiply mode.
	 */
	public static inline var TINTING_MULTIPLY:Float = 0.0;
	
	/**
	 * tintMode value to tint in colorize mode.
	 */
	public static inline var TINTING_COLORIZE:Float = 1.0;
	
	/**
	 * Constructor.
	 * @param	source		Source image.
	 * @param	clipRect	Optional rectangle defining area of the source image to draw.
	 */
	public function new(source:Dynamic, clipRect:Rectangle = null) 
	{
		super();
		
		// init vars
		_bitmap = new Bitmap();
		_colorTransform = new ColorTransform();
		_matrix = HP.matrix;

		
		if (Std.is(source, Class))
		{
			_source = HP.getBitmap(source);
			_class = Type.getClassName(source);
		}
		else if (Std.is(source, BitmapData)) _source = source;
		if (_source == null) throw new Error("Invalid source image.");
		_sourceRect = _source.rect;
		if (clipRect != null)
		{
			if (clipRect.width > 0) clipRect.width = _sourceRect.width;
			if (clipRect.height > 0) clipRect.height = _sourceRect.height;
			_sourceRect = clipRect;
		}
		createBuffer();
		updateBuffer();
	}
	
	/** @private Creates the buffer. */
	private function createBuffer():Void
	{
		if (_buffer != null) {
			_buffer.dispose();
			_buffer = null;
		}
		_buffer = new BitmapData(Std.int(_sourceRect.width), Std.int(_sourceRect.height), true, 0);
		_bufferRect = _buffer.rect;
		_bitmap.bitmapData = _buffer;
	}
	
	/** @private Renders the image. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void
	{
		// quit if no graphic is assigned
		if (_buffer == null) return;
		
		// determine drawing location
		_point.x = point.x + x - originX - camera.x * scrollX;
		_point.y = point.y + y - originY - camera.y * scrollY;
		
		// render without transformation
		if (angle == 0 && scaleX * scale == 1 && scaleY * scale == 1 && blend == null)
		{
			target.copyPixels(_buffer, _bufferRect, _point, null, null, true);
			return;
		}
		
		// render with transformation
		_matrix.b = _matrix.c = 0;
		_matrix.a = scaleX * scale;
		_matrix.d = scaleY * scale;
		_matrix.tx = -originX * _matrix.a;
		_matrix.ty = -originY * _matrix.d;
		if (angle != 0) _matrix.rotate(angle * HP.RAD);
		_matrix.tx += originX + _point.x;
		_matrix.ty += originY + _point.y;
		_bitmap.smoothing = smooth;
		target.draw(_bitmap, _matrix, null, blend, null, smooth);
	}
	
	/**
	 * Creates a new rectangle Image.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @return	A new Image object.
	 */
	public static function createRect(width:UInt, height:UInt, color:UInt = 0xFFFFFF, alpha:Float = 1):Image
	{
		var source:BitmapData = new BitmapData(width, height, true, 0xFFFFFFFF);
		
		var image:Image = new Image(source);
		
		image.color = color;
		image.alpha = alpha;
		
		return image;
	}
	
	/**
	 * Creates a new circle Image.
	 * @param	radius		Radius of the circle.
	 * @param	color		Color of the circle.
	 * @param	alpha		Alpha of the circle.
	 * @return	A new Image object.
	 */
	public static function createCircle(radius:UInt, color:UInt = 0xFFFFFF, alpha:Float = 1):Image
	{
		HP.sprite.graphics.clear();
		HP.sprite.graphics.beginFill(0xFFFFFF);
		HP.sprite.graphics.drawCircle(radius, radius, radius);
		var data:BitmapData = new BitmapData(radius * 2, radius * 2, true, 0);
		data.draw(HP.sprite);
		
		var image:Image = new Image(data);
		
		image.color = color;
		image.alpha = alpha;
		
		return image;
	}
	
	/**
	 * Creates a new gradient Image.
	 * @param	width		Width of the image.
	 * @param	height		Height of the image.
	 * @param	fromX		X coordinate to start gradient at.
	 * @param	fromY		Y coordinate to start gradient at.
	 * @param	toX			X coordinate to end gradient at.
	 * @param	toY			X coordinate to end gradient at.
	 * @param	fromColor	Color at start of gradient.
	 * @param	toColor		Color at end of gradient.
	 * @param	fromAlpha	Alpha at start of gradient.
	 * @param	toAlpha		Alpha at end of gradient.
	 * @return	A new Image object.
	 */
	public static function createGradient (width:UInt, height:UInt, fromX:Float, fromY:Float, toX:Float, toY:Float, fromColor:UInt, toColor:UInt, fromAlpha:Float = 1, toAlpha:Float = 1):Image
	{
		var bitmap:BitmapData = new BitmapData(width, height, true, 0x0);
		
		var fillType:GradientType = GradientType.LINEAR;
		var spreadMethod:SpreadMethod = SpreadMethod.PAD;
		var colors:Array<Int> = [fromColor & 0xFFFFFF, toColor & 0xFFFFFF];
		var alphas:Array<Dynamic> = [fromAlpha, toAlpha];
		var ratios:Array<Dynamic> = [0x00, 0xFF];
		
		var dirX:Float = toX - fromX;
		var dirY:Float = toY - fromY;
		var mRotation:Float = Math.atan2(dirY, dirX);
		var mWidth:Float = dirX;
		var mHeight:Float = dirY;
		if (toX < fromX) {
			fromX = toX;
			mWidth *= -1;
		}
		if (toY < fromY) {
			fromY = toY;
			mHeight *= -1;
		}
		
		if (mWidth == 0) mWidth = 1;
		if (mHeight == 0) mHeight = 1;
		
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(mWidth, mHeight, mRotation, fromX, fromY);
		
		HP.sprite.graphics.clear();
		HP.sprite.graphics.beginGradientFill(fillType, colors, alphas, ratios, matrix, spreadMethod);
		HP.sprite.graphics.drawRect(0, 0, width, height);
		
		bitmap.draw(HP.sprite);
		
		return new Image(bitmap);
	}
	
	/**
	 * Updates the image buffer.
	 */
	public function updateBuffer(clearBefore:Bool = false):Void
	{
		if (locked)
		{
			_needsUpdate = true;
			if (clearBefore) _needsClear = true;
			return;
		}
		if (_source == null) return;
		if (clearBefore) _buffer.fillRect(_bufferRect, 0);
		_buffer.copyPixels(_source, _sourceRect, HP.zero, _drawMask, HP.zero);
		if (_tint != null) _buffer.colorTransform(_bufferRect, _tint);
	}
	
	/**
	 * Clears the image buffer.
	 */
	public function clear():Void
	{
		_buffer.fillRect(_bufferRect, 0);
	}
	
	/**
	 * Change the opacity of the Image, a value from 0 to 1.
	 */
	public var alpha(get, set):Float = 0;
	public function get_alpha() { return _alpha; }
	public function set_alpha(value:Float):Float
	{
		value = value < 0 ? 0 : (value > 1 ? 1 : value);
		if (_alpha == value) return value;
		_alpha = value;
		updateColorTransform();
		return value;
	}
	
	/**
	 * The tinted color of the Image. Use 0xFFFFFF to draw the
	 * Image normally with the default blending mode.
	 * Default: 0xFFFFFF.
	 */
	public var color(get, set):UInt = 0;
	public function get_color() { return _color; }
	public function set_color(value:UInt):UInt
	{
		value &= 0xFFFFFF;
		if (_color == value) return _color;
		_color = value;
		updateColorTransform();
		return _color;
	}
	
	/**
	 * The amount the image will be tinted, suggested values from
	 * 0 to 1. 0 Means no change, 1 is full color tint.
	 * Default: 1.
	 */
	public var tinting(get, set):Float = 0;
	public function get_tinting() { return _tintFactor; }
	public function set_tinting(value:Float):Float
	{
		if (_tintFactor == value) return value;
		_tintFactor = value;
		updateColorTransform();
		return value;
	}
	
	/**
	 * The tint mode - multiply or colorize.
	 * Default: multiply.
	 * See Image.TINTING_MULTIPLY and Image.TINTING_COLORIZE.
	 */
	public var tintMode(get, set):Float = 0;
	public function get_tintMode() { return _tintMode; }
	public function set_tintMode(value:Float):Float
	{
		if (_tintMode == value) return value;
		_tintMode = value;
		updateColorTransform();
		return value;
	}
	
	/**
	 * Updates the color transform
	 */
	private function updateColorTransform():Void {
		if (_alpha == 1) {
			if (_tintFactor == 0) {
				_tint = null;
				return updateBuffer();
			}
			if ((_tintMode == TINTING_MULTIPLY) && (_color == 0xFFFFFF)) {
				_tint = null;
				return updateBuffer();
			}
		}
		_tint = _colorTransform;
		
		_tint.redMultiplier   = _tintMode * (1.0 - _tintFactor) + (1-_tintMode) * (_tintFactor * ((_color >> 16 & 0xFF) / 255 - 1) + 1);
		_tint.greenMultiplier = _tintMode * (1.0 - _tintFactor) + (1-_tintMode) * (_tintFactor * ((_color >> 8 & 0xFF) / 255 - 1) + 1);
		_tint.blueMultiplier  = _tintMode * (1.0 - _tintFactor) + (1-_tintMode) * (_tintFactor * ((_color & 0xFF) / 255 - 1) + 1);
		_tint.redOffset       = (_color >> 16 & 0xFF) * _tintFactor * _tintMode;
		_tint.greenOffset     = (_color >> 8 & 0xFF) * _tintFactor * _tintMode;
		_tint.blueOffset      = (_color & 0xFF) * _tintFactor * _tintMode;
		
		_tint.alphaMultiplier = _alpha;
		updateBuffer();
	}
	
	/**
	 * If you want to draw the Image horizontally flipped. This is
	 * faster than setting scaleX to -1 if your image isn't transformed.
	 */
	public var flipped(get, set):Bool;
	public function get_flipped() { return _flipped; }
	public function set_flipped(value:Bool):Bool
	{
		if (_flipped == value) return value;
		_flipped = value;
		var temp:BitmapData = _source;
		if (_flip != null)
		{
			_source = _flip;
			_flip = temp;
			updateBuffer();
			return value;
		}
		if (_class != null && _flips.exists(_class))
		{
			_source = _flips[_class];
			_flip = temp;
			updateBuffer();
			return value;
		}
		_source = new BitmapData(_source.width, _source.height, true, 0);
		_flip = temp;
		HP.matrix.identity();
		HP.matrix.a = -1;
		HP.matrix.tx = _source.width;
		_source.draw(temp, HP.matrix);
		
		if (_class != null) _flips[_class] = _source;
		
		updateBuffer();
		return value;
	}
	
	/**
	 * Set the transparency mask of the Image.
	 */
	public var drawMask(get, set):BitmapData;
	public function get_drawMask() { return _drawMask; }
	public function set_drawMask(value:BitmapData):BitmapData
	{
		// no early exit because the BitmapData contents might have changed
		_drawMask = value;
		updateBuffer(true);
		return value;
	}
	
	/**
	 * Centers the Image's originX/Y to its center.
	 */
	public function centerOrigin():Void
	{
		originX = _bufferRect.width / 2;
		originY = _bufferRect.height / 2;
	}
	
	/**
	 * Width of the image.
	 */
	public var width(get, set):UInt = 0;
	public function get_width() { return Std.int(_bufferRect.width); }
	public function set_width(value:UInt):UInt { throw new Error("Cannot modify this property!"); return 0; }
	
	/**
	 * Height of the image.
	 */
	public var height(get, set):UInt = 0;
	public function get_height() { return Std.int(_bufferRect.height); }
	public function set_height(value:UInt):UInt { throw new Error("Cannot modify this property!"); return 0; }
	
	/**
	 * The scaled width of the image.
	 */
	public var scaledWidth(get, set):Float = 0;
	public function get_scaledWidth() { return _bufferRect.width * scaleX * scale; }
	
	/**
	 * Set the scaled width of the image.
	 */
	public function set_scaledWidth(w:Float):Float { return scaleX = w / scale / _bufferRect.width; }
	
	/**
	 * The scaled height of the image.
	 */
	public var scaledHeight(get, set):Float = 0;
	public function get_scaledHeight() { return _bufferRect.height * scaleY * scale; }
	
	/**
	 * Set the scaled height of the image.
	 */
	public function set_scaledHeight(h:Float):Float { return scaleY = h / scale / _bufferRect.height; }
	
	/**
	 * Clipping rectangle for the image.
	 */
	public var clipRect(get, null):Rectangle;
	public function get_clipRect() { return _sourceRect; }
	
	/** @private Source BitmapData image. */
	public var source(get, null):BitmapData;
	private function get_source() { return _source; }
	
	/**
	 * Lock the image, preventing updateBuffer() from being run until
	 * unlock() is called, for performance.
	 */
	public function lock():Void
	{
		_locked = true;
	}
	
	/**
	 * Unlock the image. Any pending updates will be applied immediately.
	 */
	public function unlock():Void
	{
		_locked = false;
		if (_needsUpdate) updateBuffer(_needsClear);
		_needsUpdate = _needsClear = false;
	}
	
	/**
	 * True if the image is locked.
	 */
	public var locked(get, null):Bool;
	public function get_locked() { return _locked; }
	
	// Locking
	/** @private */ private var _locked:Bool = false;
	/** @private */ private var _needsClear:Bool = false;
	/** @private */ private var _needsUpdate:Bool = false;
	
	// Source and buffer information.
	/** @private */ private var _source:BitmapData;
	/** @private */ private var _sourceRect:Rectangle;
	/** @private */ private var _buffer:BitmapData;
	/** @private */ private var _bufferRect:Rectangle;
	/** @private */ private var _bitmap:Bitmap;
	
	// Color and alpha information.
	/** @private */ private var _alpha:Float = 1;
	/** @private */ private var _color:UInt = 0x00FFFFFF;
	/** @private */ private var _tintFactor:Float = 1.0;
	/** @private */ private var _tintMode:Float = TINTING_MULTIPLY;
	/** @private */ private var _tint:ColorTransform;
	/** @private */ private var _colorTransform:ColorTransform;
	/** @private */ private var _matrix:Matrix;
	/** @private */ private var _drawMask:BitmapData;
	
	// Flipped image information.
	/** @private */ private var _class:String;
	/** @private */ private var _flipped:Bool;
	/** @private */ private var _flip:BitmapData;
	/** @private */ private static var _flips:Map<String, BitmapData> = new Map<String, BitmapData>();
}