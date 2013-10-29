package net.hxpunk;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import net.hxpunk.graphics.Graphiclist;
import net.hxpunk.graphics.Image;

/**
 * Main game Entity class updated by World.
 */
class Entity extends Tweener
{
	/**
	 * If the Entity should render.
	 */
	public var visible:Bool = true;
	
	/**
	 * If the Entity should respond to collision checks.
	 */
	public var collidable:Bool = true;
	
	/**
	 * X position of the Entity in the World.
	 */
	public var x:Float = 0;
	
	/**
	 * Y position of the Entity in the World.
	 */
	public var y:Float = 0;
	
	/**
	 * Width of the Entity's hitbox.
	 */
	public var width:Int = 0;
	
	/**
	 * Height of the Entity's hitbox.
	 */
	public var height:Int = 0;
	
	/**
	 * X origin of the Entity's hitbox.
	 */
	public var originX:Int = 0;
	
	/**
	 * Y origin of the Entity's hitbox.
	 */
	public var originY:Int = 0;
	
	/**
	 * The BitmapData target to draw the Entity to. Leave as null to render to the current screen buffer (default).
	 */
	public var renderTarget:BitmapData;
	
	/**
	 * Constructor. Can be usd to place the Entity and assign a graphic and mask.
	 * @param	x			X position to place the Entity.
	 * @param	y			Y position to place the Entity.
	 * @param	graphic		Graphic to assign to the Entity.
	 * @param	mask		Mask to assign to the Entity.
	 */
	public function new(x:Float = 0, y:Float = 0, graphic:Graphic = null, mask:Mask = null) 
	{
		super();

		// init vars
		HITBOX = new Mask();
		_point = HP.point;
		_camera = HP.point2;
		
		this.x = x;
		this.y = y;
		if (graphic != null) this.graphic = graphic;
		if (mask != null) this.mask = mask;
		HITBOX.assignTo(this);
		_class = Type.getClassName(Type.getClass(this));
	}
	
	/**
	 * Override this, called when the Entity is added to a World.
	 */
	public function added():Void
	{
		
	}
	
	/**
	 * Override this, called when the Entity is removed from a World.
	 */
	public function removed():Void
	{
		
	}
	
	/**
	 * Updates the Entity.
	 */
	override public function update():Void 
	{
		
	}
	
	/**
	 * Renders the Entity. If you override this for special behaviour,
	 * remember to call super.render() to render the Entity's graphic.
	 */
	public function render():Void 
	{
		if (_graphic != null && _graphic.visible)
		{
			if (_graphic.relative)
			{
				_point.x = x;
				_point.y = y;
			}
			else _point.x = _point.y = 0;
			_camera.x = _world != null ? _world.camera.x : HP.camera.x;
			_camera.y = _world != null ? _world.camera.y : HP.camera.y;
			_graphic.render(renderTarget != null ? renderTarget : HP.buffer, _point, _camera);
		}
	}
	
	/**
	 * Checks for a collision against an Entity type.
	 * @param	type		The Entity type to check for.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @return	The first Entity collided with, or null if none were collided.
	 */
	public function collide(type:String, x:Float, y:Float):Entity
	{
		if (_world == null) return null;
		
		var e:Entity = _world._typeFirst[type];
		if (e == null) return null;
		
		_x = this.x; _y = this.y;
		this.x = x; this.y = y;
		
		if (_mask == null)
		{
			while (e != null)
			{
				/** TODO !== ? != */
				if (e.collidable && e != this
				&& x - originX + width > e.x - e.originX
				&& y - originY + height > e.y - e.originY
				&& x - originX < e.x - e.originX + e.width
				&& y - originY < e.y - e.originY + e.height)
				{
					if (e._mask == null || e._mask.collide(HITBOX))
					{
						this.x = _x; this.y = _y;
						return e;
					}
				}
				e = e._typeNext;
			}
			this.x = _x; this.y = _y;
			return null;
		}
		
		while (e != null)
		{
			/** TODO !== ? != */
			if (e.collidable && e != this
			&& x - originX + width > e.x - e.originX
			&& y - originY + height > e.y - e.originY
			&& x - originX < e.x - e.originX + e.width
			&& y - originY < e.y - e.originY + e.height)
			{
				if (_mask.collide(e._mask != null ? e._mask : e.HITBOX))
				{
					this.x = _x; this.y = _y;
					return e;
				}
			}
			e = e._typeNext;
		}
		this.x = _x; this.y = _y;
		return null;
	}
	
