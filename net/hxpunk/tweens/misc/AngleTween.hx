﻿package net.hxpunk.tweens.misc;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.HP;
import net.hxpunk.Tween;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Tweens from one angle to another.
 */
class AngleTween extends Tween
{
	/**
	 * The current value.
	 */
	public var angle:Float = 0;
	
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
	 * Tweens the value from one angle to another.
	 * @param	fromAngle		Start angle.
	 * @param	toAngle			End angle.
	 * @param	duration		Duration of the tween.
	 * @param	ease			Optional easer function.
	 */
	public function tween(fromAngle:Float, toAngle:Float, duration:Float, ease:EasingFunction = null):Void
	{
		_start = angle = fromAngle;
		var d:Float = toAngle - angle,
			a:Float = Math.abs(d);
		if (a > 181) _range = (360 - a) * (d > 0 ? -1 : 1);
		else if (a < 179) _range = d;
		else _range = HP.choose(180, -180);
		_target = duration;
		_ease = ease;
		start();
	}
	
	/** Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		angle = (_start + _range * _t) % 360;
		if (angle < 0) angle += 360;
	}
	
	// Tween information.
	private var _start:Float;
	private var _range:Float;
}