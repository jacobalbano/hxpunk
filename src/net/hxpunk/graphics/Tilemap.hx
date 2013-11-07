package net.hxpunk.graphics; 

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.Rectangle;

import net.hxpunk.HP;
import net.hxpunk.masks.Grid;
import net.hxpunk.utils.Draw;


/**
 * A canvas to which Tiles can be drawn for fast multiple tile rendering.
 */
class Tilemap extends Canvas
{
	/**
	 * If x/y positions should be used instead of columns/rows.
	 */
	public var usePositions:Bool = false;
	
	/**
	 * Constructor.
	 * @param	tileset			The source tileset image.
	 * @param	width			Width of the tilemap, in pixels.
	 * @param	height			Height of the tilemap, in pixels.
	 * @param	tileWidth		Tile width.
	 * @param	tileHeight		Tile height.
	 */
	public function new(tileset:Dynamic, width:Int, height:Int, tileWidth:Int, tileHeight:Int)
	{
		// set some tilemap information
		_width = width;
		_height = height;
		_columns = Math.ceil(_width / tileWidth);
		_rows = Math.ceil(_height / tileHeight);
		_map = new BitmapData(_columns, _rows, false, 0);
		_temp = _map.clone();
		_tile = new Rectangle(0, 0, tileWidth, tileHeight);
		
		// create the canvas
		_maxWidth -= _maxWidth % tileWidth;
		_maxHeight -= _maxHeight % tileHeight;
		super(_width, _height);
		
		// load the tileset graphic
		_set = HP.getBitmapData(tileset);
		if (_set == null) throw new Error("Invalid tileset graphic provided.");
		_setColumns = Math.ceil(_set.width / tileWidth);
		_setRows = Math.ceil(_set.height / tileHeight);
		_setCount = _setColumns * _setRows;
	}
	
