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
	/** @private */ public var _type:ParticleType;
	/** @private */ public var _time:Float;
	/** @private */ public var _duration:Float;
	
	// Motion information.
	/** @private */ public var _x:Float;
	/** @private */ public var _y:Float;
	/** @private */ public var _moveX:Float;
	/** @private */ public var _moveY:Float;
	
	// Gravity information.
	/** @private */ public var _gravity:Float;
	
	// List information.
	/** @private */ public var _prev:Particle;
	/** @private */ public var _next:Particle;
}
