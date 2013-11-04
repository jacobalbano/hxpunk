package net.hxpunk.tweens.misc;

import flash.errors.Error;
import net.hxpunk.graphics.Spritemap.VoidCallback;
import net.hxpunk.Tween;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Tweens a numeric public property of an Object.
 */
class VarTween extends Tween
{
	/**
	 * Constructor.
	 * @param	complete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(complete:VoidCallback = null, type:TweenType = null) 
	{
		super(0, type, complete);
	}
	
	/**
	 * Tweens a numeric public property.
	 * @param	object		The object containing the property.
	 * @param	property	The name of the property (eg. "x").
	 * @param	to			Value to tween to.
	 * @param	duration	Duration of the tween.
	 * @param	ease		Optional easer function.
	 */
	public function tween(object:Dynamic, property:String, to:Float, duration:Float, ease:EasingFunction = null):Void
	{
		_object = object;
		_property = property;
		_ease = ease;
		if (!Reflect.hasField(object, property)) throw new Error("The Object does not have the property\"" + property + "\", or it is not accessible.");
		var a:Dynamic = cast(Reflect.getProperty(_object, property), Float);
		if (a == null || Math.isNaN(a)) throw new Error("The property \"" + property + "\" is not numeric.");
		_start = Reflect.getProperty(_object, property);
		_range = to - _start;
		_target = duration;
		_ease = ease;
		start();
	}
	
	/** @private Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		Reflect.setProperty(_object, _property, _start + _range * _t);
	}
	
	// Tween information.
	/** @private */ private var _object:Dynamic;
	/** @private */ private var _property:String;
	/** @private */ private var _start:Float;
	/** @private */ private var _range:Float;
}