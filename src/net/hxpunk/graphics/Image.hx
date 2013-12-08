package net.hxpunk.graphics;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.LineScaleMode;
import flash.display.SpreadMethod;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Graphic;
import net.hxpunk.HP;
import net.hxpunk.masks.Polygon;

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
	 * @param	source		Source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	clipRect	Optional rectangle defining area of the source image to draw.
	 */
	public function new(source:Dynamic, clipRect:Rectangle = null) 
	{
		super();
		
		// init vars
		_bitmap = new Bitmap();
		_colorTransform = new ColorTransform();
		_matrix = HP.matrix;

		// set the graphic
		_source = HP.getBitmapData(source);
		if (Std.is(source, Class))
			_class = Type.getClassName(source);
		else if (Std.is(source, String)) 
			_class = source;
		if (_source == null) throw new Error("Image source must be of type BitmapData, String or Class.");
		_sourceRect = _source.rect;
		if (clipRect != null)
		{
			if (clipRect.width <= 0) clipRect.width = _sourceRect.width;
			if (clipRect.height <= 0) clipRect.height = _sourceRect.height;
			_sourceRect = clipRect;
		}
		createBuffer();
		updateBuffer();
	}
	
	/** Creates the buffer. */
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
	
	/** Renders the image. */
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
	 * @param	alpha		Alpha of the rectangle.
	 * @param	fill		If the rectangle should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @param	radius		Round rectangle corners by this amount.
	 * @return	A new Image object.
	 */
	public static function createRect(width:Int, height:Int, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1, radius:Float = 0):Image
	{
		var graphics:Graphics = HP.sprite.graphics;
		
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		graphics.clear();
		
		var thickOffset:Float = 0;
		if (fill) {
			graphics.beginFill(color, alpha);
		} else {
			thickOffset = thick * .5;
			graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		}
		
		if (radius <= 0) {
			graphics.drawRect(0 + thickOffset, 0 + thickOffset, width - thickOffset * 2, height - thickOffset * 2);
		} else {
			graphics.drawRoundRect(0 + thickOffset, 0 + thickOffset, width - thickOffset * 2, height - thickOffset * 2, radius);
		}
		graphics.endFill();

		var data:BitmapData = new BitmapData(width, height, true, 0);
		data.draw(HP.sprite);
		
		var image:Image = new Image(data);
		return image;
	}
	
	/**
	 * Creates a new circle Image.
	 * @param	radius		Radius of the circle.
	 * @param	color		Color of the circle.
	 * @param	alpha		Alpha of the circle.
	 * @param	fill		If the circle should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @return	A new Image object.
	 */
	public static function createCircle(radius:Int, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1):Image
	{
		var graphics:Graphics = HP.sprite.graphics;
		
		graphics.clear();
		if (fill) {
			graphics.beginFill(color & 0xFFFFFF, alpha);
			graphics.drawCircle(radius, radius, radius);
			graphics.endFill();
		} else {
			graphics.lineStyle(thick, color & 0xFFFFFF, alpha);
			graphics.drawCircle(radius, radius, radius - thick * .5);
		}
		var data:BitmapData = new BitmapData(radius * 2, radius * 2, true, 0);
		data.draw(HP.sprite);
		
		var image:Image = new Image(data);
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
	public static function createGradient (width:Int, height:Int, fromX:Float, fromY:Float, toX:Float, toY:Float, fromColor:Int, toColor:Int, fromAlpha:Float = 1, toAlpha:Float = 1):Image
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
	 * Creates a new polygon Image from an array of points.
	 * @param	points		Array containing the polygon's points.
	 * @param	color		Color of the polygon.
	 * @param	alpha		Alpha of the polygon.
	 * @param	fill		If the polygon should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @return	A new Image object.
	 */
	public static function createPolygonFromPoints(points:Array<Point>, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1):Image
	{
		var graphics:Graphics = HP.sprite.graphics;
		var minX:Float, maxX:Float;
		var minY:Float, maxY:Float;
		
		minX = minY = Math.POSITIVE_INFINITY;
		maxX = maxY = Math.NEGATIVE_INFINITY;
		
		// find polygon bounds
		for (p in points) {
			if (p.x < minX) minX = p.x;
			if (p.x > maxX) maxX = p.x;
			if (p.y < minY) minY = p.y;
			if (p.y > maxY) maxY = p.y;
		}
		var w:Int = Math.ceil(maxX - minX);
		var h:Int = Math.ceil(maxY - minY);
		
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		graphics.clear();
		
		if (fill) {
			graphics.beginFill(color, alpha);
		} else {
			graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		}
		
		graphics.moveTo(points[points.length - 1].x, points[points.length - 1].y);
		for (p in points)
		{
			graphics.lineTo(p.x, p.y);
		}
		graphics.endFill();
		
		var matrix:Matrix = HP.matrix;
		matrix.identity();
		matrix.translate(-minX, -minY);

		var data:BitmapData = new BitmapData(w, h, true, 0);
		data.draw(HP.sprite, matrix);
		
		var image:Image = new Image(data);
		return image;
	}
	
	/**
	 * Creates a new regular polygon Image.
	 * @param	sides		The number of sides in the polygon.
	 * @param	radius		The distance that the vertices are at.
	 * @param	angle		How much the polygon is rotated (in degrees).
	 * @param	color		Color of the polygon.
	 * @param	alpha		Alpha of the polygon.
	 * @param	fill		If the polygon should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @return	A new Image object.
	 */
	public static function createRegularPolygon(sides:Int = 3, radius:Float = 100, angle:Float = 0, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1):Image
	{
		if (sides < 3) throw new Error("The polygon needs at least 3 sides.");

		// figure out the angle required for each step
		var rotationAngle:Float = (Math.PI * 2) / sides;
		var angleRad:Float = angle * HP.RAD;

		// loop through and generate each point
		var points:Array<Point> = new Array<Point>();

		for (i in 0...sides)
		{
			var tempAngle:Float = i * rotationAngle + angleRad;
			var p:Point = new Point();
			p.x = Math.cos(tempAngle) * radius;
			p.y = Math.sin(tempAngle) * radius;
			points.push(p);
		}
		
		var image:Image = Image.createPolygonFromPoints(points, color, alpha, fill, thick);
		return image;
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
	public function clear(color:Int = 0):Void
	{
		_buffer.fillRect(_bufferRect, color);
	}
	
	/**
	 * Change the opacity of the Image, a value from 0 to 1.
	 */
	public var alpha(get, set):Float;
	private inline function get_alpha() { return _alpha; }
	private function set_alpha(value:Float):Float
	{
		value = value < 0 ? 0 : (value > 1 ? 1 : value);
		if (_alpha != value) {
			_alpha = value;
			updateColorTransform();
		}
		return value;
	}
	
	/**
	 * The tinted color of the Image. Use 0xFFFFFF to draw the
	 * Image normally with the default blending mode.
	 * Default: 0xFFFFFF.
	 */
	public var color(get, set):Int;
	private inline function get_color() { return _color; }
	private function set_color(value:Int):Int
	{
		value &= 0xFFFFFF;
		if (_color != value) {
			_color = value;
			updateColorTransform();
		}
		return value;
	}
	
	/**
	 * The amount the image will be tinted, suggested values from
	 * 0 to 1. 0 Means no change, 1 is full color tint.
	 * Default: 1.
	 */
	public var tinting(get, set):Float;
	private inline function get_tinting() { return _tintFactor; }
	private function set_tinting(value:Float):Float
	{
		if (_tintFactor != value) {
			_tintFactor = value;
			updateColorTransform();
		}
		return value;
	}
	
	/**
	 * The tint mode - multiply or colorize.
	 * Default: multiply.
	 * See Image.TINTING_MULTIPLY and Image.TINTING_COLORIZE.
	 */
	public var tintMode(get, set):Float;
	private inline function get_tintMode() { return _tintMode; }
	private function set_tintMode(value:Float):Float
	{
		if (_tintMode != value) {
			_tintMode = value;
			updateColorTransform();
		}
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
	private inline function get_flipped() { return _flipped; }
	private function set_flipped(value:Bool):Bool
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
	private inline function get_drawMask() { return _drawMask; }
	private function set_drawMask(value:BitmapData):BitmapData
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
	public var width(get, set):Int;
	private function get_width() { return Std.int(_bufferRect.width); }
	private function set_width(value:Int):Int { throw new Error("Cannot modify this property!"); return 0; }
	
	/**
	 * Height of the image.
	 */
	public var height(get, set):Int;
	private function get_height() { return Std.int(_bufferRect.height); }
	private function set_height(value:Int):Int { throw new Error("Cannot modify this property!"); return 0; }
	
	/**
	 * The scaled width of the image.
	 */
	public var scaledWidth(get, set):Float;
	private function get_scaledWidth() { return _bufferRect.width * scaleX * scale; }
	
	/**
	 * Set the scaled width of the image.
	 */
	private function set_scaledWidth(w:Float):Float { return scaleX = w / scale / _bufferRect.width; }
	
	/**
	 * The scaled height of the image.
	 */
	public var scaledHeight(get, set):Float;
	private function get_scaledHeight() { return _bufferRect.height * scaleY * scale; }
	
	/**
	 * Set the scaled height of the image.
	 */
	private function set_scaledHeight(h:Float):Float { return scaleY = h / scale / _bufferRect.height; }
	
	/**
	 * Clipping rectangle for the image.
	 */
	public var clipRect(get, null):Rectangle;
	private function get_clipRect() { return _sourceRect; }
	
	/** Source BitmapData image. */
	public var source(get, null):BitmapData;
	private inline function get_source() { return _source; }
	
	/** Buffer BitmapData image. */
	public var buffer(get, null):BitmapData;
	private inline function get_buffer() { return _buffer; }
	
	/**
	 * Lock the image, preventing updateBuffer() from being run until
	 * unlock() is called, for performance.
	 */
	public inline function lock():Void
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
	private inline function get_locked() { return _locked; }
	
	/**
	 * Sync the image with the specified polygon mask.
	 */
	public function syncWithPolygon(poly:Polygon):Void 
	{
		originX = poly.originX;
		originY = poly.originY;
		angle = poly.angle;
		x = poly.x + poly.originX;
		y = poly.y + poly.originY;
	}
	
	// Locking
	private var _locked:Bool = false;
	private var _needsClear:Bool = false;
	private var _needsUpdate:Bool = false;
	
	// Source and buffer information.
	private var _source:BitmapData;
	private var _sourceRect:Rectangle;
	private var _buffer:BitmapData;
	private var _bufferRect:Rectangle;
	private var _bitmap:Bitmap;
	
	// Color and alpha information.
	private var _alpha:Float = 1;
	private var _color:Int = 0x00FFFFFF;
	private var _tintFactor:Float = 1.0;
	private var _tintMode:Float = TINTING_MULTIPLY;
	private var _tint:ColorTransform;
	private var _colorTransform:ColorTransform;
	private var _matrix:Matrix;
	private var _drawMask:BitmapData;
	
	// Flipped image information.
	private var _class:String;
	private var _flipped:Bool;
	private var _flip:BitmapData;
	private static var _flips:Map<String, BitmapData> = new Map<String, BitmapData>();
}
