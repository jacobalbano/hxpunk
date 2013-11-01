package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import net.hxpunk.HP;

/**
 * Creates a pre-rotated Image strip to increase runtime performance for rotating graphics.
 */
class PreRotation extends Image
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * Current angle to fetch the pre-rotated frame from.
	 */
	public var frameAngle:Float = 0;
	
	/**
	 * Whether to automatically change frameAngle when angle is modified.
	 */
	public var syncFrameAngle:Bool = true;
	
	
	
	private static inline function initStaticVars():Bool 
	{
		_rotated = new Map<String, BitmapData>();
		_size = new Map<String, Int>();
		
		return true;
	}

	/**
	 * Constructor.
	 * @param	source			The source image to be rotated.
	 * @param	frameCount		How many frames to use. More frames result in smoother rotations.
	 * @param	syncFrameAngle	Whether to automatically change frameAngle when angle is modified.
	 * @param	smooth			Make the rotated graphic appear less pixelly.
	 */
	public function new(source:Dynamic, frameCount:Int = 36, syncFrameAngle:Bool = true, smooth:Bool = false) 
	{
		var name = Std.string(source);
		var r:BitmapData = _rotated[name];
		_frame = new Rectangle(0, 0, _size[name], _size[name]);
		if (r == null)
		{
			// produce a rotated bitmap strip
			var temp:BitmapData = HP.getBitmap(source),
				size:Int = _size[name] = Math.ceil(HP.distance(0, 0, temp.width, temp.height));
			_frame.width = _frame.height = size;
			var width:Int = Std.int(_frame.width * frameCount),
				height:Int = Std.int(_frame.height);
			if (width > _MAX_WIDTH)
			{
				width = Std.int(_MAX_WIDTH - (_MAX_WIDTH % _frame.width));
				height = Std.int(Math.ceil(frameCount / (width / _frame.width)) * _frame.height);
			}
			_rotated[name] = r = new BitmapData(width, height, true, 0);
			var m:Matrix = HP.matrix,
				a:Float = 0,
				aa:Float = (Math.PI * 2) / -frameCount,
				ox:Int = temp.width >> 1,
				oy:Int = temp.height >> 1,
				o:Int = Std.int(_frame.width) >> 1,
				x:Int = 0,
				y:Int = 0;
			while (y < height)
			{
				while (x < width)
				{
					m.identity();
					m.translate(-ox, -oy);
					m.rotate(a);
					m.translate(o + x, o + y);
					r.draw(temp, m, null, null, null, smooth);
					x += Std.int(_frame.width);
					a += aa;
				}
				x = 0;
				y += Std.int(_frame.height);
			}
		}
		_source = r;
		_width = r.width;
		_frameCount = frameCount;
		this.syncFrameAngle = syncFrameAngle;
		super(_source, _frame);
	}
	
	/** @private Renders the PreRotated graphic. */
	override public function render(target:BitmapData, point:Point, camera:Point):Void 
	{
		var _angle:Float = angle;
		if (syncFrameAngle) frameAngle = angle;
		frameAngle %= 360;
		if (frameAngle < 0) frameAngle += 360;
		_current = Std.int(_frameCount * (frameAngle / 360));
		if (_last != _current)
		{
			_last = _current;
			_frame.x = _frame.width * _last;
			_frame.y = Std.int(_frame.x / _width) * _frame.height;
			_frame.x %= _width;
			updateBuffer();
		}
		angle = 0;
		super.render(target, point, camera);
		angle = _angle;
	}
	
	// Rotation information.
	/** @private */ private var _width:Int = 0;
	/** @private */ private var _frame:Rectangle;
	/** @private */ private var _frameCount:Int = 0;
	/** @private */ private var _last:Int = -1;
	/** @private */ private var _current:Int = -1;
	
	// Global information.
	/** @private */ private static var _rotated:Map<String, BitmapData>;
	/** @private */ private static var _size:Map<String, Int>;
	/** @private */ private static inline var _MAX_WIDTH:Int = 4000;

}