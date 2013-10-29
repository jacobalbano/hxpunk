package net.hxpunk;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.Lib;
import haxe.Timer;
import net.hxpunk.HP;
import net.hxpunk.Screen;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Input;
import net.hxpunk.World;


/**
 * Main game Sprite class, added to the Flash Stage. Manages the game loop.
 */
class Engine extends Sprite
{
	/**
	 * If the game should stop updating/rendering.
	 */
	public var paused:Bool = false;
	
	/**
	 * Cap on the elapsed time (default at 30 FPS). Raise this to allow for lower framerates (eg. 1 / 10).
	 */
	public var maxElapsed:Float = 0.0333;
	
	/**
	 * The max amount of frames that can be skipped in fixed framerate mode.
	 */
	public var maxFrameSkip:Int = 5;
	
	/**
	 * The amount of milliseconds between ticks in fixed framerate mode.
	 */
	public var tickRate:Int = 4;
	
	/**
	 * Constructor. Defines startup information about your game.
	 * @param	width			The width of your game.
	 * @param	height			The height of your game.
	 * @param	frameRate		The game framerate, in frames per second.
	 * @param	fixed			If a fixed-framerate should be used.
	 */
	public function new(width:Int, height:Int, frameRate:Float = 60, fixed:Bool = false) 
	{
		super();
		
		_frameList = new Array<UInt>();

		// global game properties
		HP.width = width;
		HP.height = height;
		HP.halfWidth = width/2;
		HP.halfHeight = height/2;
		HP.assignedFrameRate = frameRate;
		HP.fixed = fixed;
		HP.timeInFrames = fixed;
		
		// global game objects
		HP.engine = this;
		HP.screen = new Screen();
		HP.bounds = new Rectangle(0, 0, width, height);
		HP._world = new World();
		HP.camera = HP._world.camera;
		Draw.resetTarget();
		
		// miscellaneous startup stuff
		if (HP.randomSeed == 0) HP.randomizeSeed();
		HP.entity = new Entity();
		HP._time = Lib.getTimer();
		
		// on-stage event listener
	#if flash
		if (Lib.current.stage != null) onStage();
		else Lib.current.addEventListener(Event.ADDED_TO_STAGE, onStage);
	#else
		addEventListener(Event.ADDED_TO_STAGE, onStage);
		Lib.current.addChild(this);
	#end
		
		// set trace() for flash targets
	#if (flash9 || flash10)
		haxe.Log.trace = function(v, ?pos) { untyped __global__["trace"](pos.className + "#" + pos.methodName + "(" + pos.lineNumber + "):", v); }
	#elseif flash
		haxe.Log.trace = function(v, ?pos) { flash.Lib.trace(pos.className + "#" + pos.methodName + "(" + pos.lineNumber + "): " + v); }
	#end
	}
	
	/**
	 * Override this, called after Engine has been added to the stage.
	 */
	public function init():Void
	{
		
	}
	
	/**
	 * Updates the game, updating the World and Entities.
	 */
	public function update():Void
	{
		HP._world.updateLists();
		if (HP._goto != null) checkWorld();
		if (HP.tweener.active && HP.tweener._tween != null) HP.tweener.updateTweens();
		if (HP._world.active)
		{
			if (HP._world._tween != null) HP._world.updateTweens();
			HP._world.update();
		}
		HP._world.updateLists(false);
	}
	
	/**
	 * Renders the game, rendering the World and Entities.
	 */
	public function render():Void
	{
		// timing stuff
		var t:Float = Lib.getTimer();
		if (_frameLast <= 0) _frameLast = Std.int(t);
		
		// render loop
		HP.screen.swap();
		Draw.resetTarget();
		HP.screen.refresh();
		if (HP._world.visible) HP._world.render();
		HP.screen.redraw();
		
		// more timing stuff
		t = Lib.getTimer();
		_frameListSum += (_frameList[_frameList.length] = Std.int(t - _frameLast));
		if (_frameList.length > 10) _frameListSum -= _frameList.shift();
		HP.frameRate = 1000 / (_frameListSum / _frameList.length);
		_frameLast = Std.int(t);
	}
	
	/**
	 * Override this; called when game gains focus.
	 */
	public function focusGained():Void
	{
		
	}
	
	/**
	 * Override this; called when game loses focus.
	 */
	public function focusLost():Void
	{
		
	}
	
	/**
	 * Sets the game's stage properties. Override this to set them differently.
	 */
	public function setStageProperties():Void
	{
		stage.frameRate = HP.assignedFrameRate;
		stage.align = StageAlign.TOP_LEFT;
		stage.quality = StageQuality.HIGH;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.displayState = StageDisplayState.NORMAL;
	}
	
