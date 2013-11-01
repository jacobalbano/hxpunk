package net.hxpunk.masks;

import flash.display.*;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.errors.Error;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.*;
import net.hxpunk.HP;
import net.hxpunk.Mask;

/**
 * Uses a hash grid to determine collision, faster than
 * using hundreds of Entities for tiled levels, etc.
 */
class Grid extends Hitbox
{
	/**
	 * If x/y positions should be used instead of columns/rows.
	 */
	public var usePositions:Bool;
	
	/**
	 * Constructor.
	 * @param	width			Width of the grid, in pixels.
	 * @param	height			Height of the grid, in pixels.
	 * @param	tileWidth		Width of a grid tile, in pixels.
	 * @param	tileHeight		Height of a grid tile, in pixels.
	 * @param	x				X offset of the grid.
	 * @param	y				Y offset of the grid.
	 */
	public function new(width:Int, height:Int, tileWidth:Int, tileHeight:Int, x:Int = 0, y:Int = 0) 
	{
		super();
		
		_rect = HP.rect;
		_point = HP.point;

		// check for illegal grid size
		if (width <= 0 || height <= 0 || tileWidth <= 0 || tileHeight <= 0) throw new Error("Illegal Grid, sizes cannot be 0.");
		
		// set grid properties
		_columns = Std.int(width / tileWidth);
		_rows = Std.int(height / tileHeight);
		_data = new BitmapData(_columns, _rows, true, 0);
		_tile = new Rectangle(0, 0, tileWidth, tileHeight);
		_x = x;
		_y = y;
		_width = width;
		_height = height;
		
		// set callback functions
		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
		_check.set(Type.getClassName(Pixelmask), collidePixelmask);
		_check.set(Type.getClassName(Grid), collideGrid);
	}
	
