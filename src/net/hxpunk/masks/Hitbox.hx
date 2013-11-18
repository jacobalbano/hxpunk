package net.hxpunk.masks;

import net.hxpunk.Mask;

	
/**
 * Uses parent's hitbox to determine collision. This class is used
 * internally by FlashPunk, you don't need to use this class because
 * this is the default behaviour of Entities without a Mask object.
 */
class Hitbox extends Mask
{
	/**
	 * Constructor.
	 * @param	width		Width of the hitbox.
	 * @param	height		Height of the hitbox.
	 * @param	x			X offset of the hitbox.
	 * @param	y			Y offset of the hitbox.
	 */
	public function new(width:Int = 1, height:Int = 1, x:Int = 0, y:Int = 0) 
	{
		super();
		_width = width;
		_height = height;
		_x = x;
		_y = y;
		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
	}
	
	/** @private Collides against an Entity. */
	override private function collideMask(other:Mask):Bool
	{
		return parent.x + _x + _width > other.parent.x - other.parent.originX
			&& parent.y + _y + _height > other.parent.y - other.parent.originY
			&& parent.x + _x < other.parent.x - other.parent.originX + other.parent.width
			&& parent.y + _y < other.parent.y - other.parent.originY + other.parent.height;
	}
	
	/** @private Collides against a Hitbox. */
	private function collideHitbox(other:Hitbox):Bool
	{
		return parent.x + _x + _width > other.parent.x + other._x
			&& parent.y + _y + _height > other.parent.y + other._y
			&& parent.x + _x < other.parent.x + other._x + other._width
			&& parent.y + _y < other.parent.y + other._y + other._height;
	}
	
	/**
	 * X offset.
	 */
	public var x(get, set):Int;
	private inline function get_x() { return _x; }
	private function set_x(value:Int):Int
	{
		if (_x == value) return value;
		_x = value;
		if (list != null) list.update();
		else if (parent != null) update();
		return value;
	}
	
	/**
	 * Y offset.
	 */
	public var y(get, set):Int;
	private inline function get_y() { return _y; }
	private function set_y(value:Int):Int
	{
		if (_y == value) return value;
		_y = value;
		if (list != null) list.update();
		else if (parent != null) update();
		return value;
	}
	
	/**
	 * Width.
	 */
	public var width(get, set):Int;
	private inline function get_width() { return _width; }
	private inline function set_width(value:Int):Int
	{
		if (Std.int(_width) == value) return value;
		_width = value;
		if (list != null) list.update();
		else if (parent != null) update();
		return value;
	}
	
	/**
	 * Height.
	 */
	public var height(get, set):Int;
	private inline function get_height() { return _height; }
	private inline function set_height(value:Int):Int
	{
		if (Std.int(_height) == value) return value;
		_height = value;
		if (list != null) list.update();
		else if (parent != null) update();
		return value;
	}
	
	/** @public Updates the parent's bounds for this mask. */
	override public function update():Void 
	{
		if (list != null)
		{
			// update parent list
			list.update();
		}
		else if (parent != null)
		{
			// update entity bounds
			parent.originX = -_x;
			parent.originY = -_y;
			parent.width = _width;
			parent.height = _height;
		}
	}
	
	// Hitbox information.
	private var _width:Int = 0;
	private var _height:Int = 0;
	private var _x:Int = 0;
	private var _y:Int = 0;
}
