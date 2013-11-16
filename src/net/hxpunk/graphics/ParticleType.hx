package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import net.hxpunk.HP;
import net.hxpunk.utils.Ease.EasingFunction;

import net.hxpunk.HP;


typedef FriendlyParticleType = {
	
	// Particle information.
	/** @private */ private var _name:String;
	/** @private */ private var _source:BitmapData;
	/** @private */ private var _width:Int;
	/** @private */ private var _frame:Rectangle;
	/** @private */ private var _frames:Array<Int>;
	/** @private */ private var _frameCount:Int;
	
	// Motion information.
	/** @private */ private var _angle:Float;
	/** @private */ private var _angleRange:Float;
	/** @private */ private var _distance:Float;
	/** @private */ private var _distanceRange:Float;
	/** @private */ private var _duration:Float;
	/** @private */ private var _durationRange:Float;
	/** @private */ private var _ease:EasingFunction;
	
	// Rotation information.
	public var originX:Float;
	public var originY:Float;
	/** @private */ private var _isRotating:Bool;
	/** @private */ private var _startAngle:Float;
	/** @private */ private var _startAngleRange:Float;
	/** @private */ private var _spanAngle:Float;
	/** @private */ private var _spanAngleRange:Float;
	/** @private */ private var _smooth:Bool;
	/** @private */ private var _rotationEase:EasingFunction;

	// Gravity information.
	/** @private */ private var _gravity:Float;
	/** @private */ private var _gravityRange:Float;
	
	// Alpha information.
	/** @private */ private var _alpha:Float;
	/** @private */ private var _alphaRange:Float;
	/** @private */ private var _alphaEase:EasingFunction;
	
	// Color information.
	/** @private */ private var _red:Float;
	/** @private */ private var _redRange:Float;
	/** @private */ private var _green:Float;
	/** @private */ private var _greenRange:Float;
	/** @private */ private var _blue:Float;
	/** @private */ private var _blueRange:Float;
	/** @private */ private var _colorEase:EasingFunction;
	
	// Buffer information.
	/** @private */ private var _buffer:BitmapData;
	/** @private */ private var _bufferRect:Rectangle;
}


/**
 * Template used to define a particle type used by the Emitter class. Instead
 * of creating this object yourself, fetch one with Emitter's add() function.
 */
class ParticleType 
{
	// Rotation information.

	/**
	 * X origin of the frame, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originX:Float = 0;

	/**
	 * Y origin of the frame, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originY:Float = 0;
	
	/**
	 * Constructor.
	 * @param	name			Name of the particle type.
	 * @param	frames			Array of frame indices to animate through.
	 * @param	source			Source image BitmapData.
	 * @param	frameWidth		Frame width.
	 * @param	frameHeight		Frame height.
	 */
	public function new(name:String, frames:Array<Int>, source:BitmapData, frameWidth:Int, frameHeight:Int)
	{
		_name = name;
		_source = source;
		_width = source.width;
		_frame = new Rectangle(0, 0, frameWidth, frameHeight);
		_frames = frames;
		_frameCount = frames.length;
	}
	
	/**
	 * Defines the motion range for this particle type.
	 * @param	angle			Launch Direction.
	 * @param	distance		Distance to travel.
	 * @param	duration		Particle duration.
	 * @param	angleRange		Random amount to add to the particle's direction.
	 * @param	distanceRange	Random amount to add to the particle's distance.
	 * @param	durationRange	Random amount to add to the particle's duration.
	 * @param	ease			Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setMotion(angle:Float, distance:Float, duration:Float, angleRange:Float = 0, distanceRange:Float = 0, durationRange:Float = 0, ease:EasingFunction = null):ParticleType
	{
		_angle = angle * HP.RAD;
		_distance = distance;
		_duration = duration;
		_angleRange = angleRange * HP.RAD;
		_distanceRange = distanceRange;
		_durationRange = durationRange;
		_ease = ease;
		return this;
	}
	
	/**
	 * Defines the rotation range for this particle type.
	 * @param	name			The particle type.
	 * @param	startAngle		Starting angle.
	 * @param	spanAngle		Total amount of degrees to rotate.
	 * @param	startAngleRange	Random amount to add to the particle's starting angle.
	 * @param	spanAngleRange	Random amount to add to the particle's span angle.
	 * @param	smooth			Whether to smooth the resulting rotated particle.
	 * @param	ease			Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setRotation(startAngle:Float, spanAngle:Float, startAngleRange:Float = 0, spanAngleRange:Float = 0, smooth:Bool = false, ease:EasingFunction = null):ParticleType
	{
		_isRotating = true;
		_startAngle = startAngle * HP.RAD;
		_spanAngle = spanAngle * HP.RAD;
		_startAngleRange = startAngleRange * HP.RAD;
		_spanAngleRange = spanAngleRange * HP.RAD;
		_smooth = smooth;
		_rotationEase = ease;
		createBuffer();
		return this;
	}

	/**
	 * Defines the motion range for this particle type based on the vector.
	 * @param	x				X distance to move.
	 * @param	y				Y distance to move.
	 * @param	duration		Particle duration.
	 * @param	durationRange	Random amount to add to the particle's duration.
	 * @param	ease			Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setMotionVector(x:Float, y:Float, duration:Float, durationRange:Float = 0, ease:EasingFunction = null):ParticleType
	{
		_angle = Math.atan2(y, x);
		_angleRange = 0;
		_duration = duration;
		_durationRange = durationRange;
		_ease = ease;
		return this;
	}
	
	/**
	 * Sets the gravity range of this particle type.
	 * @param	gravity			Gravity amount to affect to the particle y velocity.
	 * @param	gravityRange	Random amount to add to the particle's gravity.
	 * @return	This ParticleType object.
	 */
	public function setGravity(gravity:Float = 0, gravityRange:Float = 0):ParticleType
	{
		_gravity = gravity;
		_gravityRange = gravityRange;
		return this;
	}
	
