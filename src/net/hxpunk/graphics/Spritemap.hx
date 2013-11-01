package net.hxpunk.graphics;

import flash.geom.Rectangle;
import net.hxpunk.graphics.Anim;


typedef AnimCompleteCallback = Void -> Void;

/**
 * Performance-optimized animated Image. Can have multiple animations,
 * which draw frames from the provided source image to the screen.
 */
class Spritemap extends Image
{
	/**
	 * If the animation has stopped.
	 */
	public var complete:Bool = true;
	
	/**
	 * Optional callback function for animation end.
	 */
	public var callback:AnimCompleteCallback;
	
	/**
	 * Animation speed factor, alter this to speed up/slow down all animations.
	 */
	public var rate:Float = 1;
	
	/**
	 * Constructor.
	 * @param	source			Source image.
	 * @param	frameWidth		Frame width.
	 * @param	frameHeight		Frame height.
	 * @param	callback		Optional callback function for animation end.
	 */
	public function new(source:Dynamic, frameWidth:Int = 0, frameHeight:Int = 0, callback:AnimCompleteCallback = null) 
	{
		_anims = new Map<String, Anim>();
		_rect = new Rectangle(0, 0, frameWidth, frameHeight);
		_clipRect = new Rectangle(0, 0, frameWidth, frameHeight);
		_frameWidth = frameWidth;
		_frameHeight = frameHeight;
		super(source, _rect);
		if (frameWidth <= 0)
		{
			_rect.width = this.source.width;
			_clipRect.width = this.source.width;
			_frameWidth = this.source.width;
		}
		if (frameHeight <= 0)
		{
			_rect.height = this.source.height;
			_clipRect.height = this.source.height;
			_frameHeight = this.source.height;
		}
		_width = this.source.width;
		_height = this.source.height;
		_columns = Math.ceil(_width / _rect.width);
		_rows = Math.ceil(_height / _rect.height);
		_frameCount = _columns * _rows;
		this.callback = callback;
		updateBuffer();
		active = true;
	}
	
	/**
	 * Updates the spritemap's buffer.
	 */
	override public function updateBuffer(clearBefore:Bool = false):Void 
	{
		// get position of the current frame
		_rect.x = _frameWidth * (_frame % _columns);
		_rect.y = _frameHeight * Std.int(_frame / _columns) + _clipRect.y;
		if (_flipped) _rect.x = (_width - _frameWidth) - _rect.x + _clipRect.x;
		else _rect.x += _clipRect.x;
		
		_rect.width = _clipRect.width;
		_rect.height = _clipRect.height;
		
		if (_clipRect.x + _clipRect.width > _frameWidth) _rect.width -= _clipRect.x + _clipRect.width - _frameWidth;
		if (_clipRect.y + _clipRect.height > _frameHeight) _rect.height -= _clipRect.y + _clipRect.height - _frameHeight;
		
		// update the buffer
		super.updateBuffer(clearBefore);
	}
	
	/** @private Updates the animation. */
	override public function update():Void 
	{
		if (_anim != null && !complete)
		{
			var timeAdd:Float = _anim.frameRate * rate;
			if (!HP.timeInFrames) timeAdd *= HP.elapsed;
			_timer += timeAdd;
			if (_timer >= 1)
			{
				while (_timer >= 1)
				{
					_timer --;
					_index ++;
					if (_index == _anim.frameCount)
					{
						if (_anim.loop)
						{
							_index = 0;
							if (callback != null) callback();
						}
						else
						{
							_index = _anim.frameCount - 1;
							complete = true;
							if (callback != null) callback();
							break;
						}
					}
				}
				if (_anim != null) _frame = Std.int(_anim.frames[_index]);
				updateBuffer();
			}
		}
	}
	
	/**
	 * Add an Animation.
	 * @param	name		Name of the animation.
	 * @param	frames		Array of frame indices to animate through.
	 * @param	frameRate	Animation speed (with variable framerate: in frames per second, with fixed framerate: in frames per frame).
	 * @param	loop		If the animation should loop.
	 * @return	A new Anim object for the animation.
	 */
	public function add(name:String, frames:Array<Int>, frameRate:Float = 0, loop:Bool = true):Anim
	{
		for (i in 0...frames.length) {
			frames[i] %= _frameCount;
			if (frames[i] < 0) frames[i] += _frameCount;
		}
		var newAnim:Anim = new Anim(name, frames, frameRate, loop);
		_anims[name] = newAnim;
		_friendlyAnim = newAnim;
		_friendlyAnim._parent = this;
		return newAnim;
	}
	
