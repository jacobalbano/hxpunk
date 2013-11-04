package net.hxpunk;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.masks.Masklist;
import net.hxpunk.utils.Draw;


typedef HitCallback = Dynamic -> Bool;

/**
 * Base class for Entity collision masks.
 */
class Mask 
{
	/**
	 * The parent Entity of this mask.
	 */
	public var parent:Entity;
	
	/**
	 * The parent Masklist of the mask.
	 */
	public var list:Masklist;
	
	/**
	 * Constructor.
	 */
	public function new() 
	{
		_check = new Map<String, HitCallback>();
		
		_class = Type.getClassName(Type.getClass(this));
		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Masklist), collideMasklist);
	}
	
	/**
	 * Checks for collision with another Mask.
	 * @param	mask	The other Mask to check against.
	 * @return	If the Masks overlap.
	 */
	public function collide(mask:Mask):Bool
	{
		if (_check[mask._class] != null) return _check[mask._class](mask);
		if (mask._check[_class] != null) return mask._check[_class](this);
		return false;
	}
	
	/** @private Collide against an Entity. */
	private function collideMask(other:Mask):Bool
	{
		return parent.x - parent.originX + parent.width > other.parent.x - other.parent.originX
			&& parent.y - parent.originY + parent.height > other.parent.y - other.parent.originY
			&& parent.x - parent.originX < other.parent.x - other.parent.originX + other.parent.width
			&& parent.y - parent.originY < other.parent.y - other.parent.originY + other.parent.height;
	}
	
	/** @private Collide against a Masklist. */
	private function collideMasklist(other:Masklist):Bool
	{
		return other.collide(this);
	}
	
	/** @private Assigns the mask to the parent. */
	public function assignTo(parent:Entity):Void
	{
		this.parent = parent;
		if (list == null && parent != null) update();
	}
	
	/** @public Updates the parent's bounds for this mask. */
	public function update():Void
	{
		
	}
	
	/** Used to render debug information in console. */
	public function renderDebug(g:Graphics):Void
	{
		
	}
	
	
	
	/**
	 * Replacement for BitmapData.hitTest() that is not yet available in non-flash targets. TODO: Serious testing and optimizations (for Rect and Points above all).
	 * 
	 * @param	firstObject				The first BitmapData object to check against.
	 * @param	firstPoint				A position of the upper-left corner of the BitmapData image in an arbitrary coordinate space. The same coordinate space is used in defining the secondBitmapPoint parameter.
	 * @param	firstAlphaThreshold		The smallest alpha channel value that is considered opaque for this hit test.
	 * @param	secondObject			A Rectangle, Point, Bitmap, or BitmapData object.
	 * @param	secondPoint				A point that defines a pixel location in the second BitmapData object. Use this parameter only when the value of secondObject is a BitmapData object.
	 * @param	secondAlphaThreshold	The smallest alpha channel value that is considered opaque in the second BitmapData object. Use this parameter only when the value of secondObject is a BitmapData object and both BitmapData objects are transparent.
	 * 
	 * @return  A value of true if a hit occurs; otherwise, false.
	 */
	public static function hitTest(firstObject:BitmapData, firstPoint:Point, firstAlphaThreshold:Int, secondObject:Dynamic, secondPoint:Point = null, secondAlphaThreshold:Int = 1):Bool 
	{
		if (firstPoint == null) {
			throw new Error("firstPoint cannot be null.");
		}
		var rectA:Rectangle = firstObject.rect.clone();
		rectA.x = firstPoint.x;
		rectA.y = firstPoint.y;
		var firstBMD:BitmapData = firstObject;
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
		} else throw new Error("Invalid secondObjects. Must be Point, Rectangle or BitmapData.");
		
		if (secondPoint != null) {
			rectB.x = secondPoint.x;
			rectB.y = secondPoint.y;
		}
		
		var intersectRect:Rectangle = rectA.intersection(rectB);
		var boundsOverlap:Bool = (intersectRect.width > 0 && intersectRect.height > 0);
		var hit:Bool = false;

		if (boundsOverlap) {
			
			Draw.enqueueCall(function ():Void 
			{
				Draw.rectPlus(intersectRect.x, intersectRect.y, intersectRect.width, intersectRect.height, 0xFFFFFF, 1, false);
			});

			var colorTransform:ColorTransform = new ColorTransform(1, 0, 0, 1, 255, 0, 0, 256 - firstAlphaThreshold);
			var transformMatrix:Matrix = new Matrix();
			var intersectBMD:BitmapData = new BitmapData(Std.int(intersectRect.width), Std.int(intersectRect.height), true, 0);
			
			// draw firstBMD
			var xOffset:Float = intersectRect.x > rectA.x ? intersectRect.x - rectA.x : rectA.x - intersectRect.x;
			var yOffset:Float = intersectRect.y > rectA.y ? intersectRect.y - rectA.y : rectA.y - intersectRect.y;
			transformMatrix.translate(-xOffset, -yOffset);
			intersectBMD.draw(firstBMD, transformMatrix, colorTransform);
			
			// draw secondBMD
			xOffset = intersectRect.x > rectB.x ? intersectRect.x - rectB.x : rectB.x - intersectRect.x;
			yOffset = intersectRect.y > rectB.y ? intersectRect.y - rectB.y : rectB.y - intersectRect.y;
			transformMatrix.identity();
			transformMatrix.translate( -xOffset, -yOffset);
			colorTransform = new ColorTransform(0, 1, 0, 1, 0, 255, 0, 256 - secondAlphaThreshold);
			intersectBMD.draw(secondBMD, transformMatrix, colorTransform, BlendMode.ADD);
			
			Draw.enqueueCall(function ():Void 
			{
				Draw.copyPixels(intersectBMD, null, new Point(HP.halfWidth, HP.halfHeight));
			});
			
			var intersectRect = intersectBMD.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFF00);
			hit = (intersectRect.width > 0 && intersectRect.height > 0);
			
			//intersectBMD.dispose();
			//intersectBMD = null;
		}
		
		return hit;
	}
	
	
	// Mask information.
	/** @private */ private var _class:String;
	/** @private */ private var _check:Map<String, HitCallback>;
}
