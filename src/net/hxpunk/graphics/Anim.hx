package net.hxpunk.graphics;


typedef FriendlyAnim = {
	private var _parent:Spritemap;
}

/**
 * Template used by Spritemap to define animations. Don't create
 * these yourself, instead you can fetch them with Spritemap's add().
 */
class Anim 
{
	/**
	 * Constructor.
	 * @param	name		Animation name.
	 * @param	frames		Array of frame indices to animate.
	 * @param	frameRate	Animation speed.
	 * @param	loop		If the animation should loop.
	 */
	public function new(name:String, frames:Array<Int>, frameRate:Float = 0, loop:Bool = true) 
	{
		_name = name;
		_frames = frames;
		_frameRate = frameRate;
		_loop = loop;
		_frameCount = frames.length;
	}
	
	/**
	 * Plays the animation.
	 * @param	reset		If the animation should force-restart if it is already playing.
	 */
	public function play(reset:Bool = false):Void
	{
		_parent.play(_name, reset);
	}
	
	/**
	 * Name of the animation.
	 */
	public var name(get, null):String;
	private inline function get_name():String { return _name; }
	
	/**
	 * Array of frame indices to animate.
	 */
	public var frames(get, null):Array<Int>;
	private inline function get_frames():Array<Int> { return _frames; }
	
	/**
	 * Animation speed.
	 */
	public var frameRate(get, null):Float;
	private inline function get_frameRate():Float { return _frameRate; }
	
	/**
	 * Amount of frames in the animation.
	 */
	public var frameCount(get, null):Int;
	private function get_frameCount():Int { return _frameCount; }
	
	/**
	 * If the animation loops.
	 */
	public var loop(get, null):Bool;
	private function get_loop():Bool { return _loop; }
	
	private var _parent:Spritemap;
	private var _name:String;
	private var _frames:Array<Int>;
	private var _frameRate:Float;
	private var _frameCount:Int;
	private var _loop:Bool;
}
