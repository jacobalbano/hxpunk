package net.hxpunk.graphics;


/**
 * Used by the Emitter class to track an existing Particle.
 */
class Particle
{
	public function new()
	{
		
	}
	
	// Particle information.
	public var _type:ParticleType = null;
	public var _time:Float = 0;
	public var _duration:Float = 0;
	
	// Motion information.
	public var _x:Float = 0;
	public var _y:Float = 0;
	public var _moveX:Float = 0;
	public var _moveY:Float = 0;
	
	// Rotation information.
	public var _rotation:Float = 0;
	public var _totalRotation:Float = 0;

	// Gravity information.
	public var _gravity:Float = 0;
	
	// List information.
	public var _prev:Particle = null;
	public var _next:Particle = null;
}
