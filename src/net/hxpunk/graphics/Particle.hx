package net.flashpunk.graphics 
{
	/**
	 * Used by the Emitter class to track an existing Particle.
	 */
	public class Particle 
	{
		/**
		 * Constructor.
		 */
		public function Particle() 
		{
			
		}
		
		// Particle information.
		/** @private */ internal var _type:ParticleType;
		/** @private */ internal var _time:Float;
		/** @private */ internal var _duration:Float;
		
		// Motion information.
		/** @private */ internal var _x:Float;
		/** @private */ internal var _y:Float;
		/** @private */ internal var _moveX:Float;
		/** @private */ internal var _moveY:Float;
		
		// Gravity information.
		/** @private */ internal var _gravity:Float;
		
		// List information.
		/** @private */ internal var _prev:Particle;
		/** @private */ internal var _next:Particle;
	}
}