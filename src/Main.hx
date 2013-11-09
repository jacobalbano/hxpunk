package ;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.errors.Error;
import flash.events.KeyboardEvent;
import flash.filters.BlurFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.system.System;
import flash.ui.Keyboard;
import haxe.ds.Vector.Vector;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Graphiclist;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Grid;
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
import flash.media.Sound;
import net.hxpunk.Sfx;
import net.hxpunk.utils.Data;


/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	var BG_MUSIC_ID:String = "BGMUSIC";
	var bgMusic:Sfx;
	
	var SFX_WHIFF_ID:String = #if flash "assets/whiff.mp3" #else "assets/whiff.ogg" #end;
	var whiffSfx:Sfx;
	
	var t:TiledImage;
	
	private var e:Entity;
	var deltaScale:Float = -.1;
	var text:Text;
	var preRotation:PreRotation;
	var bg:Backdrop;
	var box:Entity;

	var _point:Point;
	var _rect:Rectangle;
	var gridEntity2:Entity;
	
    public function new() {
        super(320, 240, 60, false);
    }
	
    override public function init():Void {
        super.init();
		HP.screen.scale = 2;
        HP.console.enable();
		HP.watch("name");
		HP.watch("originX");
		HP.watch("originY");
		
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
		e.type = "solid";
		//e.setHitboxTo(img);
		e.mask = new Pixelmask("assets/obstacle.png");
		cast(e.mask, Pixelmask).threshold = 100;
		e.centerOrigin();
		img.angle = 45;
		
		//img.blend = BlendMode.SUBTRACT;
		
		for (i in 0...35) HP.log(i, [1, 2, 3]);
		
		HP.world.addGraphic(text = new Text("Ecciao!", 5, 30, {color:0}));
		
		/*var g:Graphiclist = new Graphiclist();
		g.add(e.graphic);
		g.add(e.graphic);
		HP.world.addGraphic(g, 0, 200);
		*/
		
		text.scale = 2;
		text.setStyle("bah", { color: 0x343434 } );
		text.richText = "font color=<bah>'#343434'</bah></font>";
		
		text.color = 0xFFF000;
		
		trace(Ease.fromPennerFormat(.5));
		
		box = new Entity(preRotation = new PreRotation("assets/obstacle.png"));
		preRotation.centerOrigin();
		preRotation.angle = 45;
		
		box.mask = new Pixelmask("assets/ball.png");
		_point = new Point();
		_rect = new Rectangle();
		
		//box.centerOrigin();
		HP.world.add(box, 250, 120);
		box.name = "Box";
		box.type = "pixelmask";
		
		HP.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		var gridMask:Grid = new Grid(140, 80, 20, 20);
		var gridStr = 
		"1,0,0,1,1,1,0\n" +
		"0,0,0,1,0,1,1\n" +
		"1,0,0,0,0,0,1\n" +
		"0,0,0,0,0,0,1\n";
		gridMask.loadFromString(gridStr);
		HP.world.addMask(gridMask, "solid", 0, 120);
		
		var gridMask2:Grid = new Grid(140, 80, 20, 20);
		var gridStr2 = 
		"1,0,0,0,0,0,0\n" +
		"0,0,0,0,0,0,0\n" +
		"0,0,0,0,0,0,0\n" +
		"0,0,0,0,0,0,0\n";
		gridMask2.loadFromString(gridStr2);
		gridEntity2 = HP.world.addMask(gridMask2, "solid", 150, 150);
		
		
		HP.log("WASD - camera | ARROWS - ball | SHIFT + ARROWS - grid");
		
		bgMusic = new Sfx(BG_MUSIC_ID, null, "bg_music");
		
		bgMusic.loop(0, 0);
		whiffSfx = new Sfx(SFX_WHIFF_ID);
		
		Data.prefix = "personal";
		Data.load("savegame");
		Data.writeString("whats", "up");
		Data.save();
		trace(Data.toString());
		Data.clear();
		trace(Data.toString());
		Data.load("savegame");
		trace(Data.toString());
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
		
		if (Input.check(Key.SHIFT)) {
			gridEntity2.moveBy(dx * 2, dy * 2, ["solid", "pixelmask"], true);
		} else {
			e.moveBy(dx * 2, dy * 2, ["solid"], true);
		}
		
		// scale and rotate Entity
		var img:Image = cast e.graphic;
		if (img.scale > 2.5 || img.scale < 0.5) deltaScale *= -1;
		img.scale += deltaScale;
		img.angle += 1.5;
		img.angle %= 360;
		
		//preRotation.angle += 1.5;
		preRotation.angle %= 360;
		
		if (e.collideTypes(["solid"], e.x, e.y) != null) {
			cast(e.graphic, Image).color = 0xFF0000;
		} else {
			cast(e.graphic, Image).color = 0xFFFFFF;
		}
		
		var pixelMask:Pixelmask = cast box.mask;
		pixelMask.data = preRotation.buffer;
		pixelMask.x = -pixelMask.width >> 1;
		pixelMask.y = -pixelMask.height >> 1;
		pixelMask.threshold = 90;
		
		preRotation.originX = 20;
		preRotation.originY = 20;
		
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
		
		if (Mask.hitTest(pixelMask.data, _point, 1, _rect)) {
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
		
		if (Input.pressed(Key.Z)) {
			new Sfx(SFX_WHIFF_ID).play();
		}
		
		if (Input.pressed(Key.SPACE)) {
			bgMusic.isPlaying ? bgMusic.stop() : bgMusic.resume();
		}
		
		
		if (Input.check(Key.I)) HP.volume += .05;
		if (Input.check(Key.K)) HP.volume -= .05;
		if (Input.check(Key.L)) HP.pan += .05;
		if (Input.check(Key.J)) HP.pan -= .05;
		
		text.text = "v:" + HP.toFixed(HP.volume, 1) + " p:" + HP.toFixed(HP.pan, 1);
	}
	
	override public function render():Void 
	{
		super.render();
		
	}
	
	public function onKeyDown(e:KeyboardEvent):Void 
	{
		//trace("Keys:", e.charCode, Input.lastKey, e.keyCode);
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

