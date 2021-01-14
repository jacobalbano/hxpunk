﻿package net.hxpunk;
import net.hxpunk.HP.VoidCallback;
import net.hxpunk.utils.Ease.EasingFunction;

enum TweenType {

	/** Persistent Tween type, will stop when it finishes. */
	PERSIST;

	/** Looping Tween type, will restart immediately when it finishes. */
	LOOPING;

	/** Oneshot Tween type, will stop and remove itself from its core container when it finishes. */
	ONESHOT;
}


/**
 * Base class for all Tween objects, can be added to any Core-extended classes.
 */
class Tween 
{	
	/**
	 * If the tween should update.
	 */
	public var active:Bool;
	
	/**
	 * Tween completion callback.
	 */
	public var onComplete:VoidCallback;
	
	/**
	 * Length of time to wait before starting this tween.
	 */
	public var delay:Float = 0;
	
	/**
	 * Constructor. Specify basic information about the Tween.
	 * @param	duration		Duration of the tween (in seconds or frames).
	 * @param	type			Tween type, one of Tween.PERSIST (default), Tween.LOOPING, or Tween.ONESHOT.
	 * @param	onComplete		Optional callback for when the Tween completes.
	 * @param	ease			Optional easer function to apply to the Tweened value.
	 */
	public function new(duration:Float, type:TweenType = null, onComplete:VoidCallback = null, ease:EasingFunction = null) 
	{
		if (type == null) type = TweenType.PERSIST;
		_target = duration;
		_type = type;
		this.onComplete = onComplete;
		_ease = ease;
	}
	
	/**
	 * Updates the Tween, called by World.
	 */
	public function update():Void
	{
		var dt:Float = HP.timeInFrames ? 1 : HP.elapsed;
		if (delay > 0) {
			delay -= dt;
			
			if (delay > 0) {
				return;
			} else {
				_time -= delay;
			}
		} else {
			_time += dt;
		}
		
		_t = _time / _target;
		if (_time >= _target)
		{
			_t = 1;
			_finish = true;
		}
		if (_ease != null) _t = _ease(_t);
	}
	
	/**
	 * Starts the Tween, or restarts it if it's currently running.
	 */
	public function start():Void
	{
		_time = 0;
		if (_target == 0)
		{
			active = false;
			return;
		}
		active = true;
	}
	
	/**
	 * Immediately stops the Tween and removes it from its Tweener without calling the complete callback.
	 */
	public function cancel():Void
	{
		active = false;
		if (_parent != null) _parent.removeTween(this);
	}
	
	/** Called when the Tween completes. */
	public function finish():Void
	{
		switch (_type)
		{
			case PERSIST:
				_time = _target;
				active = false;
			case LOOPING:
				_time %= _target;
				_t = _time / _target;
				if (_ease != null) _t = _ease(_t);
				start();
			case ONESHOT:
				_time = _target;
				active = false;
				_parent.removeTween(this);
		}
		_finish = false;
		if (onComplete != null) onComplete();
	}
	
	/**
	 * The completion percentage of the Tween.
	 */
	public var percent(get, set):Float;
	private inline function get_percent() { return _time / _target; }
	private inline function set_percent(value:Float):Float { return _time = _target * value; }
	
	/**
	 * The current time scale of the Tween (after easer has been applied).
	 */
	public var scale(get, null):Float;
	private inline function get_scale() { return _t; }
	
	// Tween information.
	private var _type:TweenType;
	private var _ease:EasingFunction;
	private var _t:Float = 0;
	
	// Timing information.
	private var _time:Float = 0;
	private var _target:Float = 0;
	
	// List information.
	public var _finish:Bool;
	public var _parent:Tweener;
	public var _prev:Tween;
	public var _next:Tween;
}

