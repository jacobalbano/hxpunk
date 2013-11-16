package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.HP;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Ease.EasingFunction;
import net.hxpunk.graphics.ParticleType;
import net.hxpunk.HP;
import net.hxpunk.Graphic;

/**
 * Particle emitter used for emitting and rendering particle sprites.
 * Good rendering performance with large amounts of particles.
 */
class Emitter extends Graphic
{
	/**
	 * Constructor. Sets the source image to use for newly added particle types.
	 * @param	source			Source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	frameWidth		Frame width.
	 * @param	frameHeight		Frame height.
	 */
	public function new(source:Dynamic, frameWidth:Int = 0, frameHeight:Int = 0) 
	{
		super();
		
		// init vars
		_types = new Map<String, ParticleType>();
		_p = new Point();
		_tint = new ColorTransform();
		_matrix = new Matrix();
		
		setSource(source, frameWidth, frameHeight);
		active = true;
	}
	
	/**
	 * Changes the source image to use for newly added particle types.
	 * @param	source			Source image.
	 * @param	frameWidth		Frame width.
	 * @param	frameHeight		Frame height.
	 */
	public function setSource(source:Dynamic, frameWidth:Int = 0, frameHeight:Int = 0):Void
	{
		_source = HP.getBitmapData(source);
		if (_source == null) throw new Error("Invalid source image.");
		_width = _source.width;
		_height = _source.height;
		_frameWidth = frameWidth > 0 ? frameWidth : _width;
		_frameHeight = frameHeight > 0? frameHeight : _height;
		_frameCount = Std.int(_width / _frameWidth) * Std.int(_height / _frameHeight);
	}
	
	/**
	 * Emits a particle.
	 * @param	name		Particle type to emit.
	 * @param	x			X point to emit from.
	 * @param	y			Y point to emit from.
	 * @return
	 */
	public function emit(name:String, x:Float = 0, y:Float = 0):Particle
	{
		if (!_types.exists(name)) throw new Error("Particle type \"" + name + "\" does not exist.");
		var p:Particle, type:FriendlyParticleType = _types[name];
		
		if (_cache != null)
		{
			p = _cache;
			_cache = p._next;
		}
		else p = new Particle();
		p._next = _particle;
		p._prev = null;
		if (p._next != null) p._next._prev = p;
		
		p._type = cast type;
		p._time = 0;
		p._duration = type._duration + type._durationRange * HP.random;
		var a:Float = type._angle + type._angleRange * HP.random,
			d:Float = type._distance + type._distanceRange * HP.random;
		p._moveX = Math.cos(a) * d;
		p._moveY = Math.sin(a) * d;
		p._x = x;
		p._y = y;
		p._gravity = type._gravity + type._gravityRange * HP.random;
		p._rotation = type._startAngle + type._startAngleRange * HP.random;
		p._totalRotation = type._spanAngle + type._spanAngleRange * HP.random;
		_particleCount ++;
		return (_particle = p);
	}

	override public function update():Void 
	{
		// quit if there are no particles
		if (_particle == null) return;
		
		// particle info
		var e:Float = HP.timeInFrames ? 1 : HP.elapsed,
			p:Particle = _particle,
			n:Particle;
		
		// loop through the particles
		while (p != null)
		{
			// update time scale
			p._time += e;
			
			// remove on time-out
			if (p._time >= p._duration)
			{
				if (p._next != null) p._next._prev = p._prev;
				if (p._prev != null) p._prev._next = p._next;
				else _particle = p._next;
				n = p._next;
				p._next = _cache;
				p._prev = null;
				_cache = p;
				p = n;
				_particleCount --;
				continue;
			}
			
			// get next particle
			p = p._next;
		}
	}
	
	/** @private Renders the particles. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		// quit if there are no particles
		if (_particle == null) return;
		
		// get rendering position
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;
		
		// particle info
		var t:Float, td:Float,
			p:Particle = _particle,
			type:FriendlyParticleType,
			rect:Rectangle;
		
		// loop through the particles
		while (p != null)
		{
			// get time scale
			t = p._time / p._duration;
			
			// get particle type
			type = p._type;
			rect = type._frame;
			
			// get position
			td = (type._ease == null) ? t : type._ease(t);
			_p.x = _point.x + p._x + p._moveX * td;
			_p.y = _point.y + p._y + p._moveY * td + p._gravity * td * td;
			
			// get frame
			rect.x = rect.width * type._frames[Std.int(td * type._frameCount)];
			rect.y = Std.int(rect.x / type._width) * rect.height;
			rect.x %= type._width;
			
			// draw particle
			if (type._buffer != null)
			{
				// get alpha
				var alphaT:Float = (type._alphaEase == null) ? t : type._alphaEase(t);
				_tint.alphaMultiplier = type._alpha + type._alphaRange * alphaT;
				
				// get color
				td = (type._colorEase == null) ? t : type._colorEase(t);
				_tint.redMultiplier = type._red + type._redRange * td;
				_tint.greenMultiplier = type._green + type._greenRange * td;
				_tint.blueMultiplier  = type._blue + type._blueRange * td;
				type._buffer.fillRect(type._bufferRect, 0);
				type._buffer.copyPixels(type._source, rect, HP.zero);
				type._buffer.colorTransform(type._bufferRect, _tint);
				
				// draw particle
				if (type._isRotating) {
					var _rotationT:Float = (type._rotationEase == null) ? t : type._rotationEase(t);
					_matrix.identity();
					_matrix.tx = -type.originX;
					_matrix.ty = -type.originY;
					_matrix.rotate(p._rotation + _rotationT * p._totalRotation);
					_matrix.tx += type.originX + _p.x;
					_matrix.ty += type.originY * .5 + _p.y;
					target.draw(type._buffer, _matrix, null, null, null, type._smooth);
				} else {
					target.copyPixels(type._buffer, type._bufferRect, _p, null, null, true);
				}
			} else {  // no buffer
				target.copyPixels(type._source, rect, _p, null, null, true);
			}
			
			// get next particle
			p = p._next;
		}
	}
	
	/**
	 * Creates a new Particle type for this Emitter.
	 * @param	name		Name of the particle type.
	 * @param	frames		Array of frame indices for the particles to animate.
	 * @param	originX		Origin x offset used for rotations (defaults to half frameWidth).
	 * @param	originY		Origin y offset used for rotations (defaults to half frameHeight).
	 * @return	A new ParticleType object.
	 */
	public function newType(name:String, frames:Array<Int> = null, ?originX:Float, ?originY:Float):ParticleType
	{
		if (frames == null) frames = new Array<Int>();
		if (frames.length == 0) frames[0] = 0;
		if (_types.exists(name)) throw new Error("Cannot add multiple particle types of the same name");
		return (_types[name] = new ParticleType(name, frames, _source, _frameWidth, _frameHeight, originX, originY));
	}
	
