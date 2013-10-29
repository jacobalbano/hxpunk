package net.hxpunk;

import flash.geom.Point;

/**
 * Updated by Engine, main game container that holds all currently active Entities.
 * Useful for organization, eg. "Menu", "Level1", etc.
 */
class World extends Tweener
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * If the render() loop is performed.
	 */
	public var visible:Bool = true;
	
	/**
	 * Point used to determine drawing offset in the render loop.
	 */
	public var camera:Point;
	
	/**
	 * Constructor.
	 */
	public function new() 
	{
		super();
		
		initVars();
	}
	
	public static inline function initStaticVars():Bool 
	{
		_recycled = new Map < String, Entity > ();
		
		return true;
	}
	
	public inline function initVars():Void 
	{
		camera = new Point();
		
		// Adding and removal.
		_add = new Array<Entity>();
		_remove = new Array<Entity>();
		_recycle = new Array<Entity>();
		
		// Render information.
		_renderFirst = new Array<Entity>();
		_renderLast = new Array<Entity>();
		_layerList = new Array<Int>();
		_layerCount = new Array<Int>();
		_classCount = new Map<String, UInt>();
		
		_typeFirst = new Map<String, Entity>();
		_typeCount = new Map<String, UInt>();
		
		_entityNames = new Map<String, Entity>();
	}
	
	/**
	 * Override this; called when World is switch to, and set to the currently active world.
	 */
	public function begin():Void
	{
		
	}
	
	/**
	 * Override this; called when World is changed, and the active world is no longer this.
	 */
	public function end():Void
	{
		
	}
	
	/**
	 * Performed by the game loop, updates all contained Entities.
	 * If you override this to give your World update code, remember
	 * to call super.update() or your Entities will not be updated.
	 */
	override public function update():Void 
	{
		// update the entities
		var e:Entity = _updateFirst;
		while (e != null)
		{
			if (e.active)
			{
				if (e._tween != null) e.updateTweens();
				e.update();
			}
			if (e._graphic != null && e._graphic.active) e._graphic.update();
			e = e._updateNext;
		}
	}
	
	/**
	 * Performed by the game loop, renders all contained Entities.
	 * If you override this to give your World render code, remember
	 * to call super.render() or your Entities will not be rendered.
	 */
	public function render():Void 
	{
		// sort the depth list
		if (_layerSort)
		{
			if (_layerList.length > 1) HP.sort(_layerList, true);
			_layerSort = false;
		}
		
		// render the entities in order of depth
		var e:Entity,
			i:Int = _layerList.length;
		while (i -- > 0)
		{
			e = _renderLast[_layerList[i]];
			while (e != null)
			{
				if (e.visible) e.render();
				e = e._renderPrev;
			}
		}
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
	 * X position of the mouse in the World.
	 */
	public var mouseX(get, null):Int;
	private inline function get_mouseX()
	{
		return Std.int(HP.screen.mouseX + camera.x);
	}
	
	/**
	 * Y position of the mouse in the world.
	 */
	public var mouseY(get, null):Int;
	private inline function get_mouseY()
	{
		return Std.int(HP.screen.mouseY + camera.y);
	}
	
	/**
	 * Adds the Entity to the World at the end of the frame.
	 * @param	e		Entity object you want to add.
	 * @return	The added Entity object.
	 */
	public function add(e:Entity):Entity
	{
		_add[_add.length] = e;
		return e;
	}
	
	/**
	 * Removes the Entity from the World at the end of the frame.
	 * @param	e		Entity object you want to remove.
	 * @return	The removed Entity object.
	 */
	public function remove(e:Entity):Entity
	{
		_remove[_remove.length] = e;
		return e;
	}
	
	/**
	 * Removes all Entities from the World at the end of the frame.
	 */
	public function removeAll():Void
	{
		var e:Entity = _updateFirst;
		while (e != null)
		{
			_remove[_remove.length] = e;
			e = e._updateNext;
		}
	}
	
	/**
	 * Adds multiple Entities to the world.
	 * @param	list		Several Entities (as arguments) or an Array/Vector of Entities.
	 */
	public var addList(get, null):Dynamic;
	private inline function get_addList()
	{
		return Reflect.makeVarArgs(_addList);
	}
	private function _addList(list:Array<Dynamic>):Dynamic
	{
		var e:Entity;
		if (Std.is(list[0], Array))
		{
			var v:Array<Dynamic> = cast(list[0], Array<Dynamic>);
			for (e in v) add(e);
			return null;
		}
		for (e in list) add(e);
		return null;
	}
	
	/**
	 * Removes multiple Entities from the world.
	 * @param	list		Several Entities (as arguments) or an Array/Vector of Entities.
	 */
	public var removeList(get, null):Dynamic;
	private inline function get_removeList()
	{
		return Reflect.makeVarArgs(_removeList);
	}
	private function _removeList(list:Array<Dynamic>):Dynamic
	{
		var e:Entity;
		if (Std.is(list[0], Array))
		{
			var v:Array<Dynamic> = cast(list[0], Array<Dynamic>);
			for (e in v) remove(e);
			return null;
		}
		for (e in list) remove(e);
		return null;
	}
	
	/**
	 * Adds an Entity to the World with the Graphic object.
	 * @param	graphic		Graphic to assign the Entity.
	 * @param	x			X position of the Entity.
	 * @param	y			Y position of the Entity.
	 * @param	layer		Layer of the Entity.
	 * @return	The Entity that was added.
	 */
	public function addGraphic(graphic:Graphic, layer:Int = 0, x:Float = 0, y:Float = 0):Entity
	{
		var e:Entity = new Entity(x, y, graphic);
		if (layer != 0) e.layer = layer;
		e.active = false;
		return add(e);
	}
	
	/**
	 * Adds an Entity to the World with the Mask object.
	 * @param	mask	Mask to assign the Entity.
	 * @param	type	Collision type of the Entity.
	 * @param	x		X position of the Entity.
	 * @param	y		Y position of the Entity.
	 * @return	The Entity that was added.
	 */
	public function addMask(mask:Mask, type:String, x:Int = 0, y:Int = 0):Entity
	{
		var e:Entity = new Entity(x, y, null, mask);
		if (type != null) e.type = type;
		e.active = e.visible = false;
		return add(e);
	}
	
	/**
	 * Returns a new Entity, or a stored recycled Entity if one exists.
	 * @param	classType		The Class of the Entity you want to add.
	 * @param	addToWorld		Add it to the World immediately.
	 * @return	The new Entity object.
	 */
	public function create(classType:Class<Entity>, addToWorld:Bool = true):Entity
	{
		var className:String = Type.getClassName(classType);
		var e:Entity = _recycled[className];
		if (e != null)
		{
			_recycled[className] = e._recycleNext;
			e._recycleNext = null;
		}
		else e = Type.createInstance(classType, []);
		if (addToWorld) return add(e);
		return e;
	}
	
	/**
	 * Removes the Entity from the World at the end of the frame and recycles it.
	 * The recycled Entity can then be fetched again by calling the create() function.
	 * @param	e		The Entity to recycle.
	 * @return	The recycled Entity.
	 */
	public function recycle(e:Entity):Entity
	{
		_recycle[_recycle.length] = e;
		return remove(e);
	}
	
	/**
	 * Clears stored recycled Entities of the Class type.
	 * @param	classType		The Class type to clear.
	 */
	public static function clearRecycled(className:String):Void
	{
		var e:Entity = _recycled[className],
			n:Entity;
		while (e != null)
		{
			n = e._recycleNext;
			e._recycleNext = null;
			e = n;
		}
		_recycled.remove(className);
	}
	
	/**
	 * Clears stored recycled Entities of all Class types.
	 */
	public static function clearRecycledAll():Void
	{
		for (className in _recycled.keys()) clearRecycled(className);
	}
	
	/**
	 * Brings the Entity to the front of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function bringToFront(e:Entity):Bool
	{
		if (e._world != this || e._renderPrev == null) return false;
		// pull from list
		e._renderPrev._renderNext = e._renderNext;
		if (e._renderNext != null) e._renderNext._renderPrev = e._renderPrev;
		else _renderLast[e._layer] = e._renderPrev;
		// place at the start
		e._renderNext = _renderFirst[e._layer];
		e._renderNext._renderPrev = e;
		_renderFirst[e._layer] = e;
		e._renderPrev = null;
		return true;
	}
	
	/**
	 * Sends the Entity to the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendToBack(e:Entity):Bool
	{
		if (e._world != this || e._renderNext == null) return false;
		// pull from list
		e._renderNext._renderPrev = e._renderPrev;
		if (e._renderPrev != null) e._renderPrev._renderNext = e._renderNext;
		else _renderFirst[e._layer] = e._renderNext;
		// place at the end
		e._renderPrev = _renderLast[e._layer];
		e._renderPrev._renderNext = e;
		_renderLast[e._layer] = e;
		e._renderNext = null;
		return true;
	}
	
	/**
	 * Shifts the Entity one place towards the front of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function bringForward(e:Entity):Bool
	{
		if (e._world != this || e._renderPrev == null) return false;
		// pull from list
		e._renderPrev._renderNext = e._renderNext;
		if (e._renderNext != null) e._renderNext._renderPrev = e._renderPrev;
		else _renderLast[e._layer] = e._renderPrev;
		// shift towards the front
		e._renderNext = e._renderPrev;
		e._renderPrev = e._renderPrev._renderPrev;
		e._renderNext._renderPrev = e;
		if (e._renderPrev != null) e._renderPrev._renderNext = e;
		else _renderFirst[e._layer] = e;
		return true;
	}
	
	/**
	 * Shifts the Entity one place towards the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendBackward(e:Entity):Bool
	{
		if (e._world != this || e._renderNext == null) return false;
		// pull from list
		e._renderNext._renderPrev = e._renderPrev;
		if (e._renderPrev != null) e._renderPrev._renderNext = e._renderNext;
		else _renderFirst[e._layer] = e._renderNext;
		// shift towards the back
		e._renderPrev = e._renderNext;
		e._renderNext = e._renderNext._renderNext;
		e._renderPrev._renderNext = e;
		if (e._renderNext != null) e._renderNext._renderPrev = e;
		else _renderLast[e._layer] = e;
		return true;
	}
	
	/**
	 * If the Entity as at the front of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public function isAtFront(e:Entity):Bool
	{
		return e._renderPrev == null;
	}
	
	/**
	 * If the Entity as at the back of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public function isAtBack(e:Entity):Bool
	{
		return e._renderNext == null;
	}
	
	/**
	 * Returns the first Entity that collides with the rectangular area.
	 * @param	type		The Entity type to check for.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @return	The first Entity to collide, or null if none collide.
	 */
	public function collideRect(type:String, rX:Float, rY:Float, rWidth:Float, rHeight:Float):Entity
	{
		var e:Entity = _typeFirst[type];
		while (e != null)
		{
			if (e.collidable && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) return e;
			e = e._typeNext;
		}
		return null;
	}

	/**
	 * Returns the first Entity found that collides with the position.
	 * @param	type		The Entity type to check for.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @return	The collided Entity, or null if none collide.
	 */
	public function collidePoint(type:String, pX:Float, pY:Float):Entity
	{
		var e:Entity = _typeFirst[type];
		while (e != null)
		{
			if (e.collidable && e.collidePoint(e.x, e.y, pX, pY)) return e;
			e = e._typeNext;
		}
		return null;
	}
	
	/**
	 * Returns the first Entity found that collides with the line.
	 * @param	type		The Entity type to check for.
	 * @param	fromX		Start x of the line.
	 * @param	fromY		Start y of the line.
	 * @param	toX			End x of the line.
	 * @param	toY			End y of the line.
	 * @param	precision	Distance between consecutive tests. Higher values are faster but increase the chance of missing collisions.
	 * @param	p			If non-null, will have its x and y values set to the point of collision.
	 * @return
	 */
	public function collideLine(type:String, fromX:Int, fromY:Int, toX:Int, toY:Int, precision:Int = 1, ?p:Point = null):Entity
	{
		// If the distance is less than precision, do the short sweep.
		if (precision < 1) precision = 1;
		if (HP.distance(fromX, fromY, toX, toY) < precision)
		{
			if (p != null)
			{
				if (fromX == toX && fromY == toY)
				{
					p.x = toX; p.y = toY;
					return collidePoint(type, toX, toY);
				}
				return collideLine(type, fromX, fromY, toX, toY, 1, p);
			}
			else return collidePoint(type, fromX, toY);
		}
		
		// Get information about the line we're about to raycast.
		var xDelta:Int = Std.int(Math.abs(toX - fromX)),
			yDelta:Int = Std.int(Math.abs(toY - fromY)),
			xSign:Float = toX > fromX ? precision : -precision,
			ySign:Float = toY > fromY ? precision : -precision,
			x:Float = fromX, y:Float = fromY, e:Entity;
		
		// Do a raycast from the start to the end point.
		if (xDelta > yDelta)
		{
			ySign *= yDelta / xDelta;
			if (xSign > 0)
			{
				while (x < toX)
				{
					e = collidePoint(type, x, y);
					if (e != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p);
					}
					x += xSign; y += ySign;
				}
			}
			else
			{
				while (x > toX)
				{
					e = collidePoint(type, x, y);
					if (e != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p);
					}
					x += xSign; y += ySign;
				}
			}
		}
		else
		{
			xSign *= xDelta / yDelta;
			if (ySign > 0)
			{
				while (y < toY)
				{
					e = collidePoint(type, x, y);
					if (e != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p);
					}
					x += xSign; y += ySign;
				}
			}
			else
			{
				while (y > toY)
				{
					e = collidePoint(type, x, y);
					if (e != null)
					{
						if (p == null) return e;
						if (precision < 2)
						{
							p.x = x - xSign; p.y = y - ySign;
							return e;
						}
						return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p);
					}
					x += xSign; y += ySign;
				}
			}
		}
		
		// Check the last position.
		if (precision > 1)
		{
			if (p == null) return collidePoint(type, toX, toY);
			if (collidePoint(type, toX, toY) != null) return collideLine(type, Std.int(x - xSign), Std.int(y - ySign), toX, toY, 1, p);
		}
		
		// No collision, return the end point.
		if (p != null)
		{
			p.x = toX;
			p.y = toY;
		}
		return null;
	}
	
	/**
	 * Populates an array with all Entities that collide with the rectangle. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type		The Entity type to check for.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @param	into		The Array or Vector to populate with collided Entities.
	 */
	public function collideRectInto(type:String, rX:Float, rY:Float, rWidth:Float, rHeight:Float, into:Array<Entity>):Void
	{
		var e:Entity = _typeFirst[type],
			n:Int = into.length;
		while (e != null)
		{
			if (e.collidable && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) into[n ++] = e;
			e = e._typeNext;
		}
	}
	
	/**
	 * Populates an array with all Entities that collide with the position. This
	 * function does not empty the array, that responsibility is left to the user.
	 * @param	type		The Entity type to check for.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @param	into		The Array or Vector to populate with collided Entities.
	 * @return	The provided Array.
	 */
	public function collidePointInto(type:String, pX:Float, pY:Float, into:Array<Entity>):Void
	{
		var e:Entity = _typeFirst[type],
			n:Int = into.length;
		while (e != null)
		{
			if (e.collidable && e.collidePoint(e.x, e.y, pX, pY)) into[n ++] = e;
			e = e._typeNext;
		}
	}
	
	/**
	 * Finds the Entity nearest to the rectangle.
	 * @param	type		The Entity type to check for.
	 * @param	x			X position of the rectangle.
	 * @param	y			Y position of the rectangle.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	ignore		Ignore this entity.
	 * @return	The nearest Entity to the rectangle.
	 */
	public function nearestToRect(type:String, x:Float, y:Float, width:Float, height:Float, ignore:Entity = null):Entity
	{
		var n:Entity = _typeFirst[type],
			nearDist:Float = 1 << 29,
			near:Entity = null, dist:Float = 0;
		while (n != null)
		{
			if (n != ignore) {
				dist = squareRects(x, y, width, height, n.x - n.originX, n.y - n.originY, n.width, n.height);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
			n = n._typeNext;
		}
		return near;
	}
	
	/**
	 * Finds the Entity nearest to another.
	 * @param	type		The Entity type to check for.
	 * @param	e			The Entity to find the nearest to.
	 * @param	useHitboxes	If the Entities' hitboxes should be used to determine the distance. If false, their x/y coordinates are used.
	 * @return	The nearest Entity to e.
	 */
	public function nearestToEntity(type:String, e:Entity, useHitboxes:Bool = false):Entity
	{
		if (useHitboxes) return nearestToRect(type, e.x - e.originX, e.y - e.originY, e.width, e.height);
		var n:Entity = _typeFirst[type],
			nearDist:Float = 1 << 29,
			near:Entity = null, dist:Float,
			x:Float = e.x - e.originX,
			y:Float = e.y - e.originY;
		while (n != null)
		{
			if (n != e)
			{
				dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
			n = n._typeNext;
		}
		return near;
	}
	
	/**
	 * Finds the Entity nearest to the position.
	 * @param	type		The Entity type to check for.
	 * @param	x			X position.
	 * @param	y			Y position.
	 * @param	useHitboxes	If the Entities' hitboxes should be used to determine the distance. If false, their x/y coordinates are used.
	 * @return	The nearest Entity to the position.
	 */
	public function nearestToPoint(type:String, x:Float, y:Float, useHitboxes:Bool = false):Entity
	{
		var n:Entity = _typeFirst[type],
			nearDist:Float = 1 << 29,
			near:Entity = null, dist:Float = 0;
		if (useHitboxes)
		{
			while (n != null)
			{
				dist = squarePointRect(x, y, n.x - n.originX, n.y - n.originY, n.width, n.height);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
				n = n._typeNext;
			}
			return near;
		}
		while (n != null)
		{
			dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
			if (dist < nearDist)
			{
				nearDist = dist;
				near = n;
			}
			n = n._typeNext;
		}
		return near;
	}
	
	/**
	 * How many Entities are in the World.
	 */
	public var count(get, null):Int;
	private inline function get_count() { return _count; }
	
	/**
	 * Returns the amount of Entities of the type are in the World.
	 * @param	type		The type (or Class type) to count.
	 * @return	How many Entities of type exist in the World.
	 */
	public function typeCount(type:String):Int
	{
		return cast _typeCount[type];
	}
	
	/**
	 * Returns the amount of Entities of the Class are in the World.
	 * @param	c		The Class type to count.
	 * @return	How many Entities of Class exist in the World.
	 */
	public function classCount(c:Class<Entity>):Int
	{
		return _classCount[Type.getClassName(c)];
	}
	
	/**
	 * Returns the amount of Entities are on the layer in the World.
	 * @param	layer		The layer to count Entities on.
	 * @return	How many Entities are on the layer.
	 */
	public function layerCount(layer:Int):Int
	{
		return cast _layerCount[layer];
	}
	
	/**
	 * The first Entity in the World.
	 */
	public var first(get, null):Entity;
	private inline function get_first() { return _updateFirst; }
	
	/**
	 * How many Entity layers the World has.
	 */
	public var layers(get, null):Int;
	private inline function get_layers() { return _layerList.length; }
	
	/**
	 * The first Entity of the type.
	 * @param	type		The type to check.
	 * @return	The Entity.
	 */
	public function typeFirst(type:String):Entity
	{
		if (_updateFirst == null) return null;
		return cast _typeFirst[type];
	}
	
	/**
	 * The first Entity of the Class.
	 * @param	c		The Class type to check.
	 * @return	The Entity.
	 */
	public function classFirst(c:Class<Entity>):Entity
	{
		if (_updateFirst == null) return null;
		var e:Entity = _updateFirst;
		while (e != null)
		{
			if (Std.is(e, c)) return e;
			e = e._updateNext;
		}
		return null;
	}
	
	/**
	 * The first Entity on the Layer.
	 * @param	layer		The layer to check.
	 * @return	The Entity.
	 */
	public function layerFirst(layer:Int):Entity
	{
		if (_updateFirst == null) return null;
		return cast _renderFirst[layer];
	}
	
	/**
	 * The last Entity on the Layer.
	 * @param	layer		The layer to check.
	 * @return	The Entity.
	 */
	public function layerLast(layer:Int):Entity
	{
		if (_updateFirst == null) return null;
		return cast _renderLast[layer];
	}
	
	/**
	 * The Entity that will be rendered first by the World.
	 */
	public var farthest(get, null):Entity;
	private inline function get_farthest()
	{
		if (_updateFirst == null) return null;
		return cast _renderLast[cast(_layerList[_layerList.length - 1], Int)];
	}
	
	/**
	 * The Entity that will be rendered last by the world.
	 */
	public var nearest(get, null):Entity;
	private inline function get_nearest()
	{
		if (_updateFirst == null) return null;
		return cast _renderFirst[cast(_layerList[0], Int)];
	}
	
	/**
	 * The layer that will be rendered first by the World.
	 */
	public var layerFarthest(get, null):Int;
	private inline function get_layerFarthest()
	{
		if (_updateFirst == null) return 0;
		return cast _layerList[_layerList.length - 1];
	}
	
	/**
	 * The layer that will be rendered last by the World.
	 */
	public var layerNearest(get, null):Int;
	private inline function get_layerNearest()
	{
		if (_updateFirst == null) return 0;
		return cast _layerList[0];
	}
	
	/**
	 * How many different types have been added to the World.
	 */
	public var uniqueTypes(get, null):Int;
	private inline function get_uniqueTypes()
	{
		var i:Int = 0;
		for (type in _typeCount) i++;
		return i;
	}
	
	/**
	 * Pushes all Entities in the World of the type into the Array or Vector.
	 * @param	type		The type to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getType(type:String, into:Array<Entity>):Void
	{
		var e:Entity = _typeFirst[type],
			n:Int = into.length;
		while (e != null)
		{
			into[n ++] = e;
			e = e._typeNext;
		}
	}
	
	/**
	 * Pushes all Entities in the World of the Class into the Array or Vector.
	 * @param	c			The Class type to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getClass(c:Class<Entity>, into:Array<Entity>):Void
	{
		var e:Entity = _updateFirst,
			n:Int = into.length;
		while (e != null)
		{
			if (Std.is(e, c)) into[n ++] = e;
			e = e._updateNext;
		}
	}
	
	/**
	 * Pushes all Entities in the World on the layer into the Array or Vector.
	 * @param	layer		The layer to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getLayer(layer:Int, into:Array<Entity>):Void
	{
		var e:Entity = _renderLast[layer],
			n:Int = into.length;
		while (e != null)
		{
			into[n ++] = e;
			e = e._renderPrev;
		}
	}
	
	/**
	 * Pushes all Entities in the World into the array.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getAll(into:Array<Entity>):Void
	{
		var e:Entity = _updateFirst,
			n:Int = into.length;
		while (e != null)
		{
			into[n ++] = e;
			e = e._updateNext;
		}
	}
	
	/**
	 * Returns the Entity with the instance name, or null if none exists.
	 * @param	name	Instance name of the Entity.
	 * @return	An Entity in this world.
	 */
	public function getInstance(name:String):Entity
	{
		return cast _entityNames[name];
	}
	
	/**
	 * Updates the add/remove lists at the end of the frame.
	 * @param    shouldAdd    If false, entities will not be added
							  to the world, only removed.
	 */
	public function updateLists(shouldAdd:Bool = true):Void
	{
		var e:Entity;
		
		// remove entities
		if (_remove.length > 0)
		{
			for (e in _remove)
			{
				if (e._world == null)
				{
					if(Lambda.indexOf(_add, e) >= 0)
						_add.splice(Lambda.indexOf(_add, e), 1);
					
					continue;
				}
				if (e._world != this)
					continue;
				
				e.removed();
				e._world = null;
				
				removeUpdate(e);
				removeRender(e);
				if (e._type != null) removeType(e);
				if (e._name != null) unregisterName(e);
				if (e.autoClear && e._tween != null) e.clearTweens();
			}
			HP.removeAll(_remove);
		}
		
		// add entities
		if (shouldAdd && _add.length > 0)
		{
			for (e in _add)
			{
				if (e._world != null)
					continue;
				
				addUpdate(e);
				addRender(e);
				if (e._type != null) addType(e);
				if (e._name != null) registerName(e);
				
				e._world = this;
				e.added();
			}
			HP.removeAll(_add);
		}
		
		// recycle entities
		if (_recycle.length > 0)
		{
			for (e in _recycle)
			{
				if (e._world != null || e._recycleNext != null)
					continue;
				
				e._recycleNext = _recycled[e._class];
				_recycled[e._class] = e;
			}
			HP.removeAll(_recycle);
		}
	}
	
	/** @private Adds Entity to the update list. */
	private function addUpdate(e:Entity):Void
	{
		// add to update list
		if (_updateFirst != null)
		{
			_updateFirst._updatePrev = e;
			e._updateNext = _updateFirst;
		}
		else e._updateNext = null;
		e._updatePrev = null;
		_updateFirst = e;
		_count ++;
		if (!_classCount.exists(e._class)) _classCount.set(e._class, 0);
		_classCount.set(e._class, _classCount[e._class] + 1);
	}
	
	/** @private Removes Entity from the update list. */
	private function removeUpdate(e:Entity):Void
	{
		// remove from the update list
		if (_updateFirst == e) _updateFirst = e._updateNext;
		if (e._updateNext != null) e._updateNext._updatePrev = e._updatePrev;
		if (e._updatePrev != null) e._updatePrev._updateNext = e._updateNext;
		e._updateNext = e._updatePrev = null;
		
		_count --;
		_classCount.set(e._class, _classCount[e._class] - 1);
	}
	
	/** @private Adds Entity to the render list. */
	public function addRender(e:Entity):Void
	{
		var f:Entity = _renderFirst[e._layer];
		if (f != null)
		{
			// Append entity to existing layer.
			e._renderNext = f;
			f._renderPrev = e;
			_layerCount[e._layer] ++;
		}
		else
		{
			// Create new layer with entity.
			_renderLast[e._layer] = e;
			_layerList[_layerList.length] = e._layer;
			_layerSort = true;
			e._renderNext = null;
			_layerCount[e._layer] = 1;
		}
		_renderFirst[e._layer] = e;
		e._renderPrev = null;
	}
	
	/** @private Removes Entity from the render list. */
	public function removeRender(e:Entity):Void
	{
		if (e._renderNext != null) e._renderNext._renderPrev = e._renderPrev;
		else _renderLast[e._layer] = e._renderPrev;
		if (e._renderPrev != null) e._renderPrev._renderNext = e._renderNext;
		else
		{
			// Remove this entity from the layer.
			_renderFirst[e._layer] = e._renderNext;
			if (e._renderNext != null)
			{
				// Remove the layer from the layer list if this was the last entity.
				if (_layerList.length > 1)
				{
					_layerList[Lambda.indexOf(_layerList, e._layer)] = _layerList[_layerList.length - 1];
					_layerSort = true;
				}
				_layerList.pop();
			}
		}
		_layerCount[e._layer] --;
		e._renderNext = e._renderPrev = null;
	}
	
	/** @private Adds Entity to the type list. */
	public function addType(e:Entity):Void
	{
		// add to type list
		if (_typeFirst.exists(e._type))
		{
			_typeFirst[e._type]._typePrev = e;
			e._typeNext = _typeFirst[e._type];
			_typeCount.set(e._type, _typeCount[e._type] + 1);
		}
		else
		{
			e._typeNext = null;
			_typeCount.set(e._type, 1);
		}
		e._typePrev = null;
		_typeFirst[e._type] = e;
	}
	
	/** @private Removes Entity from the type list. */
	public function removeType(e:Entity):Void
	{
		// remove from the type list
		if (_typeFirst[e._type] == e) _typeFirst[e._type] = e._typeNext;
		if (e._typeNext != null) e._typeNext._typePrev = e._typePrev;
		if (e._typePrev != null) e._typePrev._typeNext = e._typeNext;
		e._typeNext = e._typePrev = null;
		_typeCount.set(e._type, _typeCount[e._type] - 1);
	}
	
	/** @private Register's the Entity's instance name. */
	public function registerName(e:Entity):Void
	{
		_entityNames[e._name] = e;
	}
	
	/** @private Unregister's the Entity's instance name. */
	public function unregisterName(e:Entity):Void
	{
		if (_entityNames[e._name] == e) _entityNames.remove(e._name);
	}
	
	/** @private Calculates the squared distance between two rectangles. */
	private static function squareRects(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Float
	{
		if (x1 < x2 + w2 && x2 < x1 + w1)
		{
			if (y1 < y2 + h2 && y2 < y1 + h1) return 0;
			if (y1 > y2) return (y1 - (y2 + h2)) * (y1 - (y2 + h2));
			return (y2 - (y1 + h1)) * (y2 - (y1 + h1));
		}
		if (y1 < y2 + h2 && y2 < y1 + h1)
		{
			if (x1 > x2) return (x1 - (x2 + w2)) * (x1 - (x2 + w2));
			return (x2 - (x1 + w1)) * (x2 - (x1 + w1));
		}
		if (x1 > x2)
		{
			if (y1 > y2) return squarePoints(x1, y1, (x2 + w2), (y2 + h2));
			return squarePoints(x1, y1 + h1, x2 + w2, y2);
		}
		if (y1 > y2) return squarePoints(x1 + w1, y1, x2, y2 + h2);
		return squarePoints(x1 + w1, y1 + h1, x2, y2);
	}
	
	/** @private Calculates the squared distance between two points. */
	private static function squarePoints(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
	}
	
	/** @private Calculates the squared distance between a rectangle and a point. */
	private static function squarePointRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Float
	{
		if (px >= rx && px <= rx + rw)
		{
			if (py >= ry && py <= ry + rh) return 0;
			if (py > ry) return (py - (ry + rh)) * (py - (ry + rh));
			return (ry - py) * (ry - py);
		}
		if (py >= ry && py <= ry + rh)
		{
			if (px > rx) return (px - (rx + rw)) * (px - (rx + rw));
			return (rx - px) * (rx - px);
		}
		if (px > rx)
		{
			if (py > ry) return squarePoints(px, py, rx + rw, ry + rh);
			return squarePoints(px, py, rx + rw, ry);
		}
		if (py > ry) return squarePoints(px, py, rx, ry + rh);
		return squarePoints(px, py, rx, ry);
	}
	
	// Adding and removal.
	/** @private */	private var _add:Array<Entity>;
	/** @private */	private var _remove:Array<Entity>;
	/** @private */	private var _recycle:Array<Entity>;
	
	// Update information.
	/** @private */	private var _updateFirst:Entity;
	/** @private */	private var _count:Int = 0;
	
	// Render information.
	/** @private */	private var _renderFirst:Array<Entity>;
	/** @private */	private var _renderLast:Array<Entity>;
	/** @private */	private var _layerList:Array<Int>;
	/** @private */	private var _layerCount:Array<Int>;
	/** @private */	private var _layerSort:Bool;
	/** @private */	private var _classCount:Map<String, UInt>;
	/** @private */	public var _typeFirst:Map<String, Entity>;
	/** @private */	private var _typeCount:Map<String, UInt>;
	/** @private */	private static var _recycled:Map<String, Entity>;
	/** @private */	public var _entityNames:Map<String, Entity>;
}

