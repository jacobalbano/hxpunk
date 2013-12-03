package net.hxpunk.masks;

import flash.display.BitmapData;
import net.hxpunk.HP;
import net.hxpunk.Graphic;
import net.hxpunk.Mask;
import net.hxpunk.masks.Grid;
import flash.display.Graphics;
import flash.geom.Point;
import net.hxpunk.utils.Draw;

/**
 * Uses circular area to determine collision.
 */
class Circle extends Hitbox
{
	/**
	 * Constructor.
	 * @param	radius		Radius of the circle.
	 * @param	x			X offset of the circle.
	 * @param	y			Y offset of the circle.
	 */
	public function new(radius:Int, x:Int = 0, y:Int = 0)
	{
		super(radius * 2, radius * 2, x, y);
		
		this.radius = radius;
		_x = x + radius;
		_y = y + radius;
		_fakePixelmask = new Pixelmask(new BitmapData(1, 1));

		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
		_check.set(Type.getClassName(Grid), collideGrid);
		_check.set(Type.getClassName(Pixelmask), collidePixelmask);
		_check.set(Type.getClassName(Circle), collideCircle);
	}

	/** @private Collides against an Entity. */
	override private function collideMask(other:Mask):Bool
	{
		var _otherHalfWidth:Float = other.parent.width * 0.5;
		var _otherHalfHeight:Float = other.parent.height * 0.5;
		
		var distanceX:Float = Math.abs(parent.x + _x - other.parent.x - _otherHalfWidth),
			distanceY:Float = Math.abs(parent.y + _y - other.parent.y - _otherHalfHeight);

		if (distanceX > _otherHalfWidth + radius || distanceY > _otherHalfHeight + radius)
		{
			return false;	// the hitbox/mask is too far away so return false
		}
		if (distanceX <= _otherHalfWidth || distanceY <= _otherHalfHeight)
		{
			return true;
		}
		var distanceToCorner:Float = (distanceX - _otherHalfWidth) * (distanceX - _otherHalfWidth)
			+ (distanceY - _otherHalfHeight) * (distanceY - _otherHalfHeight);

		return distanceToCorner <= _squaredRadius;
	}

	/** @private Collides against a Hitbox. */
	override private function collideHitbox(other:Hitbox):Bool
	{
		var _otherHalfWidth:Float = other._width * 0.5;
		var _otherHalfHeight:Float = other._height * 0.5;
		
		var distanceX:Float = Math.abs(parent.x + _x - other.parent.x - other._x - _otherHalfWidth),
			distanceY:Float = Math.abs(parent.y + _y - other.parent.y - other._y - _otherHalfHeight);

		if (distanceX > _otherHalfWidth + radius || distanceY > _otherHalfHeight + radius)
		{
			return false;	// the hitbox is too far away so return false
		}
		if (distanceX <= _otherHalfWidth || distanceY <= _otherHalfHeight)
		{
			return true;
		}
		var distanceToCorner:Float = (distanceX - _otherHalfWidth) * (distanceX - _otherHalfWidth)
			+ (distanceY - _otherHalfHeight) * (distanceY - _otherHalfHeight);

		return distanceToCorner <= _squaredRadius;
	}