	/**
	 * Checks for collision against multiple Entity types.
	 * @param	types		An Array or Vector of Entity types to check for.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @return	The first Entity collided with, or null if none were collided.
	 */
	public function collideTypes(types:Array<String>, x:Float, y:Float):Entity
	{
		if (_world == null) return null;
		
		var e:Entity;
		
		for (type in types)
		{
			e = collide(type, x, y);
			if (e != null) return e;
		}
		
		return null;
	}
	
	/**
	 * Checks if this Entity collides with a specific Entity.
	 * @param	e		The Entity to collide against.
	 * @param	x		Virtual x position to place this Entity.
	 * @param	y		Virtual y position to place this Entity.
	 * @return	The Entity if they overlap, or null if they don't.
	 */
	public function collideWith(e:Entity, x:Float, y:Float):Entity
	{
		_x = this.x; _y = this.y;
		this.x = x; this.y = y;
		
		if (e.collidable
		&& x - originX + width > e.x - e.originX
		&& y - originY + height > e.y - e.originY
		&& x - originX < e.x - e.originX + e.width
		&& y - originY < e.y - e.originY + e.height)
		{
			if (_mask == null)
			{
				if (e._mask == null || e._mask.collide(HITBOX))
				{
					this.x = _x; this.y = _y;
					return e;
				}
				this.x = _x; this.y = _y;
				return null;
			}
			if (_mask.collide(e._mask != null ? e._mask : e.HITBOX))
			{
				this.x = _x; this.y = _y;
				return e;
			}
		}
		this.x = _x; this.y = _y;
		return null;
	}
	
	/**
	 * Checks if this Entity overlaps the specified rectangle.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @return	If they overlap.
	 */
	public function collideRect(x:Float, y:Float, rX:Float, rY:Float, rWidth:Float, rHeight:Float):Bool
	{
		if (x - originX + width >= rX && y - originY + height >= rY
		&& x - originX <= rX + rWidth && y - originY <= rY + rHeight)
		{
			if (_mask == null) return true;
			_x = this.x; _y = this.y;
			this.x = x; this.y = y;
			HP.entity.x = rX;
			HP.entity.y = rY;
			HP.entity.width = Std.int(rWidth);
			HP.entity.height = Std.int(rHeight);
			if (_mask.collide(HP.entity.HITBOX))
			{
				this.x = _x; this.y = _y;
				return true;
			}
			this.x = _x; this.y = _y;
			return false;
		}
		return false;
	}
	
	/**
	 * Checks if this Entity overlaps the specified position.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @return	If the Entity intersects with the position.
	 */
	public function collidePoint(x:Float, y:Float, pX:Float, pY:Float):Bool
	{
		if (pX >= x - originX && pY >= y - originY
		&& pX < x - originX + width && pY < y - originY + height)
		{
			if (_mask == null) return true;
			_x = this.x; _y = this.y;
			this.x = x; this.y = y;
			HP.entity.x = pX;
			HP.entity.y = pY;
			HP.entity.width = 1;
			HP.entity.height = 1;
			if (_mask.collide(HP.entity.HITBOX))
			{
				this.x = _x; this.y = _y;
				return true;
			}
			this.x = _x; this.y = _y;
			return false;
		}
		return false;
	}
	