	/**
	 * Plays an animation.
	 * @param	name		Name of the animation to play.
	 * @param	reset		If the animation should force-restart if it is already playing.
	 * @param	frame		Frame of the animation to start from, if restarted.
	 * @return	Anim object representing the played animation.
	 */
	public function play(name:String = "", reset:Bool = false, frame:Int = 0):Anim
	{	
		if (!reset && _anim != null && _anim.name == name) return _anim;
		_anim = _anims[name];
		if (_anim == null)
		{
			_frame = _index = 0;
			complete = true;
			updateBuffer();
			return null;
		}
		_index = 0;
		_timer = 0;
		_frame = Std.int(_anim.frames[frame % _anim.frameCount]);
		complete = false;
		updateBuffer();
		return _anim;
	}
	
	/**
	 * Gets the frame index based on the column and row of the source image.
	 * @param	column		Frame column.
	 * @param	row			Frame row.
	 * @return	Frame index.
	 */
	public function getFrame(column:Int = 0, row:Int = 0):Int
	{
		return (row % _rows) * _columns + (column % _columns);
	}
	
	/**
	 * Sets the current display frame based on the column and row of the source image.
	 * When you set the frame, any animations playing will be stopped to force the frame.
	 * @param	column		Frame column.
	 * @param	row			Frame row.
	 */
	public function setFrame(column:Int = 0, row:Int = 0):Void
	{
		_anim = null;
		var frame:Int = (row % _rows) * _columns + (column % _columns);
		if (_frame == frame) return;
		_frame = frame;
		_timer = 0;
		updateBuffer();
	}
	
	/**
	 * Assigns the Spritemap to a random frame.
	 */
	public function randFrame():Void
	{
		frame = HP.rand(frameCount);
	}
	
	/**
	 * Sets the frame to the frame index of an animation.
	 * @param	name	Animation to draw the frame frame.
	 * @param	index	Index of the frame of the animation to set to.
	 */
	public function setAnimFrame(name:String, index:Int):Void
	{
		var frames:Array<Int> = _anims[name].frames;
		index %= frames.length;
		if (index < 0) index += frames.length;
		frame = frames[index];
	}
	
	/**
	 * Sets the current frame index. When you set this, any
	 * animations playing will be stopped to force the frame.
	 */
	public var frame(get, set):Int;
	private inline function get_frame():Int { return _frame; }
	private function set_frame(value:Int):Int
	{
		_anim = null;
		value %= _frameCount;
		if (value < 0) value = _frameCount + value;
		if (_frame == value) return value;
		_frame = value;
		_timer = 0;
		updateBuffer();
		return value;
	}
	
	/**
	 * Current index of the playing animation.
	 */
	public var index(get, set):Int;
	private inline function get_index():Int { return _anim != null ? _index : 0; }
	private function set_index(value:Int):Int
	{
		if (_anim == null) return -1;
		value %= _anim.frameCount;
		if (_index == value) return value;
		_index = value;
		_frame = Std.int(_anim.frames[_index]);
		_timer = 0;
		updateBuffer();
		return value;
	}
	
	/**
	 * The amount of frames in the Spritemap.
	 */
	public var frameCount(get, null):Int;
	private inline function get_frameCount():Int { return _frameCount; }
	
	/**
	 * Columns in the Spritemap.
	 */
	public var columns(get, null):Int;
	private inline function get_columns():Int { return _columns; }
	
	/**
	 * Rows in the Spritemap.
	 */
	public var rows(get, null):Int;
	private inline function get_rows():Int { return _rows; }
	
	/**
	 * The currently playing animation.
	 */
	public var currentAnim(get, null):String;
	private inline function get_currentAnim():String { return _anim != null ? _anim.name : ""; }
	
	/**
	 * Clipping rectangle for the spritemap.
	 */
	override private function get_clipRect():Rectangle 
	{
		return _clipRect;
	}
	
	// Spritemap information.
	/** @private */ private var _rect:Rectangle;
	/** @private */ private var _clipRect:Rectangle;
	/** @private */ private var _width:Int = 0;
	/** @private */ private var _height:Int = 0;
	/** @private */ private var _frameWidth:Int = 0;
	/** @private */ private var _frameHeight:Int = 0;
	/** @private */ private var _columns:Int = 0;
	/** @private */ private var _rows:Int = 0;
	/** @private */ private var _frameCount:Int = 0;
	/** @private */ private var _anims:Map<String, Anim>;
	/** @private */ private var _anim:Anim;
	/** @private */ private var _index:Int = 0;
	/** @private */ private var _frame:Int = 0;
	/** @private */ private var _timer:Float = 0;
	/** @private */ private var _friendlyAnim:FriendlyAnim;
}
