package net.hxpunk.tweens.misc;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.Tween;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Tweens a numeric value.
 */
class NumTween extends Tween
{
	/**
	 * The current value.
	 */
	public var value:Float = 0;
	
	/**
	 * Constructor.
	 * @param	onComplete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(onComplete:VoidCallback = null, type:TweenType = null) 
	{
		super(0, type, onComplete);
	}
	
	/**
	 * Tweens the value from one value to another.
	 * @param	fromValue		Start value.
	 * @param	toValue			End value.
	 * @param	duration		Duration of the tween.
	 * @param	ease			Optional easer function.
	 */
	public function tween(fromValue:Float, toValue:Float, duration:Float, ease:EasingFunction = null):Void
	{
		_start = value = fromValue;
		_range = toValue - value;
		_target = duration;
		_ease = ease;
		start();
	}
	
	/** @private Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		value = _start + _range * _t;
	}
	
	// Tween information.
	private var _start:Float;
	private var _range:Float;
}