	/**
	 * Defines the motion range for a particle type.
	 * @param	name			The particle type.
	 * @param	angle			Launch Direction.
	 * @param	distance		Distance to travel.
	 * @param	duration		Particle duration.
	 * @param	angleRange		Random amount to add to the particle's direction.
	 * @param	distanceRange	Random amount to add to the particle's distance.
	 * @param	durationRange	Random amount to add to the particle's duration.
	 * @param	ease			Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setMotion(name:String, angle:Float, distance:Float, duration:Float, angleRange:Float = 0, distanceRange:Float = 0, durationRange:Float = 0, ease:EasingFunction = null):ParticleType
	{
		return _types[name].setMotion(angle, distance, duration, angleRange, distanceRange, durationRange, ease);
	}
	
	/**
	 * Defines the rotation range for a particle type.
	 * @param	name			The particle type.
	 * @param	startAngle		Starting angle.
	 * @param	spanAngle		Total amount of degrees to rotate.
	 * @param	startAngleRange	Random amount to add to the particle's starting angle.
	 * @param	spanAngleRange	Random amount to add to the particle's span angle.
	 * @param	smooth			Whether to smooth the resulting rotated particle.
	 * @param	ease			Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setRotation(name:String, startAngle:Float, spanAngle:Float, startAngleRange:Float = 0, spanAngleRange:Float = 0, smooth:Bool = false, ease:EasingFunction = null):ParticleType
	{
		return _types[name].setRotation(startAngle, spanAngle, startAngleRange, spanAngleRange, smooth, ease);
	}
	
	/**
	 * Sets the gravity range for a particle type.
	 * @param	name			The particle type.
	 * @param	gravity			Gravity amount to affect to the particle y velocity.
	 * @param	gravityRange	Random amount to add to the particle's gravity.
	 * @return	This ParticleType object.
	 */
	public function setGravity(name:String, gravity:Float = 0, gravityRange:Float = 0):ParticleType
	{
		return _types[name].setGravity(gravity, gravityRange);
	}
	
	/**
	 * Sets the alpha range of the particle type.
	 * @param	name		The particle type.
	 * @param	start		The starting alpha.
	 * @param	finish		The finish alpha.
	 * @param	ease		Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setAlpha(name:String, start:Float = 1, finish:Float = 0, ease:EasingFunction = null):ParticleType
	{
		return _types[name].setAlpha(start, finish, ease);
	}
	
	/**
	 * Sets the color range of the particle type.
	 * @param	name		The particle type.
	 * @param	start		The starting color.
	 * @param	finish		The finish color.
	 * @param	ease		Optional easer function.
	 * @return	This ParticleType object.
	 */
	public function setColor(name:String, start:Int = 0xFFFFFF, finish:Int = 0, ease:EasingFunction = null):ParticleType
	{
		return _types[name].setColor(start, finish, ease);
	}	
	
	/**
	 * Amount of currently existing particles.
	 */
	public var particleCount(get, null):Int;
	private inline function get_particleCount():Int { return _particleCount; }
	
	
	// Particle information.
	/** @private */ private var _types:Map<String, ParticleType>;
	/** @private */ private var _particle:Particle = null;
	/** @private */ private var _cache:Particle = null;
	/** @private */ private var _particleCount:Int = 0;
	
	// Source information.
	/** @private */ private var _source:BitmapData;
	/** @private */ private var _width:Int;
	/** @private */ private var _height:Int;
	/** @private */ private var _frameWidth:Int;
	/** @private */ private var _frameHeight:Int;
	/** @private */ private var _frameCount:Int;
	
	// Drawing information.
	/** @private */ private var _p:Point;
	/** @private */ private var _tint:ColorTransform;
	/** @private */ private var _matrix:Matrix;
}