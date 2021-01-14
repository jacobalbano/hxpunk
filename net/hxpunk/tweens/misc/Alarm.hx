﻿package net.hxpunk.tweens.misc;

import net.hxpunk.Tween;

/**
 * A simple alarm, useful for timed events, etc.
 */
class Alarm extends Tween
{
	/**
	 * Constructor.
	 * @param	duration	Duration of the alarm.
	 * @param	complete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(duration:Float, complete:Void -> Void = null, type:TweenType = null) 
	{
		super(duration, type, complete, null);
	}
	
	/**
	 * Sets the alarm.
	 * @param	duration	Duration of the alarm.
	 */
	public function reset(duration:Float):Void
	{
		_target = duration;
		start();
	}
	
	/**
	 * How much time has passed since reset.
	 */
	public var elapsed(get, null):Float;
	private inline function get_elapsed() { return _time; }
	
	/**
	 * Current alarm duration.
	 */
	public var duration(get, null):Float;
	private inline function get_duration() { return _target; }
	
	/**
	 * Time remaining on the alarm.
	 */
	public var remaining(get, null):Float;
	private inline function get_remaining() { return _target - _time; }
}
