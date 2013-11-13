package net.hxpunk.utils;

typedef EasingFunction = Float -> Float;

/**
 * Static class with useful easer functions that can be used by Tweens.
 */
class Ease 
{
	private static var init:Bool = initStaticVars();
	
	private static function initStaticVars():Bool 
	{
		// Easing constants.
		Ease.PI = Math.PI;
		Ease.PI2 = Math.PI / 2;
		return true;
	}
	
	/** Quadratic in. */
	public static function quadIn(t:Float):Float
	{
		return t * t;
	}
	
	/** Quadratic out. */
	public static function quadOut(t:Float):Float
	{
		return -t * (t - 2);
	}
	
	/** Quadratic in and out. */
	public static function quadInOut(t:Float):Float
	{
		return t <= .5 ? t * t * 2 : 1 - (--t) * t * 2;
	}
	
	/** Cubic in. */
	public static function cubeIn(t:Float):Float
	{
		return t * t * t;
	}
	
	/** Cubic out. */
	public static function cubeOut(t:Float):Float
	{
		return 1 + (--t) * t * t;
	}
	
	/** Cubic in and out. */
	public static function cubeInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * 4 : 1 + (--t) * t * t * 4;
	}
	
	/** Quart in. */
	public static function quartIn(t:Float):Float
	{
		return t * t * t * t;
	}
	
	/** Quart out. */
	public static function quartOut(t:Float):Float
	{
		return 1 - (t-=1) * t * t * t;
	}
	
	/** Quart in and out. */
	public static function quartInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * t * 8 : (1 - (t = t * 2 - 2) * t * t * t) / 2 + .5;
	}
	
	/** Quint in. */
	public static function quintIn(t:Float):Float
	{
		return t * t * t * t * t;
	}
	
	/** Quint out. */
	public static function quintOut(t:Float):Float
	{
		return (t = t - 1) * t * t * t * t + 1;
	}
	
	/** Quint in and out. */
	public static function quintInOut(t:Float):Float
	{
		return ((t *= 2) < 1) ? (t * t * t * t * t) / 2 : ((t -= 2) * t * t * t * t + 2) / 2;
	}
	
	/** Sine in. */
	public static function sineIn(t:Float):Float
	{
		return -Math.cos(Ease.PI2 * t) + 1;
	}
	
	/** Sine out. */
	public static function sineOut(t:Float):Float
	{
		return Math.sin(Ease.PI2 * t);
	}
	
	/** Sine in and out. */
	public static function sineInOut(t:Float):Float
	{
		return -Math.cos(Ease.PI * t) / 2 + .5;
	}
	
	/** Bounce in. */
	public static function bounceIn(t:Float):Float
	{
		t = 1 - t;
		if (t < B1) return 1 - 7.5625 * t * t;
		if (t < B2) return 1 - (7.5625 * (t - B3) * (t - B3) + .75);
		if (t < B4) return 1 - (7.5625 * (t - B5) * (t - B5) + .9375);
		return 1 - (7.5625 * (t - B6) * (t - B6) + .984375);
	}
	
	/** Bounce out. */
	public static function bounceOut(t:Float):Float
	{
		if (t < B1) return 7.5625 * t * t;
		if (t < B2) return 7.5625 * (t - B3) * (t - B3) + .75;
		if (t < B4) return 7.5625 * (t - B5) * (t - B5) + .9375;
		return 7.5625 * (t - B6) * (t - B6) + .984375;
	}
	
	/** Bounce in and out. */
	public static function bounceInOut(t:Float):Float
	{
		if (t < .5)
		{
			t = 1 - t * 2;
			if (t < B1) return (1 - 7.5625 * t * t) / 2;
			if (t < B2) return (1 - (7.5625 * (t - B3) * (t - B3) + .75)) / 2;
			if (t < B4) return (1 - (7.5625 * (t - B5) * (t - B5) + .9375)) / 2;
			return (1 - (7.5625 * (t - B6) * (t - B6) + .984375)) / 2;
		}
		t = t * 2 - 1;
		if (t < B1) return (7.5625 * t * t) / 2 + .5;
		if (t < B2) return (7.5625 * (t - B3) * (t - B3) + .75) / 2 + .5;
		if (t < B4) return (7.5625 * (t - B5) * (t - B5) + .9375) / 2 + .5;
		return (7.5625 * (t - B6) * (t - B6) + .984375) / 2 + .5;
	}
	
	/** Circle in. */
	public static function circIn(t:Float):Float
	{
		return -(Math.sqrt(1 - t * t) - 1);
	}
	
	/** Circle out. */
	public static function circOut(t:Float):Float
	{
		return Math.sqrt(1 - (t - 1) * (t - 1));
	}
	
	/** Circle in and out. */
	public static function circInOut(t:Float):Float
	{
		return t <= .5 ? (Math.sqrt(1 - t * t * 4) - 1) / -2 : (Math.sqrt(1 - (t * 2 - 2) * (t * 2 - 2)) + 1) / 2;
	}
	
	/** Exponential in. */
	public static function expoIn(t:Float):Float
	{
		return Math.pow(2, 10 * (t - 1));
	}
	
	/** Exponential out. */
	public static function expoOut(t:Float):Float
	{
		return -Math.pow(2, -10 * t) + 1;
	}
	
	/** Exponential in and out. */
	public static function expoInOut(t:Float):Float
	{
		return t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) / 2 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) / 2;
	}
	
	/** Back in. */
	public static function backIn(t:Float):Float
	{
		return t * t * (2.70158 * t - 1.70158);
	}
	
	/** Back out. */
	public static function backOut(t:Float):Float
	{
		return 1 - (--t) * (t) * (-2.70158 * t - 1.70158);
	}
	
	/** Back in and out. */
	public static function backInOut(t:Float):Float
	{
		t *= 2;
		if (t < 1) return t * t * (2.70158 * t - 1.70158) / 2;
		t --;
		return (1 - (--t) * (t) * (-2.70158 * t - 1.70158)) / 2 + .5;
	}
	
	/** 
	 * Convert ease function from Penner format to FlashPunk format.
	 * 
	 * Paramaters are the polynomial coefficients
	 * 
	 * @see http://timotheegroleau.com/Flash/experiments/easing_function_generator.htm
	 * @see http://www.robertpenner.com/easing/penner_chapter7_tweening.pdf
	 * 
	 * Ex. (out elastic (big)):
	       var customEase:EasingFunction = Ease.fromPennerFormat(20, -100, 200, -175, 56);
		   HP.tween(entity, {x: HP.halfWidth, y:HP.halfHeight}, .75, {ease:customEase});
	 * 
	 * @return A function to use as an ease function
	 */
	public static function fromPennerFormat(t1:Float=1, t2:Float=0, t3:Float=0, t4:Float=0, t5:Float=0):EasingFunction 
	{
		return function (t:Float):Float {
			var ts:Float = t * t;
			var tc:Float = ts * t;
			return (t5 * tc * ts + t4 * ts * ts + t3 * tc + t2 * ts + t1 * t);
		}
	}
	
	 
	// Easing constants.
	/** @private */ private static var PI:Float;
	/** @private */ private static var PI2:Float;
	/** @private */ private static inline var B1:Float = 1 / 2.75;
	/** @private */ private static inline var B2:Float = 2 / 2.75;
	/** @private */ private static inline var B3:Float = 1.5 / 2.75;
	/** @private */ private static inline var B4:Float = 2.5 / 2.75;
	/** @private */ private static inline var B5:Float = 2.25 / 2.75;
	/** @private */ private static inline var B6:Float = 2.625 / 2.75;

	/**
	 * Operation of in/out easers:
	 * 
	 * in(t)
	 *		return t;
	 * out(t)
	 * 		return 1 - in(1 - t);
	 * inOut(t)
	 * 		return (t <= .5) ? in(t * 2) / 2 : out(t * 2 - 1) / 2 + .5;
	 */
}