	/**
	 * Populates an array with all collided Entities of a type.
	 * @param	type		The Entity type to check for.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @param	array		The Array or Vector object to populate.
	 * @return	The array, populated with all collided Entities.
	 */
	public function collideInto(type:String, x:Float, y:Float, array:Array<Entity>):Void
	{
		if (_world == null) return;
		
		var e:Entity = _world._typeFirst[type];
		if (e == null) return;
		
		_x = this.x; _y = this.y;
		this.x = x; this.y = y;
		var n:UInt = array.length;
		
		if (_mask == null)
		{
			while (e != null)
			{
				/** TODO !== ? != */
				if (e.collidable && e != this
				&& x - originX + width > e.x - e.originX
				&& y - originY + height > e.y - e.originY
				&& x - originX < e.x - e.originX + e.width
				&& y - originY < e.y - e.originY + e.height)
				{
					if (e._mask == null || e._mask.collide(HITBOX)) array[n ++] = e;
				}
				e = e._typeNext;
			}
			this.x = _x; this.y = _y;
			return;
		}
		
		while (e != null)
		{
			/** TODO !== ? != */
			if (e.collidable && e != this
			&& x - originX + width > e.x - e.originX
			&& y - originY + height > e.y - e.originY
			&& x - originX < e.x - e.originX + e.width
			&& y - originY < e.y - e.originY + e.height)
			{
				if (_mask.collide(e._mask != null ? e._mask : e.HITBOX)) array[n ++] = e;
			}
			e = e._typeNext;
		}
		this.x = _x; this.y = _y;
		return;
	}
	
	/**
	 * Populates an array with all collided Entities of multiple types.
	 * @param	types		An array of Entity types to check for.
	 * @param	x			Virtual x position to place this Entity.
	 * @param	y			Virtual y position to place this Entity.
	 * @param	array		The Array or Vector object to populate.
	 * @return	The array, populated with all collided Entities.
	 */
	public function collideTypesInto(types:Array<String>, x:Float, y:Float, array:Array<Entity>):Void
	{
		if (_world == null) return;
		for (type in types) collideInto(type, x, y, array);
	}
	
	/**
	 * If the Entity collides with the camera rectangle.
	 */
	public var onCamera(get, null):Bool;
	private inline function get_onCamera()
	{
		return collideRect(x, y, _world.camera.x, _world.camera.y, HP.width, HP.height);
	}
	
	/**
	 * The World object this Entity has been added to.
	 */
	public var world(get, null):World;
	private inline function get_world()
	{
		return _world;
	}
	
	/**
	 * Half the Entity's width.
	 */
	public var halfWidth(get, null):Float = 0;
	private inline function get_halfWidth() { return width / 2; }
	
	/**
	 * Half the Entity's height.
	 */
	public var halfHeight(get, null):Float = 0;
	private inline function get_halfHeight() { return height / 2; }
	
	/**
	 * The center x position of the Entity's hitbox.
	 */
	public var centerX(get, null):Float = 0;
	private inline function get_centerX() { return x - originX + width / 2; }
	
	/**
	 * The center y position of the Entity's hitbox.
	 */
	public var centerY(get, null):Float = 0;
	private inline function get_centerY() { return y - originY + height / 2; }
	
	/**
	 * The leftmost position of the Entity's hitbox.
	 */
	public var left(get, null):Float = 0;
	private inline function get_left() { return x - originX; }
	
	/**
	 * The rightmost position of the Entity's hitbox.
	 */
	public var right(get, null):Float = 0;
	private inline function get_right() { return x - originX + width; }
	
	/**
	 * The topmost position of the Entity's hitbox.
	 */
	public var top(get, null):Float = 0;
	private inline function get_top() { return y - originY; }
	
	/**
	 * The bottommost position of the Entity's hitbox.
	 */
	public var bottom(get, null):Float = 0;
	private inline function get_bottom() { return y - originY + height; }
	