	/**
	 * Sets the value of the tile.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @param	solid		If the tile should be solid.
	 */
	public function setTile(column:Int = 0, row:Int = 0, solid:Bool = true):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		_data.setPixel32(column, row, solid ? 0xFFFFFFFF : 0);
	}
	
	/**
	 * Makes the tile non-solid.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 */
	public function clearTile(column:Int = 0, row:Int = 0):Void
	{
		setTile(column, row, false);
	}
	
	/**
	 * Gets the value of a tile.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @return	tile value.
	 */
	public function getTile(column:Int = 0, row:Int = 0):Bool
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		return _data.getPixel32(column, row) > 0;
	}
	
	/**
	 * Sets the value of a rectangle region of tiles.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 * @param	solid		If the tiles should be solid.
	 */
	public function setRect(column:Int = 0, row:Int = 0, width:Int = 1, height:Int = 1, solid:Bool = true):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		_rect.x = column;
		_rect.y = row;
		_rect.width = width;
		_rect.height = height;
		_data.fillRect(_rect, solid ? 0xFFFFFFFF : 0);
	}
	
	/**
	 * Makes the rectangular region of tiles non-solid.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 */
	public function clearRect(column:Int = 0, row:Int = 0, width:Int = 1, height:Int = 1):Void
	{
		setRect(column, row, width, height, false);
	}
	
	/**
	* Loads the grid data from a string.
	* @param str			The string data, which is a set of tile values (0 or 1) separated by the columnSep and rowSep strings.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ",", rowSep:String = "\n"):Void
	{
		var row:Array<String> = str.split(rowSep),
			rows:Int = row.length,
			col:Array<String>, cols:Int;
		for (y in 0...rows)
		{
			if (row[y] == '') continue;
			col = row[y].split(columnSep);
			cols = col.length;
			for (x in 0...cols)
			{
				if (col[x] == '') continue;
				setTile(x, y, Std.parseInt(col[x]) > 0);
			}
		}
	}
	
	/**
	* Saves the grid data to a string.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*/
	public function saveToString(columnSep:String = ",", rowSep:String = "\n"): String
	{
		var s:StringBuf = new StringBuf();

		for (y in 0..._rows)
		{
			for (x in 0..._columns)
			{
				s.add(getTile(x, y) ? '1' : '0');
				if (x != _columns - 1) s.add(columnSep);
			}
			if (y != _rows - 1) s.add(rowSep);
		}
		return s.toString();
	}
	
	/**
	 * The tile width.
	 */
	public var tileWidth(get, null):Int;
	private inline function get_tileWidth():Int { return Std.int(_tile.width); }
	
	/**
	 * The tile height.
	 */
	public var tileHeight(get, null):Int;
	private inline function get_tileHeight():Int { return Std.int(_tile.height); }
	
	/**
	 * How many columns the grid has
	 */
	public var columns(get, null):Int;
	private inline function get_columns():Int { return _columns; }
	
	/**
	 * How many rows the grid has.
	 */
	public var rows(get, null):Int;
	private inline function get_rows():Int { return _rows; }
	
	/**
	 * The grid data.
	 */
	public var data(get, null):BitmapData;
	private inline function get_data():BitmapData { return _data; }
	
	/** @private Collides against an Entity. */
	override private function collideMask(other:Mask):Bool
	{
		_rect.x = other.parent.x - other.parent.originX - parent.x + parent.originX;
		_rect.y = other.parent.y - other.parent.originY - parent.y + parent.originY;
		_point.x = Std.int((_rect.x + other.parent.width - 1) / _tile.width) + 1;
		_point.y = Std.int((_rect.y + other.parent.height -1) / _tile.height) + 1;
		_rect.x = Std.int(_rect.x / _tile.width);
		_rect.y = Std.int(_rect.y / _tile.height);
		_rect.width = _point.x - _rect.x;
		_rect.height = _point.y - _rect.y;
		return _data.hitTest(HP.zero, 1, _rect);
	}
	
	/** @private Collides against a Hitbox. */
	override private function collideHitbox(other:Hitbox):Bool
	{
		_rect.x = other.parent.x + other._x - parent.x - _x;
		_rect.y = other.parent.y + other._y - parent.y - _y;
		_point.x = Std.int((_rect.x + other._width - 1) / _tile.width) + 1;
		_point.y = Std.int((_rect.y + other._height -1) / _tile.height) + 1;
		_rect.x = Std.int(_rect.x / _tile.width);
		_rect.y = Std.int(_rect.y / _tile.height);
		_rect.width = _point.x - _rect.x;
		_rect.height = _point.y - _rect.y;
		return _data.hitTest(HP.zero, 1, _rect);
	}
	
	/** @private Collides against a Pixelmask. */
	private function collidePixelmask(other:Pixelmask):Bool
	{
		var x1:Int = Std.int(other.parent.x + other._x - parent.x - _x),
			y1:Int = Std.int(other.parent.y + other._y - parent.y - _y),
			x2:Int = Std.int((x1 + other._width - 1) / _tile.width),
			y2:Int = Std.int((y1 + other._height - 1) / _tile.height);
		_point.x = x1;
		_point.y = y1;
		x1 = Std.int(x1 / _tile.width);
		y1 = Std.int(y1 / _tile.height);
		_tile.x = x1 * _tile.width;
		_tile.y = y1 * _tile.height;
		var xx:Int = x1;
		while (y1 <= y2)
		{
			while (x1 <= x2)
			{
				if (_data.getPixel32(x1, y1) > 0)
				{
					if (other.data.hitTest(_point, 1, _tile)) return true;
				}
				x1 ++;
				_tile.x += _tile.width;
			}
			x1 = xx;
			y1 ++;
			_tile.x = x1 * _tile.width;
			_tile.y += _tile.height;
		}
		return false;
	}
	
	/** @private Collides against a Grid. */
	private function collideGrid(other:Grid):Bool
	{
		// Find the X edges
		var ax1:Float = parent.x + _x;
		var ax2:Float = ax1 + _width;
		var bx1:Float = other.parent.x + other._x;
		var bx2:Float = bx1 + other._width;
		if (ax2 < bx1 || ax1 > bx2) return false;
		
		// Find the Y edges
		var ay1:Float = parent.y + _y;
		var ay2:Float = ay1 + _height;
		var by1:Float = other.parent.y + other._y;
		var by2:Float = by1 + other._height;
		if (ay2 < by1 || ay1 > by2) return false;
		
		// Find the overlapping area
		var ox1:Float = ax1 > bx1 ? ax1 : bx1;
		var oy1:Float = ay1 > by1 ? ay1 : by1;
		var ox2:Float = ax2 < bx2 ? ax2 : bx2;
		var oy2:Float = ay2 < by2 ? ay2 : by2;
		
		// Find the smallest tile size, and snap the top and left overlapping
		// edges to that tile size. This ensures that corner checking works
		// properly.
		var tw:Float, th:Float;
		if (_tile.width < other._tile.width)
		{
			tw = _tile.width;
			ox1 -= parent.x + _x;
			ox1 = Std.int(ox1 / tw) * tw;
			ox1 += parent.x + _x;
		}
		else
		{
			tw = other._tile.width;
			ox1 -= other.parent.x + other._x;
			ox1 = Std.int(ox1 / tw) * tw;
			ox1 += other.parent.x + other._x;
		}
		if (_tile.height < other._tile.height)
		{
			th = _tile.height;
			oy1 -= parent.y + _y;
			oy1 = Std.int(oy1 / th) * th;
			oy1 += parent.y + _y;
		}
		else
		{
			th = other._tile.height;
			oy1 -= other.parent.y + other._y;
			oy1 = Std.int(oy1 / th) * th;
			oy1 += other.parent.y + other._y;
		}
		
		// Step through the overlapping rectangle
		var y:Float = oy1;
		var x:Float = 0;
		while (y < oy2) {
			// Get the row indices for the top and bottom edges of the tile
			var ar1:Int = Std.int((y - parent.y - _y) / _tile.height);
			var br1:Int = Std.int((y - other.parent.y - other._y) / other._tile.height);
			var ar2:Int = Std.int(((y - parent.y - _y) + (th - 1)) / _tile.height);
			var br2:Int = Std.int(((y - other.parent.y - other._y) + (th - 1)) / other._tile.height);
			
			while (x < ox2) {
				// Get the column indices for the left and right edges of the tile
				var ac1:Int = Std.int((x - parent.x - _x) / _tile.width);
				var bc1:Int = Std.int((x - other.parent.x - other._x) / other._tile.width);
				var ac2:Int = Std.int(((x - parent.x - _x) + (tw - 1)) / _tile.width);
				var bc2:Int = Std.int(((x - other.parent.x - other._x) + (tw - 1)) / other._tile.width);
				
				// Check all the corners for collisions
				if ((_data.getPixel32(ac1, ar1) > 0 && other._data.getPixel32(bc1, br1) > 0)
				 || (_data.getPixel32(ac2, ar1) > 0 && other._data.getPixel32(bc2, br1) > 0)
				 || (_data.getPixel32(ac1, ar2) > 0 && other._data.getPixel32(bc1, br2) > 0)
				 || (_data.getPixel32(ac2, ar2) > 0 && other._data.getPixel32(bc2, br2) > 0))
				{
					return true;
				}
				x += tw;
			}
			y += th;
		}
		
		return false;
	}
	
	public override function renderDebug(g:Graphics):Void
	{
		var sx:Float = HP.screen.scaleX * HP.screen.scale;
		var sy:Float = HP.screen.scaleY * HP.screen.scale;
		
		g.lineStyle(1, 0xFFFFFF, 0.25);
		
		for (y in 0..._rows)
		{
			for (x in 0..._columns)
			{
				if (_data.getPixel32(x, y) > 0)
				{
					g.drawRect((parent.x - parent.originX - HP.camera.x + x * _tile.width) * sx, (parent.y - parent.originY - HP.camera.y + y * _tile.height) * sy, _tile.width * sx, _tile.height * sy);
				}
			}
		}
	}
	
	// Grid information.
	/** @private */ private var _data:BitmapData;
	/** @private */ private var _columns:Int = 0;
	/** @private */ private var _rows:Int = 0;
	/** @private */ private var _tile:Rectangle;
	/** @private */ private var _rect:Rectangle;
	/** @private */ private var _point:Point;
}