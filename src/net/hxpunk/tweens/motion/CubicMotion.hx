package net.hxpunk.tweens.motion;
import net.hxpunk.HP.VoidCallback;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Determines motion along a cubic curve.
 */
class CubicMotion extends Motion
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
	 * Starts moving along the curve.
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	duration	Duration of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotion(fromX:Float, fromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, toX:Float, toY:Float, duration:Float, ease:EasingFunction = null):Void
	{
		x = _fromX = fromX;
		y = _fromY = fromY;
		_aX = aX;
		_aY = aY;
		_bX = bX;
		_bY = bY;
		_toX = toX;
		_toY = toY;
		_target = duration;
		_ease = ease;
		start();
	}
	
	/** @private Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		x = _t * _t * _t * (_toX + 3 * (_aX - _bX) - _fromX) + 3 * _t * _t * (_fromX - 2 * _aX + _bX) + 3 * _t * (_aX - _fromX) + _fromX;
		y = _t * _t * _t * (_toY + 3 * (_aY - _bY) - _fromY) + 3 * _t * _t * (_fromY - 2 * _aY + _bY) + 3 * _t * (_aY - _fromY) + _fromY;
	}
	
	// Curve information.
	private var _fromX:Float = 0;
	private var _fromY:Float = 0;
	private var _toX:Float = 0;
	private var _toY:Float = 0;
	private var _aX:Float = 0;
	private var _aY:Float = 0;
	private var _bX:Float = 0;
	private var _bY:Float = 0;
}