	/**
	 * The rendering layer of this Entity. Higher layers are rendered first.
	 */
	public var layer(get, set):Int = 0;
	private inline function get_layer() { return _layer; }
	private inline function set_layer(value:Int):Int
	{
		if (_layer != value) {
			if (_world == null)
			{
				_layer = value;
			} else {
				_world.removeRender(this);
				_layer = value;
				_world.addRender(this);
			}
		}
		return value;
	}
	
	/**
	 * The collision type, used for collision checking.
	 */
	public var type(get, set):String;
	private inline function get_type() { return _type; }
	private inline function set_type(value:String):String
	{
		if (_type != value) {
			if (_world == null)
			{
				_type = value;
			} else {
				if (_type != null) _world.removeType(this);
				_type = value;
				if (value != null) _world.addType(this);
			}
		}
		return value;
	}
	
	/**
	 * An optional Mask component, used for specialized collision. If this is
	 * not assigned, collision checks will use the Entity's hitbox by default.
	 */
	public var mask(get, set):Mask;
	private inline function get_mask() { return _mask; }
	private inline function set_mask(value:Mask):Mask
	{
		if (_mask != value) {
			if (_mask != null) _mask.assignTo(null);
			_mask = value;
			if (value != null) _mask.assignTo(this);
		}
		return value;
	}
	
	/**
	 * Graphical component to render to the screen.
	 */
	public var graphic(get, set):Graphic;
	private inline function get_graphic() { return _graphic; }
	private inline function set_graphic(value:Graphic):Graphic
	{
		if (_graphic != value) {
			_graphic = value;
			if (value != null && value._assign != null) value._assign();
		}
		return value;
	}
	
	/**
	 * Adds the graphic to the Entity via a Graphiclist.
	 * @param	g		Graphic to add.
	 */
	public function addGraphic(g:Graphic):Graphic
	{
		if (Std.is(graphic, Graphiclist)) {
			cast(graphic, Graphiclist).add(g);
		}
		else
		{
			var list:Graphiclist = new Graphiclist();
			if (graphic != null) list.add(graphic);
			list.add(g);
			graphic = list;
		}
		return g;
	}
	
	/**
	 * Sets the Entity's hitbox properties.
	 * @param	width		Width of the hitbox.
	 * @param	height		Height of the hitbox.
	 * @param	originX		X origin of the hitbox.
	 * @param	originY		Y origin of the hitbox.
	 */
	public function setHitbox(width:Int = 0, height:Int = 0, originX:Int = 0, originY:Int = 0):Void
	{
		this.width = width;
		this.height = height;
		this.originX = originX;
		this.originY = originY;
	}
	
	/**
	 * Sets the Entity's hitbox to match that of the provided object.
	 * @param	o		The object defining the hitbox (eg. an Image or Rectangle).
	 */
	public function setHitboxTo(o:Dynamic):Void
	{
		if (Std.is(o, Image) || Std.is(o, Rectangle)) setHitbox(Std.int(Reflect.getProperty(o, "width")), Std.int(Reflect.getProperty(o, "height")), Std.int(Reflect.getProperty(o, "x")) * -1, Std.int(Reflect.getProperty(o, "y")) * -1);
		else
		{
			if (Reflect.hasField(o, "width")) width = Reflect.getProperty(o, "width");
			if (Reflect.hasField(o, "height")) width = Reflect.getProperty(o, "height");
			if (Reflect.hasField(o, "originX") && !(Std.is(o, Graphic))) originX = Reflect.getProperty(o, "originX");
			else if (Reflect.hasField(o, "x")) originX = -Std.int(Reflect.getProperty(o, "x"));
			if (Reflect.hasField(o, "originY") && !(Std.is(o, Graphic))) originY = Reflect.getProperty(o, "originY");
			else if (Reflect.hasField(o, "y")) originY = -Std.int(Reflect.getProperty(o, "y"));
		}
	}
	
	/**
	 * Sets the origin of the Entity.
	 * @param	x		X origin.
	 * @param	y		Y origin.
	 */
	public function setOrigin(x:Int = 0, y:Int = 0):Void
	{
		originX = x;
		originY = y;
	}
	
