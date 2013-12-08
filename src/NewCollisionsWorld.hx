package;

import flash.utils.ByteArray;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.Point;
import flash.system.System;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFormat;
import net.hxpunk.masks.Polygon;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Image;
import net.hxpunk.HP;
import net.hxpunk.graphics.Text;
import net.hxpunk.masks.Circle;
import net.hxpunk.masks.Grid;
import net.hxpunk.masks.Hitbox;
import net.hxpunk.masks.Pixelmask;
import net.hxpunk.Tween;
import net.hxpunk.tweens.misc.NumTween;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import net.hxpunk.World;

/**
 * ...
 * @author azrafe7
 */
class NewCollisionsWorld extends World
{

	private var SKELETON:String = "assets/skeleton.png";
	
	private var eActive:Entity;
	private var ePoly:Entity;
	private var eCircle:Entity;
	private var circle:Circle;
	private var polygon:Polygon;
	private var text:Text;
	private var messages:Array<String>;
	private static inline var MAX_MESSAGES:Int = 7;
	private var hitEntities:Array<Entity>;
	private var e6:Entity;
	var imgPoly:Image;
	

	public function new() 
	{
		super();
	}
	
	override public function begin():Void {
		
		// interactive CIRCLE
		eCircle = addMask(circle = new Circle(20, 50,20), "circle");
		eCircle.x = HP.halfWidth;
		eCircle.y = HP.halfHeight + 20;
		eCircle.graphic = Image.createCircle(20, 0xFF00FF, .5, false, 1);
		eCircle.graphic.x = 50;
		eCircle.graphic.y = 20;
		eCircle.active = eCircle.visible = true;
		
		// interactive POLYGON
		var points:Array<Point> = new Array<Point>();
		points.push(new Point(0, 0));
		points.push(new Point(30, 0));
		points.push(new Point(30, 60));
		//ePoly = addMask(polygon = new Polygon(points), "polygon");
		ePoly = addMask(polygon = Polygon.createRegular(5, 20, 0), "polygon");
		ePoly.x = HP.halfWidth;
		ePoly.y = HP.halfHeight;
		/*ePoly.centerOrigin();
		polygon.x = ePoly.originX;
		polygon.y = ePoly.originY;			
		polygon.origin.x = ePoly.originX;
		polygon.origin.y = ePoly.originY;
		*/
		//imgPoly = Image.createRegularPolygon(5, 20, 0, 0xFFFF00, .7, true);
		imgPoly = Image.createPolygonFromPoints(polygon.points, 0xFFFF00, .7, true);
		imgPoly.smooth = true;
		ePoly.addGraphic(imgPoly);
		polygon.x = 10;
		polygon.y = 10;
		polygon.originX = 15;
		polygon.originY = 30;
		rotate(polygon, imgPoly, 0.0001);
		ePoly.active = ePoly.visible = true;
		
		// other MASKS
		
		
		// Mask/Entity
		var e1:Entity = new Entity(200, 30);
		e1.type = "mask";
		e1.width = 40;
		e1.height = 50;
		add(e1);
		
		// Hitbox
		var hitbox:Hitbox = new Hitbox(30, 30, 20);
		var e2:Entity = addMask(hitbox, "hitbox");
		e2.x = 20;
		e2.y = 20;

		// Circle
		var e3:Entity = addMask(new Circle(30, 0, 0), "circle");
		e3.x = 250;
		e3.y = 110;
		
		
		var asd:Entity = addMask(new Hitbox(60, 30), "bb", 50, 50);
		asd.graphic = Image.createRect(60, 30, 0xFFFF00, .7, false, 2, 20);
		asd.active = asd.visible = true;
		add(asd);
		
		// Grid
		var gridMask:Grid = new Grid(140, 80, 20, 20);
		var gridStr:String = 
		"1,0,0,1,1,1,0\n" +
		"0,0,0,1,0,1,1\n" +
		"1,0,0,0,0,0,1\n" +
		"0,0,0,0,0,0,1\n";
		gridMask.loadFromString(gridStr);
		gridMask.x = -6;
		gridMask.y = -10;
		var e4:Entity = addMask(gridMask, "grid", 5, 120);
		
		// Polygon
		var polyMask:Polygon = Polygon.createRegular(5, 20);
		var e5:Entity = addMask(polyMask, "polygon");
		e5.x = 130;
		e5.y = 40;
		e5.addGraphic(imgPoly);
		
		// Pixelmask
		var pixelmask:Pixelmask = new Pixelmask(SKELETON);
		e6 = addMask(pixelmask, "pixelmask");
		e6.x = 260;
		e6.y = 20;
		//pixelmask.x = 10;
		//pixelmask.y = 10;
		var pixelmask2:Pixelmask = new Pixelmask(SKELETON);
		var p2 = addMask(pixelmask2, "pixelmask");
		p2.x = 160;
		p2.y = 190;
		pixelmask2.x = 10;
		pixelmask2.y = 10;
		
		
		text = new Text("puppa!");
		var textEntity:Entity = new Entity(5, 55, text);
		text.blend = BlendMode.OVERLAY;
		text.scrollX = 0;
		text.scrollY = 0;
		text.scale = .5;
		text.setTextProperty("multiline", true);
		add(textEntity);
		
		messages = new Array<String>();
		messages.push("Enable the console...");
		messages.push("hit the play button on top...");
		messages.push("then use keys described below");
		
		text.text = messages.join("\n");
		
		HP.log("~: Console | SHIFT+ARROWS: Circle | ARROWS: Polygon | SPACE: rotate polygon");
		
		hitEntities = new Array<Entity>();
		
		eActive = e6;
	}
	
