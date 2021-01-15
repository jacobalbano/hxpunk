package net.hxpunk;

import flash.geom.Point;
import haxe.ds.IntMap;
import net.hxpunk.Entity.FriendlyEntity;
import net.hxpunk.utils.Draw;

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
	
	private static inline function initStaticVars():Bool 
	{
		_recycled = new Map < String, Entity > ();
		
		return true;
	}
	
	private inline function initVars():Void 
	{
		camera = new Point();
		
		// Adding and removal.
		_add = new Array<Entity>();
		_remove = new Array<Entity>();
		_recycle = new Array<Entity>();
		
		// Render information.
		_renderFirst = new IntMap<FriendlyEntity>();
		_renderLast = new IntMap<FriendlyEntity>();
		_layerList = new Array<Int>();
		_layerCount = new IntMap<Int>();
		_classCount = new Map<String, Int>();
		
		_typeFirst = new Map<String, FriendlyEntity>();
		_typeCount = new Map<String, Int>();
		
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
		var e:Entity,
			fe:FriendlyEntity = _updateFirst;
		while (fe != null)
		{
			e = cast fe;
			if (e.active)
			{
				if (fe._tween != null) e.updateTweens();
				e.update();
			}
			if (fe._graphic != null && fe._graphic.active) fe._graphic.update();
			fe = fe._updateNext;
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
			fe:FriendlyEntity,
			i:Int = _layerList.length;
		while (i -- > 0)
		{
			fe = _renderLast.get(_layerList[i]);
			while (fe != null)
			{
				e = cast fe;
				if (e.visible) e.render();
				fe = fe._renderPrev;
			}
		}
		Draw.renderCallQueue();
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
	 * @param   x		Set Entity x position.
	 * @param   y		Set Entity y position.
	 * @return	The added Entity object.
	 */
	public function add(e:Entity, ?x:Float, ?y:Float):Entity
	{
		if (x != null) e.x = x;
		if (y != null) e.y = y;
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
		var e:Entity,
			fe:FriendlyEntity = _updateFirst;
		while (fe != null)
		{
			e = cast fe;
			_remove[_remove.length] = e;
			fe = fe._updateNext;
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
	 * Adds an Entity to the World with the Graphic object (also sets active to false).
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
	 * Adds an Entity to the World with the Mask object (also sets active and visible to false).
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
		var className:String = Type.getClassName(classType),
			e:Entity = _recycled[className],
			fe:FriendlyEntity;
		if (e != null)
		{
			fe = e;
			_recycled[className] = cast fe._recycleNext;
			fe._recycleNext = null;
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
		var fe:FriendlyEntity;
		while (e != null)
		{
			fe = e;
			n = cast fe._recycleNext;
			fe._recycleNext = null;
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
		var fe:FriendlyEntity = e;
		if (fe._world != this || fe._renderPrev == null) return false;
		// pull from list
		fe._renderPrev._renderNext = fe._renderNext;
		if (fe._renderNext != null) fe._renderNext._renderPrev = fe._renderPrev;
		else _renderLast.set(fe._layer, fe._renderPrev);
		// place at the start
		fe._renderNext = _renderFirst.get(fe._layer);
		fe._renderNext._renderPrev = e;
		_renderFirst.set(fe._layer, e);
		fe._renderPrev = null;
		return true;
	}
	
	/**
	 * Sends the Entity to the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendToBack(e:Entity):Bool
	{
		var fe:FriendlyEntity = e;
		if (fe._world != this || fe._renderNext == null) return false;
		// pull from list
		fe._renderNext._renderPrev = fe._renderPrev;
		if (fe._renderPrev != null) fe._renderPrev._renderNext = fe._renderNext;
		else _renderFirst.set(fe._layer, fe._renderNext);
		// place at the end
		fe._renderPrev = _renderLast.get(fe._layer);
		fe._renderPrev._renderNext = fe;
		_renderLast.set(fe._layer, fe);
		fe._renderNext = null;
		return true;
	}
	
	/**
	 * Shifts the Entity one place towards the front of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function bringForward(e:Entity):Bool
	{
		var fe:FriendlyEntity = e;
		if (fe._world != this || fe._renderPrev == null) return false;
		// pull from list
		fe._renderPrev._renderNext = fe._renderNext;
		if (fe._renderNext != null) fe._renderNext._renderPrev = fe._renderPrev;
		else _renderLast.set(fe._layer, fe._renderPrev);
		// shift towards the front
		fe._renderNext = fe._renderPrev;
		fe._renderPrev = fe._renderPrev._renderPrev;
		fe._renderNext._renderPrev = fe;
		if (fe._renderPrev != null) fe._renderPrev._renderNext = fe;
		else _renderFirst.set(fe._layer, fe);
		return true;
	}
	
	/**
	 * Shifts the Entity one place towards the back of its contained layer.
	 * @param	e		The Entity to shift.
	 * @return	If the Entity changed position.
	 */
	public function sendBackward(e:Entity):Bool
	{
		var fe:FriendlyEntity = e;
		if (fe._world != this || fe._renderNext == null) return false;
		// pull from list
		fe._renderNext._renderPrev = fe._renderPrev;
		if (fe._renderPrev != null) fe._renderPrev._renderNext = fe._renderNext;
		else _renderFirst.set(fe._layer, fe._renderNext);
		// shift towards the back
		fe._renderPrev = fe._renderNext;
		fe._renderNext = fe._renderNext._renderNext;
		fe._renderPrev._renderNext = fe;
		if (fe._renderNext != null) fe._renderNext._renderPrev = fe;
		else _renderLast.set(fe._layer, fe);
		return true;
	}
	
	/**
	 * If the Entity as at the front of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public function isAtFront(e:Entity):Bool
	{
		var fe:FriendlyEntity = e;
		return fe._renderPrev == null;
	}
	
	/**
	 * If the Entity as at the back of its layer.
	 * @param	e		The Entity to check.
	 * @return	True or false.
	 */
	public function isAtBack(e:Entity):Bool
	{
		var fe:FriendlyEntity = e;
		return fe._renderNext == null;
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
		var e:Entity,
			fe:FriendlyEntity = _typeFirst[type];
		while (fe != null)
		{
			e = cast fe;
			if (e.collidable && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) return e;
			fe = fe._typeNext;
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
		var e:Entity,
			fe:FriendlyEntity = _typeFirst[type];
		while (fe != null)
		{
			e = cast fe;
			if (e.collidable && e.collidePoint(e.x, e.y, pX, pY)) return e;
			fe = fe._typeNext;
		}
		return null;
	}
	
		/**
		 * Returns the Entity at front which collides with the point.
		 * @param   x       X position
		 * @param   y       Y position
		 * @return The Entity at front which collides with the point, or null if not found.
		 */
		public function frontCollidePoint(x:Float, y:Float):Entity
		{
			var fe:FriendlyEntity,
			e:Entity,
			i:Int = 0,
			l:Int = _layerList.length;
			do
			{
				fe = _renderFirst.get(_layerList[i]);
				while (fe != null)
				{
					e = cast fe;
					if(e.collidePoint(e.x, e.y, x, y)) return e;
					fe = fe._renderNext;
				}
				if(i > l) break;
			}
			while(++i != 0);
			
			return null;
		}
	
	/**
	 * Returns the topmost Entity which collides with the point.
	 * @param	type	The Entity type to check for (pass null to check for any type).
	 * @param   x       X position
	 * @param   y       Y position
	 * @return The topmost Entity which collides with the point, or null if not found.
	 */
	public function topmostCollidePoint(type:String = null, x:Float, y:Float):Entity
	{
		var e:Entity,
			fe:FriendlyEntity,
			i:Int = 0,
			nLayers:Int = _layerList.length;
		
		while (i < nLayers)
		{
			fe = _renderFirst.get(_layerList[i]);
			while (fe != null)
			{
				e = cast fe;
				if (e.collidable && (type == null || fe._type == type) && e.collidePoint(e.x, e.y, x, y)) return e;
				fe = fe._renderNext;
			}
			i++;
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
		var e:Entity,
			fe:FriendlyEntity = _typeFirst[type],
			n:Int = into.length;
		while (fe != null)
		{
			e = cast fe;
			if (e.collidable && e.collideRect(e.x, e.y, rX, rY, rWidth, rHeight)) into[n ++] = e;
			fe = fe._typeNext;
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
		var e:Entity,
			fe:FriendlyEntity = _typeFirst[type],
			n:Int = into.length;
		while (fe != null)
		{
			e = cast fe;
			if (e.collidable && e.collidePoint(e.x, e.y, pX, pY)) into[n ++] = e;
			fe = fe._typeNext;
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
		var n:Entity,
			fn:FriendlyEntity = _typeFirst[type],
			nearDist:Float = Math.POSITIVE_INFINITY,
			near:Entity = null, dist:Float = 0;
		while (fn != null)
		{
			n = cast fn;
			if (n != ignore) {
				dist = HP.distanceRectsSqr(x, y, width, height, n.x - n.originX, n.y - n.originY, n.width, n.height);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
			fn = fn._typeNext;
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
		var n:Entity,
			fn:FriendlyEntity = _typeFirst[type],
			nearDist:Float = Math.POSITIVE_INFINITY,
			near:Entity = null, dist:Float,
			x:Float = e.x - e.originX,
			y:Float = e.y - e.originY;
		while (fn != null)
		{
			n = cast fn;
			if (n != e)
			{
				dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
			}
			fn = fn._typeNext;
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
		var n:Entity,
			fn:FriendlyEntity = _typeFirst[type],
			nearDist:Float = Math.POSITIVE_INFINITY,
			near:Entity = null, dist:Float = 0;
		if (useHitboxes)
		{
			while (fn != null)
			{
				n = cast fn;
				dist = HP.distancePointRectSqr(x, y, n.x - n.originX, n.y - n.originY, n.width, n.height);
				if (dist < nearDist)
				{
					nearDist = dist;
					near = n;
				}
				fn = fn._typeNext;
			}
			return near;
		}
		while (fn != null)
		{
			n = cast fn;
			dist = (x - n.x) * (x - n.x) + (y - n.y) * (y - n.y);
			if (dist < nearDist)
			{
				nearDist = dist;
				near = n;
			}
			fn = fn._typeNext;
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
		return cast _layerCount.get(layer);
	}
	
	/**
	 * The first Entity in the World.
	 */
	public var first(get, null):Entity;
	private inline function get_first() { return cast _updateFirst; }
	
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
		var e:Entity,
			fe:FriendlyEntity = _updateFirst;
		while (fe != null)
		{
			e = cast fe;
			if (Std.is(e, c)) return e;
			fe = fe._updateNext;
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
		return cast _renderFirst.get(layer);
	}
	
	/**
	 * The last Entity on the Layer.
	 * @param	layer		The layer to check.
	 * @return	The Entity.
	 */
	public function layerLast(layer:Int):Entity
	{
		if (_updateFirst == null) return null;
		return cast _renderLast.get(layer);
	}
	
	/**
	 * The Entity that will be rendered first by the World.
	 */
	public var farthest(get, null):Entity;
	private function get_farthest()
	{
		if (_updateFirst == null) return null;
		return cast _renderLast.get(_layerList[_layerList.length - 1]);
	}
	
	/**
	 * The Entity that will be rendered last by the world.
	 */
	public var nearest(get, null):Entity;
	private function get_nearest()
	{
		if (_updateFirst == null) return null;
		return cast _renderFirst.get(_layerList[0]);
	}
	
	/**
	 * The layer that will be rendered first by the World.
	 */
	public var layerFarthest(get, null):Int;
	private function get_layerFarthest()
	{
		if (_updateFirst == null) return 0;
		return cast _layerList[_layerList.length - 1];
	}
	
	/**
	 * The layer that will be rendered last by the World.
	 */
	public var layerNearest(get, null):Int;
	private function get_layerNearest()
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
	 * Pushes all Entities in the World of the type into the Array or Array
	 * @param	type		The type to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getType(type:String, into:Array<Entity>):Void
	{
		var fe:FriendlyEntity = _typeFirst[type],
			n:Int = into.length;
		while (fe != null)
		{
			into[n ++] = cast fe;
			fe = fe._typeNext;
		}
	}
	
	/**
	 * Pushes all Entities in the World of the Class into the Array or Array
	 * @param	c			The Class type to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getClass(c:Class<Entity>, into:Array<Entity>):Void
	{
		var e:Entity,
			fe:FriendlyEntity = _updateFirst,
			n:Int = into.length;
		while (fe != null)
		{
			e = cast fe;
			if (Std.is(e, c)) into[n ++] = e;
			fe = fe._updateNext;
		}
	}
	
	/**
	 * Pushes all Entities in the World on the layer into the Array or Array
	 * @param	layer		The layer to check.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getLayer(layer:Int, into:Array<Entity>):Void
	{
		var fe:FriendlyEntity = _renderLast.get(layer),
			n:Int = into.length;
		while (fe != null)
		{
			into[n ++] = cast fe;
			fe = fe._renderPrev;
		}
	}
	
	/**
	 * Pushes all Entities in the World into the array.
	 * @param	into		The Array or Vector to populate.
	 * @return	The same array, populated.
	 */
	public function getAll(into:Array<Entity>):Void
	{
		var e:Entity,
			fe:FriendlyEntity = _updateFirst,
			n:Int = into.length;
		while (fe != null)
		{
			into[n ++] = cast fe;
			fe = fe._updateNext;
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
	 * @param    shouldAdd    If false, entities will not be added to the world, only removed.
	 */
	public function updateLists(shouldAdd:Bool = true):Void
	{
		var e:Entity,
			fe:FriendlyEntity;
		
		// remove entities
		if (_remove.length > 0)
		{
			for (e in _remove)
			{
				fe = e;
				if (fe._world == null)
				{
					if (HP.indexOf(_add, e) >= 0)
						_add.splice(HP.indexOf(_add, e), 1);
					
					continue;
				}
				if (fe._world != this)
					continue;
				
				e.removed();
				fe._world = null;
				
				removeUpdate(e);
				removeRender(e);
				if (fe._type != null) removeType(e);
				if (fe._name != null) unregisterName(e);
				if (e.autoClear && fe._tween != null) e.clearTweens();
			}
			HP.removeAll(_remove);
		}
		
		// add entities
		if (shouldAdd && _add.length > 0)
		{
			for (e in _add)
			{
				fe = e;
				if (fe._world != null)
					continue;
				
				addUpdate(e);
				addRender(e);
				if (fe._type != null) addType(e);
				if (fe._name != null) registerName(e);
				
				fe._world = this;
				e.added();
			}
			HP.removeAll(_add);
		}
		
		// recycle entities
		if (_recycle.length > 0)
		{
			for (e in _recycle)
			{
				fe = e;
				if (fe._world != null || fe._recycleNext != null)
					continue;
				
				fe._recycleNext = _recycled[fe._class];
				_recycled[fe._class] = e;
			}
			HP.removeAll(_recycle);
		}
	}
	
	/** Adds Entity to the update list. */
	private function addUpdate(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		// add to update list
		if (_updateFirst != null)
		{
			_updateFirst._updatePrev = e;
			fe._updateNext = _updateFirst;
		}
		else fe._updateNext = null;
		fe._updatePrev = null;
		_updateFirst = e;
		_count ++;
		if (!_classCount.exists(fe._class)) _classCount.set(fe._class, 0);
		_classCount.set(fe._class, _classCount[fe._class] + 1);
	}
	
	/** Removes Entity from the update list. */
	private function removeUpdate(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		// remove from the update list
		if (_updateFirst == fe) _updateFirst = fe._updateNext;
		if (fe._updateNext != null) fe._updateNext._updatePrev = fe._updatePrev;
		if (fe._updatePrev != null) fe._updatePrev._updateNext = fe._updateNext;
		fe._updateNext = fe._updatePrev = null;
		
		_count --;
		_classCount.set(fe._class, _classCount[fe._class] - 1);
	}
	
	/** Adds Entity to the render list. */
	public function addRender(e:Entity):Void
	{
		var fe:FriendlyEntity = e,
			f:FriendlyEntity = _renderFirst.get(fe._layer);
		if (f != null)
		{
			// Append entity to existing layer.
			fe._renderNext = f;
			f._renderPrev = fe;
			_layerCount.set(fe._layer, _layerCount.get(fe._layer) + 1);
		}
		else
		{
			// Create new layer with entity.
			_renderLast.set(fe._layer, fe);
			_layerList[_layerList.length] = fe._layer;
			_layerSort = true;
			fe._renderNext = null;
			_layerCount.set(fe._layer, 1);
		}
		_renderFirst.set(fe._layer, e);
		fe._renderPrev = null;
	}
	
	/** Removes Entity from the render list. */
	public function removeRender(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		if (fe._renderNext != null) fe._renderNext._renderPrev = fe._renderPrev;
		else _renderLast.set(fe._layer, fe._renderPrev);
		if (fe._renderPrev != null) fe._renderPrev._renderNext = fe._renderNext;
		else
		{
			// Remove this entity from the layer.
			_renderFirst.set(fe._layer, fe._renderNext);
			if (fe._renderNext == null)
			{
				// Remove the layer from the layer list if this was the last entity.
				if (_layerList.length > 1)
				{
					_layerList[HP.indexOf(_layerList, fe._layer)] = _layerList[_layerList.length - 1];
					_layerSort = true;
				}
				_layerList.pop();
			}
		}
		var newLayerCount:Int = _layerCount.get(fe._layer) - 1;
		if (newLayerCount > 0) {
			_layerCount.set(fe._layer, newLayerCount);
		} else {
			// Remove layer from maps if it contains 0 entities.
			_layerCount.remove(fe._layer);
			_renderFirst.remove(fe._layer);
			_renderLast.remove(fe._layer);
		}
		fe._renderNext = fe._renderPrev = null;
	}
	
	/** Adds Entity to the type list. */
	public function addType(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		// add to type list
		if (_typeFirst.exists(fe._type))
		{
			_typeFirst[fe._type]._typePrev = e;
			fe._typeNext = _typeFirst[fe._type];
			_typeCount.set(fe._type, _typeCount[fe._type] + 1);
		}
		else
		{
			fe._typeNext = null;
			_typeCount.set(fe._type, 1);
		}
		fe._typePrev = null;
		_typeFirst.set(fe._type, e);
	}
	
	/** Removes Entity from the type list. */
	public function removeType(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		// remove from the type list
		if (_typeFirst[fe._type] == e) _typeFirst[fe._type] = fe._typeNext;
		if (fe._typeNext != null) fe._typeNext._typePrev = fe._typePrev;
		if (fe._typePrev != null) fe._typePrev._typeNext = fe._typeNext;
		fe._typeNext = fe._typePrev = null;
		_typeCount.set(fe._type, _typeCount[fe._type] - 1);
	}
	
	/** Register's the Entity's instance name. */
	public function registerName(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		_entityNames[fe._name] = e;
	}
	
	/** Unregister's the Entity's instance name. */
	public function unregisterName(e:Entity):Void
	{
		var fe:FriendlyEntity = e;
		if (_entityNames[fe._name] == e) _entityNames.remove(fe._name);
	}
	
	
	// Adding and removal.
	/** */	private var _add:Array<Entity>;
	/** */	private var _remove:Array<Entity>;
	/** */	private var _recycle:Array<Entity>;
	
	// Update information.
	/** */	private var _updateFirst:FriendlyEntity;
	/** */	private var _count:Int = 0;
	
	// Render information.
	/** */	private var _renderFirst:IntMap<FriendlyEntity>;
	/** */	private var _renderLast:IntMap<FriendlyEntity>;
	/** */	private var _layerList:Array<Int>;
	/** */	private var _layerCount:IntMap<Int>;
	/** */	private var _layerSort:Bool;
	/** */	private var _classCount:Map<String, Int>;
	/** */	public var _typeFirst:Map<String, FriendlyEntity>;
	/** */	private var _typeCount:Map<String, Int>;
	/** */	private static var _recycled:Map<String, Entity>;
	/** */	public var _entityNames:Map<String, Entity>;
}

