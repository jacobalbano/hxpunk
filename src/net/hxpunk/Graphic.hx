package net.hxpunk;

import flash.display.BitmapData;
import flash.geom.Point;
import haxe.macro.Expr.Function;

/**
 * Base class for all graphical types that can be drawn by Entity.
 */
class Graphic
{
	/**
	 * If the graphic should update.
	 */
	public var active:Bool = false;
	
	/**
	 * If the graphic should render.
	 */
	public var visible:Bool = true;
	
	/**
	 * X offset.
	 */
	public var x:Float = 0;
	
	/**
	 * Y offset.
	 */
	public var y:Float = 0;
	
	/**
	 * X scrollfactor, effects how much the camera offsets the drawn graphic.
	 * Can be used for parallax effect, eg. Set to 0 to follow the camera,
	 * 0.5 to move at half-speed of the camera, or 1 (default) to stay still.
	 */
	public var scrollX:Float = 1;
	
	/**
	 * Y scrollfactor, effects how much the camera offsets the drawn graphic.
	 * Can be used for parallax effect, eg. Set to 0 to follow the camera,
	 * 0.5 to move at half-speed of the camera, or 1 (default) to stay still.
	 */
	public var scrollY:Float = 1;
	
	/**
	 * If the graphic should render at its position relative to its parent Entity's position.
	 */
	public var relative:Bool = true;
	
	/**
	 * Constructor.
	 */
	public function new() 
	{
		_point = new Point();
	}
	
	/**
	 * Updates the graphic.
	 */
	public function update():Void
	{
		
	}
	
	/**
	 * Renders the graphic to the screen buffer.
	 * @param	target		The buffer to draw to.
	 * @param	point		The position to draw the graphic.
	 * @param	camera		The camera offset.
	 */
	public function render(target:BitmapData, point:Point, camera:Point):Void
	{
		
	}
	
	/** @private Callback for when the graphic is assigned to an Entity. */
	public var assign(get, set):Void -> Void;
	private function get_assign() { return _assign; }
	private function set_assign(value:Void -> Void) { return _assign = value; }
	
	// Graphic information.
	/** @private */ public var _assign:Void -> Void;
	/** @private */ private var _point:Point;
}
