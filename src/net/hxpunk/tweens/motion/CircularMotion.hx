package net.hxpunk.tweens.motion;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.HP;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Determines a circular motion.
 */
class CircularMotion extends Motion
{
	/**
	 * Constructor.
	 * @param	complete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(complete:VoidCallback = null, type:TweenType = null)
	{
		super(0, complete, type, null);
	}
	
	/**
	 * Starts moving along a circle.
	 * @param	centerX		X position of the circle's center.
	 * @param	centerY		Y position of the circle's center.
	 * @param	radius		Radius of the circle.
	 * @param	angle		Starting position on the circle.
	 * @param	clockwise	If the motion is clockwise.
	 * @param	duration	Duration of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotion(centerX:Float, centerY:Float, radius:Float, angle:Float, clockwise:Bool, duration:Float, ease:EasingFunction = null):Void
	{
		_centerX = centerX;
		_centerY = centerY;
		_radius = radius;
		_angle = _angleStart = angle * HP.RAD;
		_angleFinish = _CIRC * (clockwise ? 1 : -1);
		_target = duration;
		_ease = ease;
		start();
	}
	
	/**
	 * Starts moving along a circle at the speed.
	 * @param	centerX		X position of the circle's center.
	 * @param	centerY		Y position of the circle's center.
	 * @param	radius		Radius of the circle.
	 * @param	angle		Starting position on the circle.
	 * @param	clockwise	If the motion is clockwise.
	 * @param	speed		Speed of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotionSpeed(centerX:Float, centerY:Float, radius:Float, angle:Float, clockwise:Bool, speed:Float, ease:EasingFunction = null):Void
	{
		_centerX = centerX;
		_centerY = centerY;
		_radius = radius;
		_angle = _angleStart = angle * HP.RAD;
		_angleFinish = _CIRC * (clockwise ? 1 : -1);
		_target = (_radius * _CIRC) / speed;
		_ease = ease;
		start();
	}
	
	/** @private Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		_angle = _angleStart + _angleFinish * _t;
		x = _centerX + Math.cos(_angle) * _radius;
		y = _centerY + Math.sin(_angle) * _radius;
	}
	
	/**
	 * The current position on the circle.
	 */
	public var angle(get, null):Float;
	private function get_angle():Float { return _angle; }
	
	/**
	 * The circumference of the current circle motion.
	 */
	public var circumference(get, null):Float;
	private function get_circumference():Float { return _radius * _CIRC; }
	
	// Circle information.
	private var _centerX:Float = 0;
	private var _centerY:Float = 0;
	private var _radius:Float = 0;
	private var _angle:Float = 0;
	private var _angleStart:Float = 0;
	private var _angleFinish:Float = 0;
	private static inline var _CIRC:Float = 6.283185307179586476925286766559;  // Math.PI * 2;
}