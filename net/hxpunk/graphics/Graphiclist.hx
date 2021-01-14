package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.geom.Point;
import net.hxpunk.Graphic;
import net.hxpunk.HP;

/**
 * A Graphic that can contain multiple Graphics of one or various types.
 * Useful for drawing sprites with multiple different parts, etc.
 */
class Graphiclist extends Graphic
{
	/**
	 * Constructor.
	 * @param	graphic		Graphic objects to add to the list.
	 */
	public function new(graphics:Iterable<Graphic> = null) 
	{
		super();
		
		// init vars
		_graphics = new Array<Graphic>();
		_temp = new Array<Graphic>();
		_camera = new Point();

		if (graphics != null) for (g in graphics) add(g);
	}
	
	/** Updates the graphics in the list. */
	override public function update():Void 
	{
		for (g in _graphics)
		{
			if (g.active) g.update();
		}
	}
	
	/** Renders the Graphics in the list. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		point.x += x;
		point.y += y;
		camera.x *= scrollX;
		camera.y *= scrollY;
		for (g in _graphics)
		{
			if (g.visible)
			{
				if (g.relative)
				{
					_point.x = point.x;
					_point.y = point.y;
				}
				else _point.x = _point.y = 0;
				_camera.x = camera.x;
				_camera.y = camera.y;
				g.render(target, _point, _camera);
			}
		}
	}
	
	/**
	 * Adds the Graphic to the list.
	 * @param	graphic		The Graphic to add.
	 * @return	The added Graphic.
	 */
	public function add(graphic:Graphic):Graphic
	{
		_graphics[_count ++] = graphic;
		if (!active) active = graphic.active;
		return graphic;
	}
	
	/**
	 * Removes the Graphic from the list.
	 * @param	graphic		The Graphic to remove.
	 * @return	The removed Graphic.
	 */
	public function remove(graphic:Graphic):Graphic
	{
		if (HP.indexOf(_graphics, graphic) < 0) return graphic;
		
		HP.removeAll(_temp);
		
		for (g in _graphics)
		{
			if (g == graphic) _count --;
			else _temp[_temp.length] = g;
		}
		var temp:Array<Graphic> = _graphics;
		_graphics = _temp;
		_temp = temp;
		updateCheck();
		return graphic;
	}
	
	/**
	 * Removes the Graphic from the position in the list.
	 * @param	index		Index to remove.
	 */
	public function removeAt(index:Int = 0):Void
	{
		if (_graphics.length <= 0) return;
		index %= _graphics.length;
		remove(_graphics[index % _graphics.length]);
		updateCheck();
	}
	
	/**
	 * Removes all Graphics from the list.
	 */
	public function removeAll():Void
	{
		HP.removeAll(_graphics);
		HP.removeAll(_temp);
		count = 0;
		active = false;
	}
	
	/**
	 * All Graphics in this list.
	 */
	public var children(get, null):Array<Graphic>;
	private inline function get_children() { return _graphics; }
	
	/**
	 * Amount of Graphics in this list.
	 */
	public var count(get, null):Int;
	private inline function get_count() { return _count; }
	
	/**
	 * Check if the Graphiclist should update.
	 */
	private function updateCheck():Void
	{
		active = false;
		for (g in _graphics)
		{
			if (g.active)
			{
				active = true;
				return;
			}
		}
	}
	
	// List information.
	private var _graphics:Array<Graphic>;
	private var _temp:Array<Graphic>;
	private var _count:Int = 0;
	private var _camera:Point;
}
