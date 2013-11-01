package ;

import flash.display.BlendMode;
import flash.system.System;
import haxe.ds.Vector.Vector;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Graphiclist;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.masks.Pixelmask;
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
import net.hxpunk.masks.Grid;

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
		
		HP.world.addGraphic(bg = new Backdrop(BALL));
		bg.visible = false;
		
		//var img:Image = Image.createRect(40, 40);
		var img:Image = new Image("assets/ball.png");
		img.centerOrigin();
		e = new Entity(0, 0, img);
		HP.world.add(e, HP.halfWidth, HP.halfHeight);
		e.setHitboxTo(img);
		e.mask = new Pixelmask("assets/ball.png");
		e.centerOrigin();
		img.angle = 45;
		
		img.blend = BlendMode.MULTIPLY;
		
		for (i in 0...35) HP.log(i, [1, 2, 3]);
		
		HP.world.addGraphic(text = new Text("Ecciao!", 5, 30));
		
		var g:Graphiclist = new Graphiclist();
		g.add(e.graphic);
		g.add(e.graphic);
		HP.world.addGraphic(g);
		
		text.scale = 2;
		text.setStyle("bah", { color: 0x343434 } );
		text.richText = "font color=<bah>'#343434'</bah></font>";
		
		trace(Ease.fromPennerFormat(.5));
		
		box = new Entity(preRotation = new PreRotation("assets/obstacle.png"));
		preRotation.centerOrigin();
		box.setHitboxTo(preRotation);
		box.centerOrigin();
		HP.world.add(box, 50, 120);
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
		
		preRotation.angle += 1.5;
		preRotation.angle %= 360;
		
		var pixelMask:Pixelmask = cast e.mask;
		pixelMask.data = preRotation.buffer;
		pixelMask.x = -pixelMask.width >> 1;
		pixelMask.y = -pixelMask.height >> 1;
		
		if (e.collideWith(box, e.x, e.y) != null) {
			trace("collision");
		}
		
		if (Input.released(Key.B)) {
			trace(Key.name(Input.lastKey));
		}
		
		//text.text = Std.string(System.totalMemory / 1024 / 1024);
		//text.text = Std.string(HP.frameRate);
	}
	
    public static function main() { 
		new Main(); 
	}
}

@:bitmap("assets/ball.png")
class BALL extends flash.display.BitmapData { }
