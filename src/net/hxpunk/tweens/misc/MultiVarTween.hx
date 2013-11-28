package net.hxpunk.tweens.misc;

import flash.errors.Error;
import net.hxpunk.Tween;
import net.hxpunk.HP.VoidCallback;
import net.hxpunk.HP;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Tweens multiple numeric public properties of an Object simultaneously.
 */
class MultiVarTween extends Tween
{
	/**
	 * Constructor.
	 * @param	onComplete		Optional completion callback.
	 * @param	type			Tween type.
	 */
	public function new(onComplete:VoidCallback = null, type:TweenType = null)
	{
		super(0, type, onComplete);

		_vars = new Array<String>();
		_start = new Array<Float>();
		_range = new Array<Float>();
	}
	
	/**
	 * Tweens multiple numeric public properties.
	 * @param	object		The object containing the properties.
	 * @param	values		An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween.
	 * @param	ease		Optional easer function.
	 */
	public function tween(object:Dynamic, values:Dynamic, duration:Float, ease:EasingFunction = null, delay:Float = 0):Void
	{
		_object = object;
		HP.removeAll(_vars);
		HP.removeAll(_start);
		HP.removeAll(_range);
		_target = duration;
		this.delay = delay;
		_ease = ease;
		for (p in Reflect.fields(values))
		{
			if (!Reflect.hasField(object, p)) throw new Error("The Object does not have the property\"" + p + "\", or it is not accessible.");
			var a:Dynamic = cast(Reflect.getProperty(_object, p), Float);
			if (a == null || Math.isNaN(a)) throw new Error("The property \"" + p + "\" is not numeric.");
			_vars.push(p);
			_start.push(a);
			_range.push(Reflect.getProperty(values, p) - a);
		}
		start();
	}
	
	/** Updates the Tween. */
	override public function update():Void
	{
		super.update();
		if (delay > 0) return;
		var i:Int = _vars.length;
		while (i -- > 0) Reflect.setProperty(_object, _vars[i], _start[i] + _range[i] * _t);
	}

	// Tween information.
	private var _object:Dynamic;
	private var _vars:Array<String>;
	private var _start:Array<Float>;
	private var _range:Array<Float>;
}