	/**
	 * Sets the index of the tile at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @param	index		Tile index.
	 */
	public function setTile(column:Int, row:Int, index:Int = 0):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		index %= _setCount;
		column %= _columns;
		row %= _rows;
		_tile.x = (index % _setColumns) * _tile.width;
		_tile.y = Std.int(index / _setColumns) * _tile.height;
		_point.x = column * _tile.width;
		_point.y = row * _tile.height;
		_map.setPixel(column, row, index);
		copyPixels(_set, _tile, _point, null, null, false);
	}
	
	/**
	 * Clears the tile at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 */
	public function clearTile(column:Int, row:Int):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		_tile.x = column * _tile.width;
		_tile.y = row * _tile.height;
		fill(_tile, 0, 0);
	}
	
	/**
	 * Gets the tile index at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @return	The tile index.
	 */
	public function getTile(column:Int, row:Int):Int
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		return _map.getPixel(column % _columns, row % _rows);
	}
	
	/**
	 * Sets a rectangular region of tiles to the index.
	 * @param	column		First tile column.
	 * @param	row			First tile row.
	 * @param	width		Width in tiles.
	 * @param	height		Height in tiles.
	 * @param	index		Tile index.
	 */
	public function setRect(column:Int, row:Int, width:Int = 1, height:Int = 1, index:Int = 0):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		var c:Int = column,
			r:Int = column + width,
			b:Int = row + height,
			u:Bool = usePositions;
		usePositions = false;
		while (row < b)
		{
			while (column < r)
			{
				setTile(column, row, index);
				column ++;
			}
			column = c;
			row ++;
		}
		usePositions = u;
	}
	
	/**
	 * Makes a flood fill on the tilemap
	 * @param	column		Column to place the flood fill
	 * @param	row			Row to place the flood fill
	 * @param	index		Tile index.
	 */
	public function floodFill(column:Int, row:Int, index:Int = 0):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		
		column %= _columns;
		row %= _rows;
		
		_map.floodFill(column, row, index);
		
		updateAll();
	}
	
	/**
	 * Draws a line of tiles
	 *  
	 * @param	x1		The x coordinate to start
	 * @param	y1		The y coordinate to start
	 * @param	x2		The x coordinate to end
	 * @param	y2		The y coordinate to end
	 * @param	id		The tiles id to draw
	 * 
	 */		
	public function line(x1:Int, y1:Int, x2:Int, y2:Int, id:Int):Void
	{
		if (usePositions)
		{
			x1 = Std.int(x1 / _tile.width);
			y1 = Std.int(_tile.height);
			x2 = Std.int(_tile.width);
			y2 = Std.int(_tile.height);
		}
		
		x1 %= _columns;
		y1 %= _rows;
		x2 %= _columns;
		y2 %= _rows;
		
		Draw.setTarget(_map);
		Draw.line(x1, y1, x2, y2, id, 0);
		updateAll();
	}
	
	/**
	 * Draws an outline of a rectangle of tiles
	 *  
	 * @param	x		The x coordinate of the rectangle
	 * @param	y		The y coordinate of the rectangle
	 * @param	width	The width of the rectangle
	 * @param	height	The height of the rectangle
	 * @param	id		The tiles id to draw
	 * 
	 */		
	public function setRectOutline(x:Int, y:Int, width:Int, height:Int, id:Int):Void
	{
		if (usePositions)
		{
			x = Std.int(x / _tile.width);
			y = Std.int(y / _tile.height);
			
			// TODO: might want to use difference between converted start/end coordinates instead?
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		
		x %= _columns;
		y %= _rows;
		
		Draw.setTarget(_map);
		Draw.line(x, y, x + width, y, id, 0);
		Draw.line(x, y + height, x + width, y + height, id, 0);
		Draw.line(x, y, x, y + height, id, 0);
		Draw.line(x + width, y, x + width, y + height, id, 0);
		updateAll();
	}
	
	/**
	 * Updates the graphical cache for the whole tilemap.
	 */		
	public function updateAll():Void
	{
		_rect.x = 0;
		_rect.y = 0;
		_rect.width = _columns;
		_rect.height = _rows;
		updateRect(_rect, false);
	}
	
	/**
	 * Clears the rectangular region of tiles.
	 * @param	column		First tile column.
	 * @param	row			First tile row.
	 * @param	width		Width in tiles.
	 * @param	height		Height in tiles.
	 */
	public function clearRect(column:Int, row:Int, width:Int = 1, height:Int = 1):Void
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		var c:Int = column,
			r:Int = column + width,
			b:Int = row + height,
			u:Bool = usePositions;
		usePositions = false;
		while (row < b)
		{
			while (column < r)
			{
				clearTile(column, row);
				column ++;
			}
			column = c;
			row ++;
		}
		usePositions = u;
	}
	
	/**
	* Loads the Tilemap tile index data from a string.
	* @param str			The string data, which is a set of tile values separated by the columnSep and rowSep strings.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ",", rowSep:String = "\n"):Void
	{
		var u:Bool = usePositions;
		usePositions = false;
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
				setTile(x, y, Std.parseInt(col[x]));
			}
		}
		
		usePositions = u;
	}
	
	/**
	* Saves the Tilemap tile index data to a string.
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
				s.add(Std.string(_map.getPixel(x, y)));
				if (x != _columns - 1) s.add(columnSep);
			}
			if (y != _rows - 1) s.add(rowSep);
		}
		return s.toString();
	}
	
	/**
	 * Gets the 1D index of a tile from a 2D index (its column and row in the tileset image).
	 * @param	tilesColumn		Tileset column.
	 * @param	tilesRow		Tileset row.
	 * @return	Index of the tile.
	 */
	public function getIndex(tilesColumn:Int, tilesRow:Int):Int
	{
		if (usePositions) {
			tilesColumn = Std.int(tilesColumn / _tile.width);
			tilesRow = Std.int(tilesRow / _tile.height);
		}
		
		return (tilesRow % _setRows) * _setColumns + (tilesColumn % _setColumns);
	}
	
	/**
	 * Shifts all the tiles in the tilemap.
	 * @param	columns		Horizontal shift.
	 * @param	rows		Vertical shift.
	 * @param	wrap		If tiles shifted off the canvas should wrap around to the other side.
	 */
	public function shiftTiles(columns:Int, rows:Int, wrap:Bool = false):Void
	{
		if (usePositions)
		{
			columns = Std.int(columns / _tile.width);
			rows = Std.int(rows / _tile.height);
		}
		
		if (!wrap) _temp.fillRect(_temp.rect, 0);
		
		if (columns != 0)
		{
			shift(Std.int(columns * _tile.width), 0);
			if (wrap) _temp.copyPixels(_map, _map.rect, HP.zero);
			_map.scroll(columns, 0);
			_point.y = 0;
			_point.x = columns > 0 ? columns - _columns : columns + _columns;
			_map.copyPixels(_temp, _temp.rect, _point);
			
			_rect.x = columns > 0 ? 0 : _columns + columns;
			_rect.y = 0;
			_rect.width = Math.abs(columns);
			_rect.height = _rows;
			updateRect(_rect, !wrap);
		}
		
		if (rows != 0)
		{
			shift(0, Std.int(rows * _tile.height));
			if (wrap) _temp.copyPixels(_map, _map.rect, HP.zero);
			_map.scroll(0, rows);
			_point.x = 0;
			_point.y = rows > 0 ? rows - _rows : rows + _rows;
			_map.copyPixels(_temp, _temp.rect, _point);
			
			_rect.x = 0;
			_rect.y = rows > 0 ? 0 : _rows + rows;
			_rect.width = _columns;
			_rect.height = Math.abs(rows);
			updateRect(_rect, !wrap);
		}
	}
	
	/**
	 * Get a subregion of the tilemap and return it as a new Tilemap.
	 */
	public function getSubMap (x:Int, y:Int, w:Int, h:Int):Tilemap
	{
		if (usePositions) {
			x = Std.int(x / _tile.width);
			y = Std.int(y / _tile.height);
			w = Std.int(w / _tile.width);
			h = Std.int(h / _tile.height);
		}
		
		var newMap:Tilemap = new Tilemap(_set, Std.int(w*_tile.width), Std.int(h*_tile.height), Std.int(_tile.width), Std.int(_tile.height));
		
		_rect.x = x;
		_rect.y = y;
		_rect.width = w;
		_rect.height = h;
		
		newMap._map.copyPixels(_map, _rect, HP.zero);
		newMap.drawGraphic(Std.int(-x * _tile.width), Std.int(-y * _tile.height), this);
		
		return newMap;
	}
	
	/** Updates the graphical cache of a region of the tilemap. */
	public function updateRect(rect:Rectangle, clear:Bool):Void
	{
		var x:Int = Std.int(rect.x),
			y:Int = Std.int(rect.y),
			w:Int = Std.int(x + rect.width),
			h:Int = Std.int(y + rect.height),
			u:Bool = usePositions;
		usePositions = false;
		if (clear)
		{
			while (y < h)
			{
				while (x < w) clearTile(x ++, y);
				x = Std.int(rect.x);
				y ++;
			}
		}
		else
		{
			while (y < h)
			{
				while (x < w) updateTile(x ++, y);
				x = Std.int(rect.x);
				y ++;
			}
		}
		usePositions = u;
	}
	
	/** @private Used by shiftTiles to update a tile from the tilemap. */
	private function updateTile(column:Int, row:Int):Void
	{
		setTile(column, row, _map.getPixel(column % _columns, row % _rows));
	}
	
	/**
	* Create or initialise a Grid object from this tilemap.
	* @param	solidTiles		Array of tile indexes that should be solid.
	* @param	grid			Grid object to populate.
	* @return Grid
	*/
	public function createGrid(solidTiles:Array<Int>, gridInput:Dynamic = null):Grid
	{
		
		var grid:Grid = null;
		var cls:Class<Grid> = null;
		
		if (Std.is(gridInput, Grid)) grid = gridInput;
		else if (Std.is(gridInput, Class)) cls = gridInput;
		else cls = Grid;
		
		if (grid == null) {
			grid = Type.createInstance(cls, [width, height, _tile.width, _tile.height, 0]);
		}
		
		for (row in 0..._rows)
		{
			for (col in 0..._columns)
			{
				if (HP.indexOf(solidTiles, _map.getPixel(col, row)) >= 0)
				{
					grid.setTile(col, row, true);
				}
			}
		}
		return grid;
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
	 * How many tiles the tilemap has.
	 */
	public var tileCount(get, null):Int;
	private inline function get_tileCount():Int { return _setCount; }
	
	/**
	 * How many columns the tilemap has.
	 */
	public var columns(get, null):Int;
	private inline function get_columns():Int { return _columns; }
	
	/**
	 * How many rows the tilemap has.
	 */
	public var rows(get, null):Int;
	private inline function get_rows():Int { return _rows; }
	
	// Tilemap information.
	/** @private */ private var _map:BitmapData;
	/** @private */ private var _temp:BitmapData;
	/** @private */ private var _columns:Int = 0;
	/** @private */ private var _rows:Int = 0;
	
	// Tileset information.
	/** @private */ private var _set:BitmapData;
	/** @private */ private var _setColumns:Int = 0;
	/** @private */ private var _setRows:Int = 0;
	/** @private */ private var _setCount:Int = 0;
	/** @private */ private var _tile:Rectangle;
}