	/** @private Event handler for stage entry. */
	private function onStage(e:Event = null):Void
	{
		// remove event listener
	#if flash
		if (e != null)
			Lib.current.removeEventListener(Event.ADDED_TO_STAGE, onStage);
		HP.stage = Lib.current.stage;
		HP.stage.addChild(this);
	#else
		removeEventListener(Event.ADDED_TO_STAGE, onStage);
		HP.stage = stage;
	#end
		
		// add focus change listeners
		stage.addEventListener(Event.ACTIVATE, onActivate);
		stage.addEventListener(Event.DEACTIVATE, onDeactivate);
		
		// set stage properties
		setStageProperties();
		
		// enable input
		Input.enable();
		
		// switch worlds
		if (HP._goto != null) checkWorld();
		
		// game start
		init();
		
		// start game loop
		_rate = 1000 / HP.assignedFrameRate;
		if (HP.fixed)
		{
			// fixed framerate
			_skip = _rate * (maxFrameSkip + 1);
			_last = _prev = Lib.getTimer();
			_timer = new Timer(tickRate);
			_timer.run = onTimer;
		}
		else
		{
			// nonfixed framerate
			_last = Lib.getTimer();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	}
	
	/** @private Framerate independent game loop. */
	private function onEnterFrame(e:Event):Void
	{
		// update timer
		_time = _gameTime = Lib.getTimer();
		HP._systemTime = Std.int(_time - _flashTime);
		_updateTime = Std.int(_time);
		HP.elapsed = (_time - _last) / 1000;
		if (HP.elapsed > maxElapsed) HP.elapsed = maxElapsed;
		HP.elapsed *= HP.rate;
		_last = _time;
		
		// update console
		if (HP._console != null) HP._console.update();
		
		// update loop
		if (!paused) update();
		
		// update input
		Input.update();
		
		// update timer
		_time = _renderTime = Lib.getTimer();
		HP._updateTime = Std.int(_time - _updateTime);
		
		// render loop
		if (!paused) render();
		
		// update timer
		_time = Lib.getTimer();
		_flashTime = Std.int(_time);
		HP._renderTime = Std.int(_time - _renderTime);
		HP._logicTime = Std.int(_time - _gameTime);
	}
	
	/** @private Fixed framerate game loop. */
	private function onTimer(/*e:TimerEvent=null*/):Void
	{
		// update timer
		_time = Lib.getTimer();
		_delta += (_time - _last);
		_last = _time;
		
		// quit if a frame hasn't passed
		if (_delta < _rate) return;
		
		// update timer
		_gameTime = Std.int(_time);
		HP._systemTime = Std.int(_time - _flashTime);
		
		// update console
		if (HP._console != null) HP._console.update();
		
		// update loop
		if (_delta > _skip) _delta = _skip;
		while (_delta >= _rate)
		{
			HP.elapsed = _rate * HP.rate * 0.001;
			
			// update timer
			_updateTime = Std.int(_time);
			_delta -= _rate;
			_prev = _time;
			
			// update loop
			if (!paused) update();
			
			// update input
			Input.update();
			
			// update timer
			_time = Lib.getTimer();
			HP._updateTime = Std.int(_time - _updateTime);
		}
		
		// update timer
		_renderTime = Std.int(_time);
		
		// render loop
		if (!paused) render();
		
		// update timer
		_time = _flashTime = Lib.getTimer();
		HP._renderTime = Std.int(_time - _renderTime);
		HP._logicTime =  Std.int(_time - _gameTime);
	}
	
	/** @private Switch Worlds if they've changed. */
	private function checkWorld():Void
	{
		if (HP._goto == null) return;
		HP._world.end();
		HP._world.updateLists();
		if (HP._world != null && HP._world.autoClear && HP._world._tween != null) HP._world.clearTweens();
		HP._world = HP._goto;
		HP._goto = null;
		HP.camera = HP._world.camera;
		HP._world.updateLists();
		HP._world.begin();
		HP._world.updateLists();
	}
	
	private function onActivate (e:Event):Void
	{
		HP.focused = true;
		focusGained();
		HP.world.focusGained();
	}
	
	private function onDeactivate (e:Event):Void
	{
		HP.focused = false;
		focusLost();
		HP.world.focusLost();
	}
	
	// Timing information.
	/** @private */ private var _delta:Float = 0;
	/** @private */ private var _time:Float = 0;
	/** @private */ private var _last:Float = 0;
	/** @private */ private var _timer:Timer;
	/** @private */ private var	_rate:Float = 0;
	/** @private */ private var	_skip:Float = 0;
	/** @private */ private var _prev:Float = 0;
	
	// Debug timing information.
	/** @private */ private var _updateTime:Int = 0;
	/** @private */ private var _renderTime:Int = 0;
	/** @private */ private var _gameTime:Int = 0;
	/** @private */ private var _flashTime:Int = 0;
	
	// FrameRate tracking.
	/** @private */ private var _frameLast:Int = 0;
	/** @private */ private var _frameListSum:Int = 0;
	/** @private */ private var _frameList:Array<UInt>;
}
