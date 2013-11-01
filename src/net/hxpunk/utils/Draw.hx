package net.hxpunk.utils;

import flash.display.*;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.IBitmapDrawable;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Entity;
import net.hxpunk.Graphic;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;

/**
 * Static class with access to miscellaneous drawing functions.
 * These functions are not meant to replace Graphic components
 * for Entities, but rather to help with testing and debugging.
 */
class Draw 
{
	/**
	 * The blending mode used by Draw functions. This will not
	 * apply to Draw.line() or Draw.circle(), but will apply
	 * to Draw.linePlus() and Draw.circlePlus().
	 */
	public static var blend:BlendMode;
	
	/**
	 * Sets the drawing target for Draw functions.
	 * @param	target		The buffer to draw to.
	 * @param	camera		The camera offset (use null for none).
	 * @param	blend		The blend mode to use.
	 */
	public static function setTarget(target:BitmapData, camera:Point = null, blend:BlendMode = null):Void
	{
		_target = target;
		_camera = camera != null ? camera : HP.zero;
		Draw.blend = blend;
	}
	
	/**
	 * Resets the drawing target to the default. The same as calling Draw.setTarget(HP.buffer, HP.camera).
	 */
	public static function resetTarget():Void
	{
		_target = HP.buffer;
		_camera = HP.camera;
		Draw.blend = null;
	}
	
	/**
	 * Draws a pixelated, non-antialiased line.
	 * @param	x1				Starting x position.
	 * @param	y1				Starting y position.
	 * @param	x2				Ending x position.
	 * @param	y2				Ending y position.
	 * @param	color			Color of the line.
	 * @param	overwriteAlpha	Alpha value written to these pixels: does NOT do blending. If you want to draw a semi-transparent line over some other content, you will have to either: A) use Draw.linePlus() or B) if non-antialiasing is important, render with Draw.line() to an intermediate buffer with transparency and then render that intermediate buffer.
	 */
	public static function line(x1:Int, y1:Int, x2:Int, y2:Int, color:Int = 0xFFFFFF, overwriteAlpha:Float = 1.0):Void
	{
		color = (Std.int(overwriteAlpha * 0xFF) << 24) | (color & 0xFFFFFF);
		
		// get the drawing positions
		x1 -= Std.int(_camera.x);
		y1 -= Std.int(_camera.y);
		x2 -= Std.int(_camera.x);
		y2 -= Std.int(_camera.y);
		
		// get the drawing difference
		var screen:BitmapData = _target,
			X:Float = Math.abs(x2 - x1),
			Y:Float = Math.abs(y2 - y1),
			xx:Int,
			yy:Int = 0;
		
		// draw a single pixel
		if (X == 0)
		{
			if (Y == 0)
			{
				screen.setPixel32(x1, y1, color);
				return;
			}
			// draw a straight vertical line
			yy = y2 > y1 ? 1 : -1;
			while (y1 != y2)
			{
				screen.setPixel32(x1, y1, color);
				y1 += yy;
			}
			screen.setPixel32(x2, y2, color);
			return;
		}
		
		if (Y == 0)
		{
			// draw a straight horizontal line
			xx = x2 > x1 ? 1 : -1;
			while (x1 != x2)
			{
				screen.setPixel32(x1, y1, color);
				x1 += xx;
			}
			screen.setPixel32(x2, y2, color);
			return;
		}
		
		xx = x2 > x1 ? 1 : -1;
		yy = y2 > y1 ? 1 : -1;
		var c:Float = 0,
			slope:Float = 0;
		
		if (X > Y)
		{
			slope = Y / X;
			c = .5;
			while (x1 != x2)
			{
				screen.setPixel32(x1, y1, color);
				x1 += xx;
				c += slope;
				if (c >= 1)
				{
					y1 += yy;
					c -= 1;
				}
			}
			screen.setPixel32(x2, y2, color);
		}
		else
		{
			slope = X / Y;
			c = .5;
			while (y1 != y2)
			{
				screen.setPixel32(x1, y1, color);
				y1 += yy;
				c += slope;
				if (c >= 1)
				{
					x1 += xx;
					c -= 1;
				}
			}
			screen.setPixel32(x2, y2, color);
		}
	}
	
