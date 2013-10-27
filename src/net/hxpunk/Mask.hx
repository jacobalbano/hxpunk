package net.hxpunk;

import flash.display.Graphics;
import net.hxpunk.masks.Masklist;


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
	
	// Mask information.
	/** @private */ private var _class:String;
	/** @private */ private var _check:Map<String, HitCallback>;
}
