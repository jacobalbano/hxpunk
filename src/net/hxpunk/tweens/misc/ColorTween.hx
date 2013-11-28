package net.hxpunk.tweens.misc;

import net.hxpunk.HP.VoidCallback;
import net.hxpunk.Tween;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Tweens a color's red, green, and blue properties
 * independently. Can also tween an alpha value.
 */
class ColorTween extends Tween
{
	/**
	 * The current color.
	 */
	public var color:Int;
	
	/**
	 * The current alpha.
	 */
	public var alpha:Float = 1;
	
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
	 * Tweens the color to a new color and an alpha to a new alpha.
	 * @param	duration		Duration of the tween.
	 * @param	fromColor		Start color.
	 * @param	toColor			End color.
	 * @param	fromAlpha		Start alpha
	 * @param	toAlpha			End alpha.
	 * @param	ease			Optional easer function.
	 */
	public function tween(duration:Float, fromColor:Int, toColor:Int, fromAlpha:Float = 1, toAlpha:Float = 1, ease:EasingFunction = null):Void
	{
		fromColor &= 0xFFFFFF;
		toColor &= 0xFFFFFF;
		color = fromColor;
		_r = fromColor >> 16 & 0xFF;
		_g = fromColor >> 8 & 0xFF;
		_b = fromColor & 0xFF;
		_startR = _r / 255;
		_startG = _g / 255;
		_startB = _b / 255;
		_rangeR = ((toColor >> 16 & 0xFF) / 255) - _startR;
		_rangeG = ((toColor >> 8 & 0xFF) / 255) - _startG;
		_rangeB = ((toColor & 0xFF) / 255) - _startB;
		_startA = alpha = fromAlpha;
		_rangeA = toAlpha - alpha;
		_target = duration;
		_ease = ease;
		start();
	}
	
	/** Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		alpha = _startA + _rangeA * _t;
		_r = Std.int((_startR + _rangeR * _t) * 255);
		_g = Std.int((_startG + _rangeG * _t) * 255);
		_b = Std.int((_startB + _rangeB * _t) * 255);
		color = _r << 16 | _g << 8 | _b;
	}
	
	/**
	 * Red value of the current color, from 0 to 255.
	 */
	public var red(get, null):Int;
	private inline function get_red():Int { return _r; }
	
	/**
	 * Green value of the current color, from 0 to 255.
	 */
	public var green(get, null):Int;
	private inline function get_green():Int { return _g; }
	
	/**
	 * Blue value of the current color, from 0 to 255.
	 */
	public var blue(get, null):Int;
	private inline function get_blue():Int { return _b; }
	
	// Color information.
	private var _r:Int;
	private var _g:Int;
	private var _b:Int;
	private var _startA:Float;
	private var _startR:Float;
	private var _startG:Float;
	private var _startB:Float;
	private var _rangeA:Float;
	private var _rangeR:Float;
	private var _rangeG:Float;
	private var _rangeB:Float;
}