	/** @private Collides against a Grid. */
	private function collideGrid(other:Grid):Bool
	{
		var thisX:Float = parent.x + _x,
			thisY:Float = parent.y + _y,
			otherX:Float = other.parent.x + other.x,
			otherY:Float = other.parent.y + other.y,
			entityDistX:Float = thisX - otherX,
			entityDistY:Float = thisY - otherY;

		var minx:Int = Math.floor((entityDistX - radius) / other.tileWidth),
			miny:Int = Math.floor((entityDistY - radius) / other.tileHeight),
			maxx:Int = Math.ceil((entityDistX + radius) / other.tileWidth),
			maxy:Int = Math.ceil((entityDistY + radius) / other.tileHeight);

		if (minx < 0) minx = 0;
		if (miny < 0) miny = 0;
		if (maxx > other.columns) maxx = other.columns;
		if (maxy > other.rows)    maxy = other.rows;

		var hTileWidth:Float = other.tileWidth * 0.5,
			hTileHeight:Float = other.tileHeight * 0.5,
			dx:Float, dy:Float;

		for (xx in minx...maxx)
		{
			for (yy in miny...maxy)
			{
				if (other.getTile(xx, yy))
				{
					var mx:Float = otherX + xx * other.tileWidth + hTileWidth,
						my:Float = otherY + yy * other.tileHeight + hTileHeight;

					dx = Math.abs(thisX - mx);

					if (dx > hTileWidth + radius)
						continue;

					dy = Math.abs(thisY - my);

					if (dy > hTileHeight + radius)
						continue;

					if (dx <= hTileWidth || dy <= hTileHeight)
						return true;

					var xCornerDist:Float = dx - hTileWidth;
					var yCornerDist:Float = dy - hTileHeight;

					if (xCornerDist * xCornerDist + yCornerDist * yCornerDist <= _squaredRadius)
						return true;
				}
			}
		}

		return false;
	}

	/**
	 * Checks for collision with a Pixelmask.
	 * May be slow (especially with big polygons), added for completeness sake.
	 * 
	 * Internally sets up a Pixelmask and uses that for collision check.
	 */
	@:access(net.hxpunk.masks.Pixelmask)
	private function collidePixelmask(pixelmask:Pixelmask):Bool
	{
		var data:BitmapData = _fakePixelmask._data;
		
		_fakePixelmask._x = _x - _radius;
		_fakePixelmask._y = _y - _radius;
		_fakePixelmask.parent = parent;
		
		_width = _height = _radius * 2;
		
		if (data == null || (data.width < _width || data.height < _height)) {
			data = new BitmapData(_width, height, true, 0);
		} else {
			data.fillRect(data.rect, 0);
		}
		
		var graphics:Graphics = HP.sprite.graphics;
		graphics.clear();

		graphics.beginFill(0xFFFFFF, 1);
		graphics.lineStyle(1, 0xFFFFFF, 1);
		
		graphics.drawCircle(_x + parent.originX, _y + parent.originY, _radius);
		
		graphics.endFill();

		data.draw(HP.sprite);
		
		_fakePixelmask.data = data;

		Draw.enqueueCall(function ():Void 
		{
			Draw.copyPixels(data, data.rect, new Point(50, 70));
		});
		
		return pixelmask.collide(_fakePixelmask);
	}

	/** @private Collides against a Circle. */
	private function collideCircle(other:Circle):Bool
	{
		var dx:Float = (parent.x + _x) - (other.parent.x + other._x);
		var dy:Float = (parent.y + _y) - (other.parent.y + other._y);
		return (dx * dx + dy * dy) < Math.pow(_radius + other._radius, 2);
	}

	override public function renderDebug(graphics:Graphics):Void
	{
		var sx:Float = HP.screen.scaleX * HP.screen.scale;
		var sy:Float = HP.screen.scaleY * HP.screen.scale;
		
		graphics.drawCircle((parent.x + _x - HP.camera.x) * sx, (parent.y + _y - HP.camera.y) * sy, radius * sx);
	}

	override private function get_x():Int { return _x - _radius; }

	override private function get_y():Int { return _y - _radius; }

	/**
	 * Radius.
	 */
	public var radius(get, set):Int;
	private inline function get_radius():Int { return _radius; }
	private function set_radius(value:Int):Int
	{
		if (_radius != value) {
			_radius = value;
			_squaredRadius = value * value;
			height = width = _radius + _radius;
			if (list != null) list.update();
			else if (parent != null) update();
		}
		return value;
	}

	/** Updates the parent's bounds for this mask. */
	override public function update():Void
	{
		if (parent != null)
		{
			// update entity bounds
			parent.originX = -_x + radius;
			parent.originY = -_y + radius;
			parent.height = parent.width = radius + radius;

			// update parent list
			if (list != null)
				list.update();
		}
	}

	// Hitbox information.
	private var _radius:Int;
	private var _squaredRadius:Int; 		// set automatically through the setter for radius
	private var _fakePixelmask:Pixelmask;	// used for Pixelmask collision
}