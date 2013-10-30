package net.hxpunk.masks;

import flash.display.Graphics;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Hitbox;

/**
 * A Mask that can contain multiple Masks of one or various types.
 */
class Masklist extends Hitbox
{
	/**
	 * Constructor.
	 * @param	mask		Masks to add to the list.
	 */
	public function new(mask:Array<Mask>) 
	{
		super();
		
		_masks = new Array<Mask>();
		_temp = new Array<Mask>();

		for (m in mask) add(m);
	}
	
	/** @private Collide against a mask. */
	override public function collide(mask:Mask):Bool 
	{
		for (m in _masks)
		{
			if (m.collide(mask)) return true;
		}
		return false;
	}
	
	/** @private Collide against a Masklist. */
	override private function collideMasklist(other:Masklist):Bool 
	{
		for (a in _masks)
		{
			for (b in other._masks)
			{
				if (a.collide(b)) return true;
			}
		}
		return false;
	}
	
	/**
	 * Adds a Mask to the list.
	 * @param	mask		The Mask to add.
	 * @return	The added Mask.
	 */
	public function add(mask:Mask):Mask
	{
		_masks[_count ++] = mask;
		mask.list = this;
		mask.parent = parent;
		update();
		return mask;
	}
	
	/**
	 * Removes the Mask from the list.
	 * @param	mask		The Mask to remove.
	 * @return	The removed Mask.
	 */
	public function remove(mask:Mask):Mask
	{
		if (HP.indexOf(_masks, mask) < 0) return mask;
		
		HP.removeAll(_temp);
		for (m in _masks)
		{
			if (m == mask)
			{
				mask.list = null;
				mask.parent = null;
				_count --;
				update();
			}
			else _temp[_temp.length] = m;
		}
		var temp:Array<Mask> = _masks;
		_masks = _temp;
		_temp = temp;
		return mask;
	}
	
	/**
	 * Removes the Mask at the index.
	 * @param	index		The Mask index.
	 */
	public function removeAt(index:Int = 0):Void
	{
		HP.removeAll(_temp);
		
		var i:Int = _masks.length;
		index %= i;
		while (i -- > 0)
		{
			if (i == Std.int(index))
			{
				_masks[index].list = null;
				_count --;
				update();
			}
			else _temp[_temp.length] = _masks[index];
		}
		var temp:Array<Mask> = _masks;
		_masks = _temp;
		_temp = temp;
	}
	
	/**
	 * Removes all Masks from the list.
	 */
	public function removeAll():Void
	{
		for (m in _masks) m.list = null;
		
		HP.removeAll(_masks);
		HP.removeAll(_temp);

		_count = 0;
		update();
	}
	
	/**
	 * Gets a Mask from the list.
	 * @param	index		The Mask index.
	 * @return	The Mask at the index.
	 */
	public function getMask(index:Int = 0):Mask
	{
		return _masks[index % _masks.length];
	}
	
	override public function assignTo(parent:Entity):Void
	{
		for (m in _masks) m.parent = parent;
		super.assignTo(parent);
	}
	
	override public function update():Void 
	{
		// find bounds of the contained masks
		var t:Int = 0, l:Int = 0, r:Int = 0, b:Int = 0, h:Hitbox, i:Int = _count;
		while (i -- > 0)
		{
			if ((h = cast(_masks[i], Hitbox)) != null)
			{
				if (h._x < l) l = h._x;
				if (h._y < t) t = h._y;
				if (h._x + Std.int(h._width) > r) r = h._x + h._width;
				if (h._y + Std.int(h._height) > b) b = h._y + h._height;
			}
		}
		
		// update hitbox bounds
		_x = l;
		_y = t;
		_width = r - l;
		_height = b - t;
		super.update();
	}
	
	/** Used to render debug information in console. */
	public override function renderDebug(g:Graphics):Void
	{
		for (m in _masks) m.renderDebug(g);
	}
	
	/**
	 * Amount of Masks in the list.
	 */
	public var count(get, null):Int;
	private inline function get_count() { return _count; }
	
	// List information.
	/** @private */ private var _masks:Array<Mask>;
	/** @private */ private var _temp:Array<Mask>;
	/** @private */ private var _count:Int = 0;
}