	override public function update():Void 
	{
		super.update();
		
		// ESC to exit
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
		// R to reset the world
		if (Input.pressed(Key.R)) {
			HP.world = new NewCollisionsWorld();
		}
		
		
		if (Input.pressed(Key.SPACE)) {
			rotate(polygon, imgPoly, imgPoly.angle + 15);
		}
				
		if (Input.check(Key.CONTROL)) {
			e6.x += Input.check(Key.LEFT) ? -1 : Input.check(Key.RIGHT) ? 1 : 0;
			e6.y += Input.check(Key.UP) ? -1 : Input.check(Key.DOWN) ? 1 : 0;
			eActive = e6;
		} else if (!Input.check(Key.SHIFT)) {
			ePoly.x += Input.check(Key.LEFT) ? -1 : Input.check(Key.RIGHT) ? 1 : 0;
			ePoly.y += Input.check(Key.UP) ? -1 : Input.check(Key.DOWN) ? 1 : 0;
			eActive = ePoly;
		} else if (Input.check(Key.SHIFT)) {
			eCircle.x += Input.check(Key.LEFT) ? -1 : Input.check(Key.RIGHT) ? 1 : 0;
			eCircle.y += Input.check(Key.UP) ? -1 : Input.check(Key.DOWN) ? 1 : 0;
			eActive = eCircle;
		}
		
		HP.removeAll(hitEntities);
		eActive.collideTypesInto(["hitbox", "mask", "circle", "grid", "polygon", "pixelmask"], eActive.x, eActive.y, hitEntities);
		
		for (i in 0...hitEntities.length) {
			var hitEntity:Entity = cast (hitEntities[i]);
			trace("hit " + hitEntity.type);
			messages.push("hit " + hitEntity.type);
			if (messages.length > MAX_MESSAGES) messages.splice(0, 1);
			text.text = messages.join("\n");
			
			HP.alarm(.2, function ():Void 
			{
				messages.splice(0, 1);
				text.text = messages.join("\n");
			});
		}

		
	}
	
	public function rotate(poly:Polygon, image:Image, angle:Float):Void 
	{
		/*
		trace("before");
		trace("img", imgPoly.x, imgPoly.y, imgPoly.originX, imgPoly.originY);
		trace("poly", polygon.x, polygon.y, polygon.originX, polygon.originY);
		trace(ePoly.x, ePoly.y, ePoly.originX, ePoly.originY);
		poly.angle = angle;
		image.originX = poly.originX;
		image.originY = poly.originY;
		image.angle = angle;
		image.x = polygon.x + polygon.originX;
		image.y = polygon.y + polygon.originY;
		trace("after");
		trace("img", imgPoly.x, imgPoly.y, imgPoly.originX, imgPoly.originY);
		trace("poly", polygon.x, polygon.y, polygon.originX, polygon.originY);
		trace(ePoly.x, ePoly.y, ePoly.originX, ePoly.originY);*/
		poly.angle = angle;
		image.syncWithPolygon(poly);
		
	}
	
	override public function render():Void 
	{
		super.render();
		Draw.dot(ePoly.x, ePoly.y);
		Draw.dot(ePoly.x + polygon.x + polygon.originX, ePoly.y + polygon.y + polygon.originY, 0xFFFF00);
		
		Draw.poly(0, 0, polygon.points, 0x0000FF, .5, true, false, 5);
	}
}
