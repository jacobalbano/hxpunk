package net.hxpunk.masks;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.utils.Draw;


/**
 * A bitmap mask used for pixel-perfect collision. 
 */
class Pixelmask extends Hitbox
{
	/**
	 * Alpha threshold of the bitmap used for collision.
	 */
	public var threshold:Int = 1;
	
	/**
	 * Constructor.
	 * @param	source		The image to use as a mask.
	 * @param	x			X offset of the mask.
	 * @param	y			Y offset of the mask.
	 */
	public function new(source:Dynamic, x:Int = 0, y:Int = 0)
	{
		super();
		
		_rect = HP.rect;
		_point = HP.point;
		_point2 = HP.point2;

		// fetch mask data
		_data = HP.getBitmap(source);
		if (_data == null) throw new Error("Invalid Pixelmask source image.");
		
		// set mask properties
		_width = data.width;
		_height = data.height;
		_x = x;
		_y = y;
		
		// set callback functions
		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
		_check.set(Type.getClassName(Pixelmask), collidePixelmask);
	}
	
	public static function test(thisBMD:BitmapData, firstPoint:Point, firstAlhpaThreshold:Int, secondObject:Dynamic):Bool 
	{
		var rectA:Rectangle = thisBMD.rect.clone();
		rectA.x = firstPoint.x;
		rectA.y = firstPoint.y;
		var firstBMD:BitmapData = thisBMD;
		var rectB:Rectangle = null;
		var secondBMD:BitmapData = null;
		
		if (Std.is(secondObject, Rectangle)) {
			rectB = cast secondObject;
			secondBMD = new BitmapData(Std.int(rectB.width), Std.int(rectB.height), true);
		} else if (Std.is(secondObject, BitmapData)) {
			secondBMD = cast secondObject;
			rectB = secondBMD.rect;
		} else if (Std.is(secondObject, Point)) {
			var p:Point = cast secondObject;
			rectB = new Rectangle(p.x, p.y, 1, 1);
		} else throw new Error("Invalid");
		
		var intersectRect:Rectangle = rectA.intersection(rectB);
		var boundsOverlap:Bool = (intersectRect.width > 0 && intersectRect.height > 0);
		if (boundsOverlap) {
			var colorTransform:ColorTransform = new ColorTransform();
			var intersectBMD:BitmapData = new BitmapData(Std.int(intersectRect.width), Std.int(intersectRect.height), true, 0);
			var transformMatrix:Matrix = new Matrix(1, 0, 0, 1, -rectA.x, -rectA.y);
			intersectBMD.draw(firstBMD, transformMatrix, colorTransform);
			transformMatrix.tx = rectB.x;
			transformMatrix.ty = rectB.y;
			//intersectBMD.draw(secondBMD, transformMatrix, colorTransform);
			
			Draw.enqueueCall("copyPixels", [firstBMD.clone(), null, new Point(HP.halfWidth, HP.halfHeight)]); 
			//intersectBMD.dispose();
			//intersectBMD = null;
		}
		
		return boundsOverlap;
	}
	
	/** @private Collide against an Entity. */
	override private function collideMask(other:Mask):Bool
	{
		_point.x = parent.x + _x;
		_point.y = parent.y + _y;
		_rect.x = other.parent.x - other.parent.originX;
		_rect.y = other.parent.y - other.parent.originY;
		_rect.width = other.parent.width;
		_rect.height = other.parent.height;
		trace("mask");
		trace(Pixelmask.test(_data, _point, threshold, _rect));
		return _data.hitTest(_point, threshold, _rect);
	}
	
	/** @private Collide against a Hitbox. */
	override private function collideHitbox(other:Hitbox):Bool
	{
		_point.x = parent.x + _x;
		_point.y = parent.y + _y;
		_rect.x = other.parent.x + other._x;
		_rect.y = other.parent.y + other._y;
		_rect.width = other._width;
		_rect.height = other._height;
		trace("hitbox");
		return _data.hitTest(_point, threshold, _rect);
	}
	
	/** @private Collide against a Pixelmask. */
	private function collidePixelmask(other:Pixelmask):Bool
	{
		_point.x = parent.x + _x;
		_point.y = parent.y + _y;
		_point2.x = other.parent.x + other._x;
		_point2.y = other.parent.y + other._y;
		trace("pixmask");
		return _data.hitTest(_point, threshold, other._data, _point2, other.threshold);
	}
	
	/**
	 * Current BitmapData mask.
	 */
	public var data(get, set):BitmapData;
	private inline function get_data():BitmapData { return _data; }
	private function set_data(value:BitmapData):BitmapData
	{
		_data = value;
		_width = value.width;
		_height = value.height;
		update();
		return data;
	}
	
	public override function renderDebug(g:Graphics):Void
	{
		if (_debug == null) {
			_debug = new BitmapData(_data.width, _data.height, true, 0x0);
		}
		
		HP.rect.x = 0;
		HP.rect.y = 0;
		HP.rect.width = _data.width;
		HP.rect.height = _data.height;
		
		_debug.fillRect(HP.rect, 0x0);
		_debug.threshold(_data, HP.rect, HP.zero, ">=", threshold << 24, 0x40FFFFFF, 0xFF000000);
		
		var sx:Float = HP.screen.scaleX * HP.screen.scale;
		var sy:Float = HP.screen.scaleY * HP.screen.scale;
		
		HP.matrix.a = sx;
		HP.matrix.d = sy;
		HP.matrix.b = HP.matrix.c = 0;
		HP.matrix.tx = (parent.x - parent.originX - HP.camera.x)*sx;
		HP.matrix.ty = (parent.y - parent.originY - HP.camera.y)*sy;
		
		g.lineStyle();
		g.beginBitmapFill(_debug, HP.matrix);
		g.drawRect(HP.matrix.tx, HP.matrix.ty, _data.width*sx, _data.height*sy);
		g.endFill();
	}
	
	// Pixelmask information.
	/** @private */ private var _data:BitmapData;
	/** @private */ private var _debug:BitmapData;
	
	// Global objects.
	/** @private */ private var _rect:Rectangle;
	/** @private */ private var _point:Point;
	/** @private */ private var _point2:Point;
}

