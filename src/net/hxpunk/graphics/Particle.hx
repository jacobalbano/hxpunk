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
	/** @private */ public var _type:ParticleType = null;
	/** @private */ public var _time:Float = 0;
	/** @private */ public var _duration:Float = 0;
	
	// Motion information.
	/** @private */ public var _x:Float = 0;
	/** @private */ public var _y:Float = 0;
	/** @private */ public var _moveX:Float = 0;
	/** @private */ public var _moveY:Float = 0;
	
	// Rotation information.
	/** @private */ public var _rotation:Float = 0;
	/** @private */ public var _totalRotation:Float = 0;

	// Gravity information.
	/** @private */ public var _gravity:Float = 0;
	
	// List information.
	/** @private */ public var _prev:Particle = null;
	/** @private */ public var _next:Particle = null;
}
