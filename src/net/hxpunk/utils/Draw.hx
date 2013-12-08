package net.hxpunk.utils;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.display.IBitmapDrawable;
import flash.display.JointStyle;
import flash.display.LineScaleMode;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.Entity;
import net.hxpunk.Graphic;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.Mask;

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
	 * @param	target		The buffer to draw to (use null for HP.buffer).
	 * @param	camera		The camera offset (use null for none).
	 * @param	blend		The blend mode to use.
	 */
	public static function setTarget(target:BitmapData = null, camera:Point = null, blend:BlendMode = null):Void
	{
		_target = target != null ? target : HP.buffer;
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
	public static function line(x1:Float, y1:Float, x2:Float, y2:Float, color:Int = 0xFFFFFF, overwriteAlpha:Float = 1.0):Void
	{
		color = (Std.int(overwriteAlpha * 0xFF) << 24) | (color & 0xFFFFFF);
		
		// get the drawing positions
		var _x1:Int = Std.int(x1 - _camera.x);
		var _y1:Int = Std.int(y1 - _camera.y);
		var _x2:Int = Std.int(x2 - _camera.x);
		var _y2:Int = Std.int(y2 - _camera.y);
		
		// get the drawing difference
		var screen:BitmapData = _target,
			X:Float = Math.abs(_x2 - _x1),
			Y:Float = Math.abs(_y2 - _y1),
			xx:Int,
			yy:Int = 0;
		
		// draw a single pixel
		if (X == 0)
		{
			if (Y == 0)
			{
				screen.setPixel32(_x1, _y1, color);
				return;
			}
			// draw a straight vertical line
			yy = _y2 > _y1 ? 1 : -1;
			while (_y1 != _y2)
			{
				screen.setPixel32(_x1, _y1, color);
				_y1 += yy;
			}
			screen.setPixel32(_x2, _y2, color);
			return;
		}
		
		if (Y == 0)
		{
			// draw a straight horizontal line
			xx = _x2 > _x1 ? 1 : -1;
			while (_x1 != _x2)
			{
				screen.setPixel32(_x1, _y1, color);
				_x1 += xx;
			}
			screen.setPixel32(_x2, _y2, color);
			return;
		}
		
		xx = _x2 > _x1 ? 1 : -1;
		yy = _y2 > _y1 ? 1 : -1;
		var c:Float = 0,
			slope:Float = 0;
		
		if (X > Y)
		{
			slope = Y / X;
			c = .5;
			while (_x1 != _x2)
			{
				screen.setPixel32(_x1, _y1, color);
				_x1 += xx;
				c += slope;
				if (c >= 1)
				{
					_y1 += yy;
					c -= 1;
				}
			}
			screen.setPixel32(_x2, _y2, color);
		}
		else
		{
			slope = X / Y;
			c = .5;
			while (_y1 != _y2)
			{
				screen.setPixel32(_x1, _y1, color);
				_y1 += yy;
				c += slope;
				if (c >= 1)
				{
					_x1 += xx;
					c -= 1;
				}
			}
			screen.setPixel32(_x2, _y2, color);
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
		_graphics.endFill();
		
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
	 * @param	x			X position of the ellipse's center.
	 * @param	y			Y position of the ellipse's center.
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
	 * @param	x			X position.
	 * @param	y			Y position.
	 * @param	options		Options (see Text constructor).
	 */
	public static function text(text:String, x:Float = 0, y:Float = 0, options:Dynamic = null):Void
	{
		var textGfx:Text = new Text(text, x, y, options);

		textGfx.render(_target, HP.zero, _camera);
	}
	
	/**
	 * Draws a tiny rectangle centered at x, y.
	 * @param	x			The point's x.
	 * @param	y			The point's y.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @param	size		Size of the rectangle.
	 */
	public static function dot(x:Float, y:Float, color:Int=0xFFFFFF, alpha:Float = 1, size:Float = 3):Void 
	{
		x -= _camera.x;
		y -= _camera.y;

		var halfSize:Float = size / 2;
		Draw.rectPlus(x - halfSize + _camera.x, y - halfSize + _camera.y, size, size, color, alpha, false);
	}

	/**
	 * Draws a smooth, antialiased line with an arrow head at the ending point.
	 * @param	x1			Starting x position.
	 * @param	y1			Starting y position.
	 * @param	x2			Ending x position.
	 * @param	y2			Ending y position.
	 * @param	color		Color of the line.
	 * @param	alpha		Alpha of the line.
	 */
	public static function arrow(x1:Float, y1:Float, x2:Float, y2:Float, color:Int=0xFFFFFF, alpha:Float = 1):Void 
	{
		x1 -= _camera.x;
		y1 -= _camera.y;
		x2 -= _camera.x;
		y2 -= _camera.y;
		
		// temporarily set camera to zero, otherwise it will be reapplied in called functions
		var _savedCamera:Point = _camera;
		_camera = HP.zero;

		var lineAngleRad:Float = HP.angle(x1, y1, x2, y2) * HP.RAD;
		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		if (len == 0) return;
		
		var arrowStartX:Float = (len-5) * Math.cos(lineAngleRad);
		var arrowStartY:Float = (len-5) * Math.sin(lineAngleRad);
		HP.point.x = -dy;
		HP.point.y = dx;
		HP.point.normalize(1);
		
		Draw.linePlus(x1, y1, x2, y2, color, alpha);
		Draw.linePlus(x1 + arrowStartX + HP.point.x * 3, y1 + arrowStartY + HP.point.y * 3, x2, y2, color, alpha);
		Draw.linePlus(x1 + arrowStartX - HP.point.x * 3, y1 + arrowStartY - HP.point.y * 3, x2, y2, color, alpha);
		
		// restore camera
		_camera = _savedCamera;
	}
	
	/**
	 * Draws a smooth, antialiased line with optional arrow heads at the start and end point.
	 * @param	x1				Starting x position.
	 * @param	y1				Starting y position.
	 * @param	x2				Ending x position.
	 * @param	y2				Ending y position.
	 * @param	color			Color of the line.
	 * @param	alpha			Alpha of the line.
	 * @param	thick			Thickness of the line.
	 * @param	arrowAngle		Angle (in degrees) between the line and the arm of the arrow heads (defaults to 30).
	 * @param	arrowLength		Pixel length of each arm of the arrow heads.
	 * @param	arrowAtStart	Whether or not to draw and arrow head over the starting point.
	 * @param	arrowAtEnd		Whether or not to draw and arrow head over the ending point.
	 */
	public static function arrowPlus(x1:Float, y1:Float, x2:Float, y2:Float, color:Int = 0xFFFFFF, alpha:Float = 1, thick:Float = 1, arrowAngle:Float=30, arrowLength:Float=6, arrowAtStart:Bool = false, arrowAtEnd:Bool = true):Void
	{
		x1 -= _camera.x;
		y1 -= _camera.y;
		x2 -= _camera.x;
		y2 -= _camera.y;

		// temporarily set camera to zero, otherwise it will be reapplied in called functions
		var _savedCamera:Point = _camera;
		_camera = HP.zero;

		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		
		_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		
		linePlus(x1, y1, x2, y2, color, alpha, thick);
		
		var arrowAngleRad:Float = arrowAngle * HP.RAD;
		var dir:Point = HP.point;
		var normal:Point = HP.point2;
		
		dir.x = x2 - x1;
		dir.y = y2 - y1;
		normal.x = -dir.y;
		normal.y = dir.x;
		dir.normalize(1);
		normal.normalize(1);
		
		var orthoLen:Float = arrowLength * Math.sin(arrowAngleRad);
		var paralLen:Float = arrowLength * Math.cos(arrowAngleRad);
		
		if (arrowAtStart) {
			linePlus(x1 + paralLen * dir.x + orthoLen * normal.x, y1 + paralLen * dir.y + orthoLen * normal.y, x1, y1, color, alpha, thick);
			linePlus(x1 + paralLen * dir.x - orthoLen * normal.x, y1 + paralLen * dir.y - orthoLen * normal.y, x1, y1, color, alpha, thick);
		}
		
		if (arrowAtEnd) {
			linePlus(x2 - paralLen * dir.x + orthoLen * normal.x, y2 - paralLen * dir.y + orthoLen * normal.y, x2, y2, color, alpha, thick);
			linePlus(x2 - paralLen * dir.x - orthoLen * normal.x, y2 - paralLen * dir.y - orthoLen * normal.y, x2, y2, color, alpha, thick);
		}

		// restore camera
		_camera = _savedCamera;
	}
	
	/**
	 * Draws a circular arc (using lines) with an optional arrow head at the end point.
	 * @param	centerX			Center x of the arc.
	 * @param	centerY			Center y of the arc.
	 * @param	radius			Radius of the arc.
	 * @param	startAngle		Starting angle (in degrees) of the arc.
	 * @param	spanAngle		Angular span (in degrees) of the arc.
	 * @param	color			Color of the arc.
	 * @param	alpha			Alpha of the arc.
	 * @param	drawArrow		Whether or not to draw an arrow head over the ending point.
	 */
	public static function arc(centerX:Float, centerY:Float, radius:Float, startAngle:Float, spanAngle:Float, color:Int = 0xFFFFFF, alpha:Float = 1, drawArrow:Bool = false):Void 
	{
		centerX -= _camera.x;
		centerY -= _camera.y;
		
		// temporarily set camera to zero, otherwise it will be reapplied in called functions
		var _savedCamera:Point = _camera;
		_camera = HP.zero;

		var startAngleRad:Float = startAngle * HP.RAD;
		var spanAngleRad:Float;
		
		// adjust angles if |span| > 360
		if (Math.abs(spanAngle) > 360) {
			startAngleRad += (spanAngle % 360) * HP.RAD;
			spanAngleRad = -HP.sign(spanAngle) * Math.PI * 2;
		} else {
			spanAngleRad = spanAngle * HP.RAD;
		}

		var steps:Int = Std.int(Math.abs(spanAngleRad) * 10);
		steps = steps > 0 ? steps : 1;
		var angleStep:Float = spanAngleRad / steps;
		
		var x1:Float = centerX + Math.cos(startAngleRad) * radius;
		var y1:Float = centerY + Math.sin(startAngleRad) * radius;
		var x2:Float;
		var y2:Float;
		
		for (i in 0...steps) {
			var angle:Float = startAngleRad + (i+1) * angleStep;
			x2 = centerX + Math.cos(angle) * radius;
			y2 = centerY + Math.sin(angle) * radius;
			if (i == (steps-1) && drawArrow)
				arrow(x1, y1, x2, y2, color, alpha);
			else
				Draw.linePlus(x1, y1, x2, y2, color, alpha);
			x1 = x2;
			y1 = y2;
		}

		// restore camera
		_camera = _savedCamera;
	}
	
	/**
	 * Draws a circular arc (using bezier curves) with an optional arrow head on the end point and other optional values.
	 * @param	centerX			Center x of the arc.
	 * @param	centerY			Center y of the arc.
	 * @param	radius			Radius of the arc.
	 * @param	startAngle		Starting angle (in degrees) of the arc.
	 * @param	spanAngle		Angular span (in degrees) of the arc.
	 * @param	color			Color of the arc.
	 * @param	alpha			Alpha of the arc.
	 * @param	fill			If the arc should be filled with the color (true) or just an outline (false).
	 * @param	thick			Thickness of the outline (only applicable when fill = false).
	 * @param	drawArrow		Whether or not to draw an arrow head over the ending point.
	 */
	public static function arcPlus(centerX:Float, centerY:Float, radius:Float, startAngle:Float, spanAngle:Float, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1, drawArrow:Bool = false):Void
	{
		centerX -= _camera.x;
		centerY -= _camera.y;
		
		// temporarily set camera to zero, otherwise it will be reapplied in called functions
		var _savedCamera:Point = _camera;
		_camera = HP.zero;

		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		
		var startAngleRad:Float = startAngle * HP.RAD;
		var spanAngleRad:Float;
		
		// adjust angles if |span| > 360
		if (Math.abs(spanAngle) > 360) {
			startAngleRad += (spanAngle % 360) * HP.RAD;
			spanAngleRad = -HP.sign(spanAngle) * Math.PI * 2;
		} else {
			spanAngleRad = spanAngle * HP.RAD;
		}

		var steps:Int = Math.floor(Math.abs(spanAngleRad / (Math.PI / 4))) + 1;
		var angleStep:Float = spanAngleRad / (2 * steps);
		var controlRadius:Float = radius / Math.cos(angleStep);

		var startX:Float = centerX + Math.cos(startAngleRad) * radius;
		var startY:Float = centerY + Math.sin(startAngleRad) * radius;
		
		if (fill) {
			_graphics.beginFill(color, alpha);
			_graphics.moveTo(centerX, centerY);
			_graphics.lineTo(startX, startY);
		} else {
			_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
			_graphics.moveTo(startX, startY);
		}

		var endAngleRad:Float = 0;
		var controlPoint:Point = HP.point;
		var anchorPoint:Point = HP.point2;

		for (i in 0...steps)
		{
			endAngleRad = startAngleRad + angleStep;
			startAngleRad = endAngleRad + angleStep;
			
			controlPoint.x = centerX + Math.cos(endAngleRad) * controlRadius;
			controlPoint.y = centerY + Math.sin(endAngleRad) * controlRadius;
			
			anchorPoint.x = centerX + Math.cos(startAngleRad) * radius;
			anchorPoint.y = centerY + Math.sin(startAngleRad) * radius;
			
			_graphics.curveTo(controlPoint.x, controlPoint.y, anchorPoint.x, anchorPoint.y);
		}
		
		if (fill) _graphics.lineTo(centerX, centerY);
		
		HP.matrix.identity();
		HP.matrix.translate(-_camera.x, -_camera.y);
		_target.draw(HP.sprite, HP.matrix, null, blend);
		
		if (drawArrow) {
			HP.point.x = anchorPoint.x - centerX;
			HP.point.y = anchorPoint.y - centerY;
			HP.point.normalize(1);
			Draw.arrowPlus(anchorPoint.x + HP.sign(angleStep) * HP.point.y, anchorPoint.y - HP.sign(angleStep) * HP.point.x, anchorPoint.x, anchorPoint.y, color, alpha, thick);
		}

		// restore camera
		_camera = _savedCamera;
	}
		
	/**
	 * Draws a rotated rectangle (with optional pivot point).
	 * @param	x			X position of the rectangle.
	 * @param	y			Y position of the rectangle.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @param	fill		If the rectangle should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @param	radius		Round rectangle corners by this amount.
	 * @param	angle		Rotation of the rectangle (in degrees).
	 * @param	pivotX		X position around which the rotation should be performed (defaults to 0).
	 * @param	pivotY		Y position around which the rotation should be performed (defaults to 0).
	 */
	public static function rotatedRect(x:Float, y:Float, width:Float, height:Float, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Float = 1, radius:Float = 0, angle:Float=0, pivotX:Float=0, pivotY:Float=0):Void
	{
		x -= _camera.x;
		y -= _camera.y;
		
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		
		if (fill) {
			_graphics.beginFill(color, alpha);
		} else {
			_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		}
		
		if (radius <= 0) {
			_graphics.drawRect(0, 0, width, height);
		} else {
			_graphics.drawRoundRect(0, 0, width, height, radius);
		}
		
		var angleRad:Float = angle * HP.RAD;
		HP.matrix.identity();
		HP.matrix.translate(-pivotX, -pivotY);
		HP.matrix.rotate(angleRad);
		HP.matrix.tx += x;
		HP.matrix.ty += y;

		_target.draw(HP.sprite, HP.matrix, null, blend);
	}

	/**
	 * Draws a polygon (or a polyline with closed = false) from an array of points.
	 * @param	x			X position of the poly.
	 * @param	y			Y position of the poly.
	 * @param	points		Array containing the poly's points.
	 * @param	color		Color of the poly.
	 * @param	alpha		Alpha of the poly.
	 * @param	fill		If the poly should be filled with the color (true) or just an outline (false).
	 * @param	closed		If the poly should be closed (true) or a polyline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 */
	public static function poly(x:Float, y:Float, points:Array<Point>, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, closed:Bool = true, thick:Float = 1):Void
	{
		x -= _camera.x;
		y -= _camera.y;
		
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		_graphics.clear();
		
		fill = fill && closed;
		if (fill) {
			_graphics.beginFill(color, alpha);
		} else {
			_graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
		}
		
		if (closed) _graphics.moveTo(points[points.length - 1].x, points[points.length - 1].y);
		else _graphics.moveTo(points[0].x, points[0].y);
		for (p in points)
		{
			_graphics.lineTo(p.x, p.y);
		}
		if (fill) _graphics.endFill();
		
		var matrix:Matrix = HP.matrix;
		matrix.identity();
		matrix.translate(x, y);

		_target.draw(HP.sprite, matrix, null, blend);
	}

	/**
	 * Draws the source display object onto the current target (doesn't use camera).
	 * 
	 * @see BitmapData.draw()
	 * 
	 * @param	source				The display object or BitmapData to draw onto the current target.
	 * @param	matrix				A Matrix object used to scale, rotate, or translate the coordinates of the bitmap.
	 * @param	colorTransform		A ColorTransform object that you use to adjust the color values of the bitmap.
	 * @param	blendMode			The blend mode to be applied to the resulting bitmap.
	 * @param	clipRect			A Rectangle object that defines the area of the source object to draw (don't trust this - AS3 docs are wrong!).
	 * @param	smoothing			Whether the source object has to be smoothed when scaled or rotated.
	 */
	public static function draw(source:IBitmapDrawable, ?matrix:Matrix, ?colorTransform:ColorTransform, ?blendMode:BlendMode, ?clipRect:Rectangle, smoothing:Bool = false):Void
	{
		return _target.draw(source, matrix, colorTransform, blendMode != null ? blendMode : blend, clipRect, smoothing);
	}
	
	/**
	 * Copies a rectangular area of a source image to a rectangular area of the same size at the destination point of the current target (doesn't use camera).
	 * 
	 * @see BitmapData.copyPixels()
	 * 
	 * @param	source				The input bitmap image from which to copy pixels.
	 * @param	sourceRect			A rectangle that defines the area of the source image to use as input.
	 * @param	destPoint			The destination point that represents the upper-left corner of the rectangular area where the new pixels are placed.
	 * @param	alphaBitmapData		A secondary, alpha BitmapData object source.
	 * @param	alphaPoint			The point in the alpha BitmapData object source that corresponds to the upper-left corner of the sourceRect parameter.
	 * @param	mergeAlpha			To use the alpha channel, set the value to true. To copy pixels with no alpha channel, set the value to false.
	 */
	public static function copyPixels(source:BitmapData, ?sourceRect:Rectangle, ?destPoint:Point, ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false) : Void
	{
		return _target.copyPixels(source, sourceRect != null ? sourceRect : source.rect, destPoint != null ? destPoint : HP.zero, alphaBitmapData, alphaPoint, mergeAlpha); 
	}
	
	/**
	 * Enqueues a call to a function to be executed at the end of the next render step. 
	 * Useful to debug draw directly from the update step, rather than having to override the render method.
	 * 
	 * Ex.:
	 * Draw.enqueueCall(function():Void {
	 *     Draw.line(player.x, player.y, enemy.x, enemy.y);
	 * });
	 * 
	 * 
	 * @param	method		The function to be enqueued.
	 */
	public static function enqueueCall(method:Dynamic):Void
	{
		if (_callQueue == null) _callQueue = new Array<Dynamic>();
		
		if (Reflect.isFunction(method))
			_callQueue.push(method);
		else	
			throw new Error("[method] must be a function.");
	}
	
	/**
	 * Executes all the functions enqueued with Draw.enqueueCall() and clears the queue (called from World.render()).
	 */
	public static function renderCallQueue():Void 
	{
		if (_callQueue == null) return;
		
		var len:Int = _callQueue.length;
		for (i in 0...len) {
			var func:Dynamic = _callQueue[i];
			if (Reflect.isFunction(func)) func();
		}
		HP.removeAll(_callQueue);
	}
	
	// Drawing information.
	private static var _target:BitmapData;
	private static var _camera:Point;
	private static var _graphics:Graphics = HP.sprite.graphics;
	private static var _rect:Rectangle = HP.rect;
	private static var _callQueue:Array<Dynamic>;
}