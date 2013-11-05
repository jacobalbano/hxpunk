package ;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.errors.Error;
import flash.filters.BlurFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import haxe.ds.Vector.Vector;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Graphiclist;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Masklist;
import net.hxpunk.masks.Pixelmask;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Ease;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import openfl.Assets;
import net.hxpunk.graphics.Stamp;
import net.hxpunk.graphics.Backdrop;
import net.hxpunk.graphics.Canvas;
import net.hxpunk.graphics.TiledImage;
import net.hxpunk.graphics.Spritemap;
import net.hxpunk.graphics.TiledSpritemap;
import net.hxpunk.graphics.TiledImage;
import net.hxpunk.graphics.Tilemap;
import net.hxpunk.graphics.PreRotation;
import net.hxpunk.graphics.Particle;
import net.hxpunk.graphics.Emitter;
import net.hxpunk.tweens.misc.AngleTween;
import net.hxpunk.tweens.misc.ColorTween;
import net.hxpunk.tweens.misc.MultiVarTween;
import net.hxpunk.tweens.misc.NumTween;
import net.hxpunk.tweens.misc.VarTween;
import net.hxpunk.tweens.motion.Motion;
import net.hxpunk.tweens.motion.CircularMotion;
import net.hxpunk.tweens.motion.LinearMotion;
import net.hxpunk.tweens.motion.LinearPath;
import net.hxpunk.tweens.motion.CubicMotion;
import net.hxpunk.tweens.motion.QuadMotion;
import net.hxpunk.tweens.motion.QuadPath;



/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	var t:TiledImage;
	
	private var e:Entity;
	var deltaScale:Float = -.1;
	var text:Text;
	var preRotation:PreRotation;
	var bg:Backdrop;
	var box:Entity;

	var _point:Point;
	var _rect:Rectangle;
	
    public function new() {
        super(320, 240, 60, false);
    }
	
    override public function init():Void {
        super.init();
		HP.screen.scale = 2;
        HP.console.enable();
		HP.watch("right");
		
		trace(HP.NAME + " is running!");
		
		t = new TiledImage("assets/ball.png");
		
		//HP.world.addGraphic(bg = new Backdrop(BALL));
		//bg.visible = false;
		
		//var img:Image = Image.createRect(40, 40);
		var img:Image = new Image("assets/ball.png");
		img.centerOrigin();
		e = new Entity(0, 0, img);
		HP.world.add(e, HP.halfWidth, HP.halfHeight);
		e.name = "Ball";
		e.setHitboxTo(img);
		e.centerOrigin();
		img.angle = 45;
		
		//img.blend = BlendMode.SUBTRACT;
		
		for (i in 0...35) HP.log(i, [1, 2, 3]);
		
		HP.world.addGraphic(text = new Text("Ecciao!", 5, 30));
		
		/*var g:Graphiclist = new Graphiclist();
		g.add(e.graphic);
		g.add(e.graphic);
		HP.world.addGraphic(g, 0, 200);
		*/
		
		text.scale = 2;
		text.setStyle("bah", { color: 0x343434 } );
		text.richText = "font color=<bah>'#343434'</bah></font>";
		
		text.setTextProperty("color", 0xFFFFFF);
		
		trace(Ease.fromPennerFormat(.5));
		
		box = new Entity(preRotation = new PreRotation("assets/obstacle.png"));
		preRotation.centerOrigin();
		preRotation.angle = 45;
		
		box.mask = new Pixelmask("assets/ball.png");
		_point = new Point();
		_rect = new Rectangle();
		
		box.centerOrigin();
		HP.world.add(box, 250, 120);
		box.name = "Box";
    }
	
	override public function update():Void 
	{
		super.update();
		
		// ESC to exit
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
		// move Entity with arrows
		var dx:Float = 0;
		var dy:Float = 0;
		if (Input.check(Console.ARROW_KEYS)) {
			dx += Input.check(Key.LEFT) ? -1 : Input.check(Key.RIGHT) ? 1 : 0;
			dy += Input.check(Key.UP) ? -1 : Input.check(Key.DOWN) ? 1 : 0;
		}
		e.x += dx * 2;
		e.y += dy * 2;
		
		// scale and rotate Entity
		var img:Image = cast e.graphic;
		if (img.scale > 2.5 || img.scale < 0.5) deltaScale *= -1;
		img.scale += deltaScale;
		img.angle += 1.5;
		img.angle %= 360;
		
		//preRotation.angle += 1.5;
		preRotation.angle %= 360;
		
		
		var pixelMask:Pixelmask = cast box.mask;
		pixelMask.data = preRotation.buffer;
		pixelMask.x = -pixelMask.width >> 1;
		pixelMask.y = -pixelMask.height >> 1;
		pixelMask.threshold = 50;
		
		Draw.enqueueCall(function ():Void 
		{
				Draw.hitbox(box, true, 0xFF0000);
				Draw.hitbox(e, true, 0xFF0000);
				
		});
		if (box.collideWith(e, box.x, box.y) != null) {
			preRotation.color = 0xFF0000;
			trace("collision");
		} else {
			preRotation.color = 0xFFFFFF;
		}
		
		var hitbox:Mask = e.HITBOX;
		
		_point.x = pixelMask.parent.x + pixelMask.x;
		_point.y = pixelMask.parent.y + pixelMask.y;
		_rect.x = hitbox.parent.x - hitbox.parent.originX;
		_rect.y = hitbox.parent.y - hitbox.parent.originY;
		_rect.width = hitbox.parent.width;
		_rect.height = hitbox.parent.height;
		
		if (Mask.hitTest(pixelMask.data, _point, 100, _rect)) {
			preRotation.color |= 0x00FF00;
		}
		
		if (Input.released(Key.B)) {
			trace(Key.name(Input.lastKey));
		}
		
		//text.text = Std.string(System.totalMemory / 1024 / 1024);
		//text.text = Std.string(HP.frameRate);
		
		// move camera around
		if (Input.check(Key.A)) HP.camera.x -= 2; 
		if (Input.check(Key.D)) HP.camera.x += 2; 
		if (Input.check(Key.W)) HP.camera.y -= 2; 
		if (Input.check(Key.S)) HP.camera.y += 2; 
		
	}
	
	override public function render():Void 
	{
		super.render();
		
		Draw.blend = BlendMode.ADD;
		Draw.rect(0, 0, 100, 100, 0x00FF00);
		Draw.rect(0, 0, 100, 100, 0xFF0000);
		Draw.blend = BlendMode.NORMAL;
	}
	
    public static function main() { 
		new Main(); 
	}
	
	/*
	public static function upd():Void 
	{
		trace("update");
	}*/
}

@:bitmap("assets/ball.png")
class BALL extends flash.display.BitmapData { }