	/**
	 * Draws a smooth, antialiased line with optional alpha and thickness.
	 * @param	x1		Starting x position.
	 * @param	y1		Starting y position.
	 * @param	x2		Ending x position.
	 * @param	y2		Ending y position.
	 * @param	color	Color of the line.
	 * @param	alpha	Alpha of the line.
	 * @param	thick	The thickness of the line.
	 */
	public static function linePlus(x1:Float, y1:Float, x2:Float, y2:Float, color:Int = 0xFF000000, alpha:Float = 1, thick:Float = 1):Void
	{
		_graphics.clear();
		_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NONE);
		_graphics.moveTo(x1 - _camera.x, y1 - _camera.y);
		_graphics.lineTo(x2 - _camera.x, y2 - _camera.y);
		_target.draw(HP.sprite, null, null, blend);
	}
	
	/**
	 * Draws a filled rectangle.
	 * @param	x			X position of the rectangle.
	 * @param	y			Y position of the rectangle.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @param	overwrite	If the color/alpha provided should replace the existing data rather than blend.
	 */
	public static function rect(x:Float, y:Float, width:Float, height:Float, color:Int = 0xFFFFFF, alpha:Float = 1, overwrite:Bool = false):Void
	{
		if (! overwrite && (alpha < 1 || blend != null)) {
			_graphics.clear();
			_graphics.beginFill(color & 0xFFFFFF, alpha);
			_graphics.drawRect(x - _camera.x, y - _camera.y, width, height);
			_target.draw(HP.sprite, null, null, blend);
			return;
		}
		
		color = (Std.int(alpha * 0xFF) << 24) | (color & 0xFFFFFF);
		_rect.x = x - _camera.x;
		_rect.y = y - _camera.y;
		_rect.width = width;
		_rect.height = height;
		_target.fillRect(_rect, color);
	}
	
	/**
	 * Draws a rectangle.
	 * @param	x			X position of the rectangle.
	 * @param	y			Y position of the rectangle.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @param	fill		If the rectangle should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @param	radius		Round rectangle corners by this amount.
	 */
	public static function rectPlus(x:Float, y:Float, width:Float, height:Float, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1, radius:Float = 0):Void
	{
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		
		if (fill) {
			_graphics.beginFill(color, alpha);
		} else {
			_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		}
		
		if (radius <= 0) {
			_graphics.drawRect(x - _camera.x, y - _camera.y, width, height);
		} else {
			_graphics.drawRoundRect(x - _camera.x, y - _camera.y, width, height, radius);
		}
		
		_target.draw(HP.sprite, null, null, blend);
	}
	
	/**
	 * Draws a non-filled, pixelated circle.
	 * @param	x			Center x position.
	 * @param	y			Center y position.
	 * @param	radius		Radius of the circle.
	 * @param	color		Color of the circle.
	 */
	public static function circle(x:Int, y:Int, radius:Int, color:Int = 0xFFFFFF):Void
	{
		if (Std.int(color) < 0xFF000000) color = 0xFF000000 | color;
		x -= Std.int(_camera.x);
		y -= Std.int(_camera.y);
		var f:Int = 1 - radius,
			fx:Int = 1,
			fy:Int = -2 * radius,
			xx:Int = 0,
			yy:Int = radius;
		_target.setPixel32(x, y + radius, color);
		_target.setPixel32(x, y - radius, color);
		_target.setPixel32(x + radius, y, color);
		_target.setPixel32(x - radius, y, color);
		while (xx < yy)
		{
			if (f >= 0) 
			{
				yy --;
				fy += 2;
				f += fy;
			}
			xx ++;
			fx += 2;
			f += fx;    
			_target.setPixel32(x + xx, y + yy, color);
			_target.setPixel32(x - xx, y + yy, color);
			_target.setPixel32(x + xx, y - yy, color);
			_target.setPixel32(x - xx, y - yy, color);
			_target.setPixel32(x + yy, y + xx, color);
			_target.setPixel32(x - yy, y + xx, color);
			_target.setPixel32(x + yy, y - xx, color);
			_target.setPixel32(x - yy, y - xx, color);
		}
	}
	
	/**
	 * Draws a circle to the screen.
	 * @param	x			X position of the circle's center.
	 * @param	y			Y position of the circle's center.
	 * @param	radius		Radius of the circle.
	 * @param	color		Color of the circle.
	 * @param	alpha		Alpha of the circle.
	 * @param	fill		If the circle should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 */
	public static function circlePlus(x:Float, y:Float, radius:Float, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1):Void
	{
		_graphics.clear();
		if (fill)
		{
			_graphics.beginFill(color & 0xFFFFFF, alpha);
			_graphics.drawCircle(x - _camera.x, y - _camera.y, radius);
			_graphics.endFill();
		}
		else
		{
			_graphics.lineStyle(thick, color & 0xFFFFFF, alpha);
			_graphics.drawCircle(x - _camera.x, y - _camera.y, radius);
		}
		_target.draw(HP.sprite, null, null, blend);
	}

	/**
	 * Draws an ellipse to the screen.
	 * @param	x		X position of the ellipse's center.
	 * @param	y		Y position of the ellipse's center.
	 * @param	width		Width of the ellipse.
	 * @param	height		Height of the ellipse.
	 * @param	color		Color of the ellipse.
	 * @param	alpha		Alpha of the ellipse.
	 * @param	fill		If the ellipse should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @param	angle		What angle (in degrees) the ellipse should be rotated.
	 */
	public static function ellipse(x:Float, y:Float, width:Float, height:Float, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1, angle:Float = 0):Void
	{
		_graphics.clear();
		if (fill)
		{
			_graphics.beginFill(color & 0xFFFFFF, alpha);
			_graphics.drawEllipse(-width / 2, -height / 2, width, height);
			_graphics.endFill();
		}
		else
		{
			_graphics.lineStyle(thick, color & 0xFFFFFF, alpha);
			_graphics.drawEllipse(-width / 2, -height / 2, width, height);
		}
		var m:Matrix = new Matrix();
		m.rotate(angle * HP.RAD);
		m.translate(x - _camera.x, y - _camera.y);
		_target.draw(HP.sprite, m, null, blend);
	}
	
	/**
	 * Draws the Entity's hitbox.
	 * @param	e			The Entity whose hitbox is to be drawn.
	 * @param	outline		If just the hitbox's outline should be drawn.
	 * @param	color		Color of the hitbox.
	 * @param	alpha		Alpha of the hitbox.
	 */
	public static function hitbox(e:Entity, outline:Bool = true, color:Int = 0xFFFFFF, alpha:Float = 1):Void
	{
		if (outline)
		{
			if (Std.int(color) < 0xFF000000) color = 0xFF000000 | color;
			var x:Int = Std.int(e.x - e.originX - _camera.x),
				y:Int = Std.int(e.y - e.originY - _camera.y);
			_rect.x = x;
			_rect.y = y;
			_rect.width = e.width;
			_rect.height = 1;
			_target.fillRect(_rect, color);
			_rect.y += e.height - 1;
			_target.fillRect(_rect, color);
			_rect.y = y;
			_rect.width = 1;
			_rect.height = e.height;
			_target.fillRect(_rect, color);
			_rect.x += e.width - 1;
			_target.fillRect(_rect, color);
			return;
		}
		if (alpha >= 1 && blend == null)
		{
			if (Std.int(color) < 0xFF000000) color = 0xFF000000 | color;
			_rect.x = e.x - e.originX - _camera.x;
			_rect.y = e.y - e.originY - _camera.y;
			_rect.width = e.width;
			_rect.height = e.height;
			_target.fillRect(_rect, color);
			return;
		}
		if (Std.int(color) > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		_graphics.beginFill(color, alpha);
		_graphics.drawRect(e.x - e.originX - _camera.x, e.y - e.originY - _camera.y, e.width, e.height);
		_target.draw(HP.sprite, null, null, blend);
	}
	
	/**
	 * Draws a quadratic curve.
	 * @param	x1		X start.
	 * @param	y1		Y start.
	 * @param	x2		X control point, used to determine the curve.
	 * @param	y2		Y control point, used to determine the curve.
	 * @param	x3		X finish.
	 * @param	y3		Y finish.
	 * @param	color	Color of the curve
	 * @param	alpha	Alpha transparency.
	 */
	public static function curve(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, color:Int = 0, alpha:Float = 1, thick:Float = 1):Void
	{
		_graphics.clear();
		_graphics.lineStyle(thick, color & 0xFFFFFF, alpha);
		_graphics.moveTo(x1 - _camera.x, y1 - _camera.y);
		_graphics.curveTo(x2 - _camera.x, y2 - _camera.y, x3 - _camera.x, y3 - _camera.y);
		_target.draw(HP.sprite, null, null, blend);
	}
	
	/**
	 * Draws a graphic object.
	 * @param	g		The Graphic to draw.
	 * @param	x		X position.
	 * @param	y		Y position.
	 */
	public static function graphic(g:Graphic, x:Float = 0, y:Float = 0):Void
	{
		if (g.visible)
		{
			if (g.relative)
			{
				HP.point.x = x;
				HP.point.y = y;
			}
			else HP.point.x = HP.point.y = 0;
			HP.point2.x = _camera.x;
			HP.point2.y = _camera.y;
			g.render(_target, HP.point, HP.point2);
		}
	}
	
	/**
	 * Draws an Entity object.
	 * @param	e					The Entity to draw.
	 * @param	x					X position.
	 * @param	y					Y position.
	 * @param	addEntityPosition	Adds the Entity's x and y position to the target position.
	 */
	public static function entity(e:Entity, x:Int = 0, y:Int = 0, addEntityPosition:Bool = false):Void
	{
		if (e.visible && e.graphic != null)
		{
			if (addEntityPosition) graphic(e.graphic, x + e.x, y + e.y);
			else graphic(e.graphic, x, y);
		}
	}

	/**
	 * Draws text.
	 * @param	text		The text to render.
	 * @param	x		X position.
	 * @param	y		Y position.
	 * @param	options		Options (see Text constructor).
	 */
	public static function text(text:String, x:Float = 0, y:Float = 0, options:Dynamic = null):Void
	{
		var textGfx:Text = new Text(text, x, y, options);

		textGfx.render(_target, HP.zero, _camera);
	}
	
	private static function draw(source:IBitmapDrawable, ?matrix:Matrix, ?colorTransform:ColorTransform, ?blendMode:BlendMode, ?clipRect:Rectangle, smoothing:Bool = false):Void
	{
		return _target.draw(source, matrix, colorTransform, blendMode != null ? blendMode : blend, clipRect, smoothing);
	}
	
	private static function copyPixels(source:BitmapData, ?sourceRect:Rectangle, ?destPoint:Point, ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false) : Void
	{
		return _target.copyPixels(source, sourceRect != null ? sourceRect : source.rect, destPoint != null ? destPoint : HP.zero, alphaBitmapData, alphaPoint, mergeAlpha); 
	}
	
	public static function enqueueCall(method:String, args:Array<Dynamic> = null):Void
	{
		if (_callQueue == null) _callQueue = new Array<CallMethod>();
		_callQueue.push(new CallMethod(method, args != null ? args : []));
	}
	
	public static function renderQueue():Void 
	{
		if (_callQueue == null) return;
		
		var len:Int = _callQueue.length;
		for (i in 0...len) {
			trace("calls in queue");
			var callMethod:CallMethod = _callQueue[i];
			Reflect.callMethod(Draw, Reflect.field(Draw, callMethod.name), callMethod.args);
		}
		HP.removeAll(_callQueue);
	}
	
	// Drawing information.
	/** @private */ private static var _target:BitmapData;
	/** @private */ private static var _camera:Point;
	/** @private */ private static var _graphics:Graphics = HP.sprite.graphics;
	/** @private */ private static var _rect:Rectangle = HP.rect;
	
	private static var _callQueue:Array<CallMethod>;
}

class CallMethod {
	public var name:String;
	public var args:Array<Dynamic>;
	
	public function new(methodName:String, args:Array<Dynamic>)
	{
		this.name = methodName;
		this.args = args;
	}
}