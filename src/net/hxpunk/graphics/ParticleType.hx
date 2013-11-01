package net.flashpunk.graphics 
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import net.flashpunk.FP;
	
	/**
	 * Template used to define a particle type used by the Emitter class. Instead
	 * of creating this object yourself, fetch one with Emitter's add() function.
	 */
	public class ParticleType 
	{
		/**
		 * Constructor.
		 * @param	name			Name of the particle type.
		 * @param	frames			Array of frame indices to animate through.
		 * @param	source			Source image.
		 * @param	frameWidth		Frame width.
		 * @param	frameHeight		Frame height.
		 */
		public function ParticleType(name:String, frames:Array, source:BitmapData, frameWidth:Int, frameHeight:Int)
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
		public function setMotion(angle:Float, distance:Float, duration:Float, angleRange:Float = 0, distanceRange:Float = 0, durationRange:Float = 0, ease:Function = null):ParticleType
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
		 * Defines the motion range for this particle type based on the vector.
		 * @param	x				X distance to move.
		 * @param	y				Y distance to move.
		 * @param	duration		Particle duration.
		 * @param	durationRange	Random amount to add to the particle's duration.
		 * @param	ease			Optional easer function.
		 * @return	This ParticleType object.
		 */
		public function setMotionVector(x:Float, y:Float, duration:Float, durationRange:Float = 0, ease:Function = null):ParticleType
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
		public function setAlpha(start:Float = 1, finish:Float = 0, ease:Function = null):ParticleType
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
		public function setColor(start:Int = 0xFFFFFF, finish:Int = 0, ease:Function = null):ParticleType
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
			if (_buffer) return;
			_buffer = new BitmapData(_frame.width, _frame.height, true, 0);
			_bufferRect = _buffer.rect;
		}
		
		// Particle information.
		/** @private */ internal var _name:String;
		/** @private */ internal var _source:BitmapData;
		/** @private */ internal var _width:Int;
		/** @private */ internal var _frame:Rectangle;
		/** @private */ internal var _frames:Array;
		/** @private */ internal var _frameCount:Int;
		
		// Motion information.
		/** @private */ internal var _angle:Float;
		/** @private */ internal var _angleRange:Float;
		/** @private */ internal var _distance:Float;
		/** @private */ internal var _distanceRange:Float;
		/** @private */ internal var _duration:Float;
		/** @private */ internal var _durationRange:Float;
		/** @private */ internal var _ease:Function;
		
		// Gravity information.
		/** @private */ internal var _gravity:Float = 0;
		/** @private */ internal var _gravityRange:Float = 0;
		
		// Alpha information.
		/** @private */ internal var _alpha:Float = 1;
		/** @private */ internal var _alphaRange:Float = 0;
		/** @private */ internal var _alphaEase:Function;
		
		// Color information.
		/** @private */ internal var _red:Float = 1;
		/** @private */ internal var _redRange:Float = 0;
		/** @private */ internal var _green:Float = 1;
		/** @private */ internal var _greenRange:Float = 0;
		/** @private */ internal var _blue:Float = 1;
		/** @private */ internal var _blueRange:Float = 0;
		/** @private */ internal var _colorEase:Function;
		
		// Buffer information.
		/** @private */ internal var _buffer:BitmapData;
		/** @private */ internal var _bufferRect:Rectangle;
	}
}