	/**
	 * Center's the Entity's origin (half width &amp; height).
	 */
	public function centerOrigin():Void
	{
		originX = Std.int(width / 2);
		originY = Std.int(height / 2);
	}
	
	/**
	 * Calculates the distance from another Entity.
	 * @param	e				The other Entity.
	 * @param	useHitboxes		If hitboxes should be used to determine the distance. If not, the Entities' x/y positions are used.
	 * @return	The distance.
	 */
	public function distanceFrom(e:Entity, useHitboxes:Bool = false):Float
	{
		var res:Float;
		if (!useHitboxes) res = Math.sqrt((x - e.x) * (x - e.x) + (y - e.y) * (y - e.y));
		else res = HP.distanceRects(x - originX, y - originY, width, height, e.x - e.originX, e.y - e.originY, e.width, e.height);
		return res;
	}
	
	/**
	 * Calculates the distance from this Entity to the point.
	 * @param	px				X position.
	 * @param	py				Y position.
	 * @param	useHitbox		If hitboxes should be used to determine the distance. If not, the Entities' x/y positions are used.
	 * @return	The distance.
	 */
	public function distanceToPoint(px:Float, py:Float, useHitbox:Bool = false):Float
	{
		var res:Float;
		if (!useHitbox) res = Math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
		else res = HP.distanceRectPoint(px, py, x - originX, y - originY, width, height);
		return res;
	}
	
	/**
	 * Calculates the distance from this Entity to the rectangle.
	 * @param	rx			X position of the rectangle.
	 * @param	ry			Y position of the rectangle.
	 * @param	rwidth		Width of the rectangle.
	 * @param	rheight		Height of the rectangle.
	 * @return	The distance.
	 */
	public function distanceToRect(rx:Float, ry:Float, rwidth:Float, rheight:Float):Float
	{
		return HP.distanceRects(rx, ry, rwidth, rheight, x - originX, y - originY, width, height);
	}
	
	/**
	 * Gets the class name as a string.
	 * @return	A string representing the class name.
	 */
	public function toString():String
	{
		var s:String = Std.string(_class);
		return s.substring(7, s.length - 1);
	}
	
	/**
	 * Moves the Entity by the amount, retaining integer values for its x and y.
	 * @param	x			Horizontal offset.
	 * @param	y			Vertical offset.
	 * @param	solidType	An optional collision type (or array of types) to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving objects from going through solidType).
	 */
	public function moveBy(x:Float, y:Float, solidTypes:Array<String> = null, sweep:Bool = false):Void
	{
		_moveX += x;
		_moveY += y;
		x = Math.round(_moveX);
		y = Math.round(_moveY);
		_moveX -= x;
		_moveY -= y;
		if (solidTypes != null)
		{
			var sign:Int, e:Entity;
			if (x != 0)
			{
				if (sweep || collideTypes(solidTypes, this.x + x, this.y) != null)
				{
					sign = x > 0 ? 1 : -1;
					while (x != 0)
					{
						e = collideTypes(solidTypes, this.x + sign, this.y);
						if (e != null)
						{
							if (moveCollideX(e)) break;
							else this.x += sign;
						}
						else this.x += sign;
						x -= sign;
					}
				}
				else this.x += x;
			}
			if (y != 0)
			{
				if (sweep || collideTypes(solidTypes, this.x, this.y + y) != null)
				{
					sign = y > 0 ? 1 : -1;
					while (y != 0)
					{
						e = collideTypes(solidTypes, this.x, this.y + sign);
						if (e != null)
						{
							if (moveCollideY(e)) break;
							else this.y += sign;
						}
						else this.y += sign;
						y -= sign;
					}
				}
				else this.y += y;
			}
		}
		else
		{
			this.x += x;
			this.y += y;
		}
	}
	