	/**
	 * Sets the alpha range of this particle type.
	 * @param	start		The starting alpha.
	 * @param	finish		The finish alpha.
	 * @param	ease		Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setAlpha(start:Float = 1, finish:Float = 0, ease:EasingFunction = null):ParticleType
	{
		start = start < 0 ? 0 : (start > 1 ? 1 : start);
		finish = finish < 0 ? 0 : (finish > 1 ? 1 : finish);
		_alpha = start;
		_alphaRange = finish - start;
		_alphaEase = ease;
		createBuffer();
		return this;
	}
	
	/**
	 * Sets the color range of this particle type.
	 * @param	start		The starting color.
	 * @param	finish		The finish color.
	 * @param	ease		Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setColor(start:Int = 0xFFFFFF, finish:Int = 0, ease:EasingFunction = null):ParticleType
	{
		start &= 0xFFFFFF;
		finish &= 0xFFFFFF;
		_red = (start >> 16 & 0xFF) / 255;
		_green = (start >> 8 & 0xFF) / 255;
		_blue = (start & 0xFF) / 255;
		_redRange = (finish >> 16 & 0xFF) / 255 - _red;
		_greenRange = (finish >> 8 & 0xFF) / 255 - _green;
		_blueRange = (finish & 0xFF) / 255 - _blue;
		_colorEase = ease;
		createBuffer();
		return this;
	}
	
	/** @private Creates the buffer if it doesn't exist. */
	private function createBuffer():Void
	{
		if (_buffer != null) return;
		_buffer = new BitmapData(Std.int(_frame.width), Std.int(_frame.height), true, 0);
		_bufferRect = _buffer.rect;
	}
	
	// Particle information.
	/** @private */ private var _name:String;
	/** @private */ private var _source:BitmapData;
	/** @private */ private var _width:Int;
	/** @private */ private var _frame:Rectangle;
	/** @private */ private var _frames:Array<Int>;
	/** @private */ private var _frameCount:Int;
	
	// Motion information.
	/** @private */ private var _angle:Float = 0;
	/** @private */ private var _angleRange:Float = 0;
	/** @private */ private var _distance:Float = 0;
	/** @private */ private var _distanceRange:Float = 0;
	/** @private */ private var _duration:Float = 0;
	/** @private */ private var _durationRange:Float = 0;
	/** @private */ private var _ease:EasingFunction;
	
	// Rotation information.
	/** @private */ private var _isRotating:Bool = false;
	/** @private */ private var _startAngle:Float = 0;
	/** @private */ private var _startAngleRange:Float = 0;
	/** @private */ private var _spanAngle:Float = 0;
	/** @private */ private var _spanAngleRange:Float = 0;
	/** @private */ private var _smooth:Bool = false;
	/** @private */ private var _rotationEase:EasingFunction;

	// Gravity information.
	/** @private */ private var _gravity:Float = 0;
	/** @private */ private var _gravityRange:Float = 0;
	
	// Alpha information.
	/** @private */ private var _alpha:Float = 1;
	/** @private */ private var _alphaRange:Float = 0;
	/** @private */ private var _alphaEase:EasingFunction;
	
	// Color information.
	/** @private */ private var _red:Float = 1;
	/** @private */ private var _redRange:Float = 0;
	/** @private */ private var _green:Float = 1;
	/** @private */ private var _greenRange:Float = 0;
	/** @private */ private var _blue:Float = 1;
	/** @private */ private var _blueRange:Float = 0;
	/** @private */ private var _colorEase:EasingFunction;
	
	// Buffer information.
	/** @private */ private var _buffer:BitmapData;
	/** @private */ private var _bufferRect:Rectangle;
}
