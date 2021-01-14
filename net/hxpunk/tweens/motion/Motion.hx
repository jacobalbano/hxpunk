package net.hxpunk.tweens.motion;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.HP.PointLike;
import net.hxpunk.Tween;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Base class for motion Tweens.
 */
class Motion extends Tween
{
	/**
	 * Constructor.
	 * @param	duration	Duration of the Tween.
	 * @param	complete	Optional completion callback.
	 * @param	type		Tween type.
	 * @param	ease		Optional easer function.
	 */
	public function new(duration:Float, complete:VoidCallback = null, type:TweenType = null, ease:EasingFunction = null) 
	{
		super(duration, type, complete, ease);
	}
	
	/**
	 * Current x position of the Tween.
	 */
	public var x(get, set):Float;
	private function get_x():Float { return _x; }
	private function set_x(value:Float):Float
	{
		_x = value;
		if (_object != null)
			_object.x = _x;
		return _x;
	}
	
	/**
	 * Current y position of the Tween.
	 */
	public var y(get, set):Float;
	private function get_y():Float { return _y; }
	private function set_y(value:Float):Float
	{
		_y = value;
		if (_object != null)
			_object.y = _y;
		return _y;
	}
	
	/**
	 * Target object for the tween. Must have an x and a y property.
	 */
	public var object(get, set):PointLike;
	private function get_object():PointLike { return _object; }
	private function set_object(value:PointLike):PointLike
	{
		_object = value;
		if (_object != null)
		{
			_object.x = _x;
			_object.y = _y;
		}
		return _object;
	}
	
	private var _x:Float = 0;
	private var _y:Float = 0;
	private var _object:PointLike;
}