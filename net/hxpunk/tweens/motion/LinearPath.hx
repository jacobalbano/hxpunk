package net.hxpunk.tweens.motion;

import flash.errors.Error;
import flash.geom.Point;
import net.hxpunk.HP.VoidCallback;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Determines linear motion along a set of points.
 */
class LinearPath extends Motion
{
	/**
	 * Constructor.
	 * @param	onComplete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(onComplete:VoidCallback = null, type:TweenType = null) 
	{
		super(0, onComplete, type, null);

		_points = new Array<Point>();
		_pointD = new Array<Float>();
		_pointT = new Array<Float>();
		
		_pointD[0] = _pointT[0] = 0;
	}
	
	/**
	 * Starts moving along the path.
	 * @param	duration		Duration of the movement.
	 * @param	ease			Optional easer function.
	 */
	public function setMotion(duration:Float, ease:EasingFunction = null):Void
	{
		updatePath();
		_target = duration;
		_speed = _distance / duration;
		_ease = ease;
		start();
	}
	
	/**
	 * Starts moving along the path at the speed.
	 * @param	speed		Speed of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotionSpeed(speed:Float, ease:EasingFunction = null):Void
	{
		updatePath();
		_target = _distance / speed;
		_speed = speed;
		_ease = ease;
		start();
	}
	
	/**
	 * Adds the point to the path.
	 * @param	x		X position.
	 * @param	y		Y position.
	 */
	public function addPoint(x:Float = 0, y:Float = 0):Void
	{
		if (_lastPoint != null)
		{
			// avoid zero-length path segments
			if (x == _lastPoint.x && y == _lastPoint.y)
				return;

			_distance += Math.sqrt((x - _lastPoint.x) * (x - _lastPoint.x) + (y - _lastPoint.y) * (y - _lastPoint.y));
			_pointD[_points.length] = _distance;
		}
		else
		{
			this.x = x;
			this.y = y;
		}
		_points[_points.length] = _lastPoint = new Point(x, y);
	}
	
	/**
	 * Gets a point on the path.
	 * @param	index		Index of the point.
	 * @return	The Point object.
	 */
	public function getPoint(index:Int = 0):Point
	{
		if (_points.length == 0) throw new Error("No points have been added to the path yet.");
		return _points[index % _points.length];
	}
	
	/** Starts the Tween. */
	override public function start():Void 
	{
		_index = 0;
		super.start();
	}
	
	/** Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		if (_points.length == 1)
		{
			x = _points[0].x;
			y = _points[0].y;
			return;
		}
		if (_index < _points.length - 1)
		{
			while (_t > _pointT[_index + 1]) _index ++;
		}
		var td:Float = _pointT[_index],
			tt:Float = _pointT[_index + 1] - td;
		td = (_t - td) / tt;
		_prevPoint = _points[_index];
		_nextPoint = _points[_index + 1];
		x = _prevPoint.x + (_nextPoint.x - _prevPoint.x) * td;
		y = _prevPoint.y + (_nextPoint.y - _prevPoint.y) * td;
	}
	
	/** Updates the path, preparing it for motion. */
	private function updatePath():Void
	{
		if (_points.length < 1) throw new Error("A LinearPath must have at least one point.");
		if (_pointD.length == _pointT.length) return;
		// evaluate t for each point
		var i:Int = 0;
		while (i < _points.length) _pointT[i] = _pointD[i ++] / _distance;
	}
	
	/**
	 * The full length of the path.
	 */
	public var distance(get, null):Float;
	private inline function get_distance():Float { return _distance; }
	
	/**
	 * How many points are on the path.
	 */
	public var pointCount(get, null):Int;
	private inline function get_pointCount():Int { return _points.length; }
	
	// Path information.
	private var _points:Array<Point>;
	private var _pointD:Array<Float>;
	private var _pointT:Array<Float>;
	private var _distance:Float = 0;
	private var _speed:Float = 0;
	private var _index:Int = 0;
	
	// Line information.
	private var _lastPoint:Point;
	private var _prevPoint:Point;
	private var _nextPoint:Point;
}