	/**
	 * Moves the Entity to the position, retaining integer values for its x and y.
	 * @param	x			X position.
	 * @param	y			Y position.
	 * @param	solidType	An optional collision type (or array of types) to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving objects from going through solidType).
	 */
	public function moveTo(x:Float, y:Float, solidTypes:Array<String> = null, sweep:Bool = false):Void
	{
		moveBy(x - this.x, y - this.y, solidTypes, sweep);
	}
	
	/**
	 * Moves towards the target position, retaining integer values for its x and y.
	 * @param	x			X target.
	 * @param	y			Y target.
	 * @param	amount		Amount to move.
	 * @param	solidType	An optional collision type (or array of types) to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving objects from going through solidType).
	 */
	public function moveTowards(x:Float, y:Float, amount:Float, solidTypes:Array<String> = null, sweep:Bool = false):Void
	{
		_point.x = x - this.x;
		_point.y = y - this.y;
		
		if (_point.x*_point.x + _point.y*_point.y > amount*amount) {
			_point.normalize(amount);
		}
		
		moveBy(_point.x, _point.y, solidTypes, sweep);
	}
	
	/**
	 * When you collide with an Entity on the x-axis with moveTo() or moveBy().
	 * @param	e		The Entity you collided with.
	 */
	public function moveCollideX(e:Entity):Bool
	{
		return true;
	}
	
	/**
	 * When you collide with an Entity on the y-axis with moveTo() or moveBy().
	 * @param	e		The Entity you collided with.
	 */
	public function moveCollideY(e:Entity):Bool
	{
		return true;
	}
	
	/**
	 * Clamps the Entity's hitbox on the x-axis.
	 * @param	left		Left bounds.
	 * @param	right		Right bounds.
	 * @param	padding		Optional padding on the clamp.
	 */
	public function clampHorizontal(left:Float, right:Float, padding:Float = 0):Void
	{
		if (x - originX < left + padding) x = left + originX + padding;
		if (x - originX + width > right - padding) x = right - width + originX - padding;
	}
	
	/**
	 * Clamps the Entity's hitbox on the y axis.
	 * @param	top			Min bounds.
	 * @param	bottom		Max bounds.
	 * @param	padding		Optional padding on the clamp.
	 */
	public function clampVertical(top:Float, bottom:Float, padding:Float = 0):Void
	{
		if (y - originY < top + padding) y = top + originY + padding;
		if (y - originY + height > bottom - padding) y = bottom - height + originY - padding;
	}
	
	/**
	 * The Entity's instance name. Use this to uniquely identify single
	 * game Entities, which can then be looked-up with World.getInstance().
	 */
	public var name(get, set):String;
	private inline function get_name() { return _name; }
	private inline function set_name(value:String):String
	{
		if (_name == value) return value;
		if (_name != null && _world != null) _world.unregisterName(this);
		_name = value;
		if (_name != null && _world != null) _world.registerName(this);
		return value;
	}
	
	public function getClassName():String { return _class; }
	
	// Entity information.
	/** @private */ public var _class:String;
	/** @private */ public var _world:World;
	/** @private */ public var _type:String;
	/** @private */ public var _name:String;
	/** @private */ public var _layer:Int = 0;
	/** @private */ public var _updatePrev:Entity;
	/** @private */ public var _updateNext:Entity;
	/** @private */ public var _renderPrev:Entity;
	/** @private */ public var _renderNext:Entity;
	/** @private */ public var _typePrev:Entity;
	/** @private */ public var _typeNext:Entity;
	/** @private */ public var _recycleNext:Entity;
	
	// Collision information.
	/** @private */ private var HITBOX:Mask;
	/** @private */ private var _mask:Mask;
	/** @private */ private var _x:Float = 0;
	/** @private */ private var _y:Float = 0;
	/** @private */ private var _moveX:Float = 0;
	/** @private */ private var _moveY:Float = 0;
	
	// Rendering information.
	/** @private */ public var _graphic:Graphic;
	/** @private */ private var _point:Point;
	/** @private */ private var _camera:Point;
}

