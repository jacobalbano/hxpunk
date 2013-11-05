package net.hxpunk;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Memory;
import flash.utils.ByteArray;
import flash.Vector;
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
		var firstBMD:BitmapData = firstObject;
		var rectB:Rectangle = null;
		var secondBMD:BitmapData = null;
		
		if (Std.is(secondObject, Point)) {
			var p:Point = cast secondObject;
			rectB = new Rectangle(p.x, p.y, 1, 1);
			var pixel:Int = firstBMD.getPixel32(Std.int(p.x), Std.int(p.y));
			return (pixel >> 24) >= firstAlphaThreshold;
		} else if (Std.is(secondObject, Rectangle)) {
			rectB = (cast secondObject).clone();
		} else if (Std.is(secondObject, BitmapData)) {
			secondBMD = cast secondObject;
			rectB = secondBMD.rect.clone();
		} else throw new Error("Invalid secondObject. Must be Point, Rectangle or BitmapData.");
		
		rectA.x = firstPoint.x;
		rectA.y = firstPoint.y;
		if (secondBMD != null && secondPoint != null) {
			rectB.x = secondPoint.x;
			rectB.y = secondPoint.y;
		} else {
			secondPoint = firstPoint;
		}
		
		var intersectRect:Rectangle = rectA.intersection(rectB);
		var boundsOverlap:Bool = (intersectRect.width > 0 && intersectRect.height > 0);
		var hit:Bool = false;

		if (boundsOverlap) {
			var w:Int = Std.int(intersectRect.width);
			var h:Int = Std.int(intersectRect.height);
			
			// firstObject
			var xOffset:Float = intersectRect.x > rectA.x ? intersectRect.x - rectA.x : rectA.x - intersectRect.x;
			var yOffset:Float = intersectRect.y > rectA.y ? intersectRect.y - rectA.y : rectA.y - intersectRect.y;
			rectA.x += xOffset - firstPoint.x;
			rectA.y += yOffset - firstPoint.y;
			rectA.width = w;
			rectA.height = h;

			// secondObject
			xOffset = intersectRect.x > rectB.x ? intersectRect.x - rectB.x : rectB.x - intersectRect.x;
			yOffset = intersectRect.y > rectB.y ? intersectRect.y - rectB.y : rectB.y - intersectRect.y;
			rectB.x += xOffset - secondPoint.x;
			rectB.y += yOffset - secondPoint.y;
			rectB.width = w;
			rectB.height = h;
			
			var pixelsA:ByteArray = firstBMD.getPixels(rectA);
			var pixelsB:ByteArray = null;
			if (secondBMD != null) {
				pixelsB = secondBMD.getPixels(rectB);
				pixelsB.position = 0;
			}
			pixelsA.position = 0;
			
			var alphaA:Int = 0;
			var alphaB:Int = 0;
			var idx:Int = 0;
			for (y in 0...h) {
				for (x in 0...w) {
					idx = (y * w + x) << 2;
					alphaA = pixelsA[idx];
					alphaB = secondBMD != null ? pixelsB[idx] : 255;
					if (alphaA >= firstAlphaThreshold && alphaB >= secondAlphaThreshold) {
						hit = true;
						break; 
					}
				}
				if (hit) break;
			}
		}
		
		return hit;
	}
	
	
	// Mask information.
	/** @private */ private var _class:String;
	/** @private */ private var _check:Map<String, HitCallback>;
}
