package ;

import flash.display.BitmapData;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.AntiAliasType;
import flash.text.TextFormatAlign;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.Utf8;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Backdrop;
import net.hxpunk.graphics.Emitter;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.ParticleType;
import net.hxpunk.graphics.PreRotation;
import net.hxpunk.graphics.Text;
import net.hxpunk.graphics.TiledImage;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Grid;
import net.hxpunk.masks.Pixelmask;
import net.hxpunk.Sfx;
import net.hxpunk.utils.Data;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Ease;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import openfl.Assets;
import openfl.display.FPS;
import net.hxpunk.graphics.BitmapFont;
import net.hxpunk.graphics.BitmapText;



/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	//Some constants used.
	private static inline var EDGE_MARGIN_X:Int = 8;
	private static inline var EDGE_MARGIN_Y:Int = 12;

	var BALL:String = "assets/ball.png";
	
	var BG_MUSIC_ID:String = "BGMUSIC";
	var bgMusic:Sfx;
	
	var SFX_WHIFF_ID:String = #if flash "assets/whiff.mp3" #else "assets/whiff_mono.ogg" #end;
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
	var emitter:Emitter;
	var emitterEntity:Entity;
	
	
	var tf:BitmapText;
	var font2:BitmapFont;
	var bd:BitmapData;
	
	
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
		
		var newFont = Assets.getFont("assets/Fischer_mod.ttf").fontName;
		HP.world.addGraphic(new Text("Ecciao!", 5, 20, {}));
		trace(Assets.getFont("assets/Fischer_mod.ttf").fontName);
		
		HP.world.addGraphic(text = new Text("Ecciao!", 5, 30, { color:0}));
		/*text.setTextProperty("antiAliasType", AntiAliasType.ADVANCED);
		text.setTextProperty("sharpness", 200);
		text.setTextProperty("thickness", 0);*/

		//var f = Assets.getFont("assets/Fischer_mod.ttf");
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
		
		Data.prefix = "personal";
		Data.load("savegame");
		Data.writeString("whats", "up");
		Data.writeBool("whats", true);
		Data.save();
		trace(Data.toString());
		Data.clear();
		//Data.save();
		trace(Data.toString());
		Data.load();
		trace(Data.toString());
		Data.clear();
		Data.save("savegame");
		HP.alarm(5, function ():Void 
		{
			trace("alarrrm!");
		});
		
		emitterEntity = new Entity(HP.halfWidth, HP.halfHeight / 2);
		var particlesBMD:BitmapData = new BitmapData(20, 10);
		Draw.setTarget(particlesBMD);
		Draw.rect(0, 0, 10, 10, 0x00FF00);
		Draw.rect(10, 0, 10, 10, 0xFF0000);
		emitter = new Emitter(particlesBMD, 10, 10);
		var p:ParticleType = emitter.newType("squares", HP.frames(1, 1, 0));
		p.setMotion(0, 80, 1.5, 360, 20, 0, null);
		p.setRotation(0, 360, 360, -720, false, Ease.quadIn);
		p.setColor(0xFFFFFF, 0xFF3366, Ease.quadIn);
		p.setAlpha(1, 0, Ease.cubeIn);
		//p.setGravity(85, 2);
		emitterEntity.graphic = emitter;
		HP.world.add(emitterEntity);

		
		// Initializing
		text = new Text("", 0, 0, { color:0xFFFF00, size:8 } );
		text.setStyle("red", { color: 0xFF0000 } );
		text.setStyle("bigger", { size:16 } );
		//text.setTextProperty("font", "fischer");
		text.width = HP.screen.width - EDGE_MARGIN_X * 2;
		text.wordWrap = true;
		text.smooth = false;
		text.align = TextFormatAlign.CENTER;
		text.richText = 
		   "It is a <red>long</red> established fact that a reader will be distracted by It is "+
		   "It is a long established fact that a reader will be distracted by It is "+
		   "It is a long established <bigger>fact</bigger> that a reader will be distracted by It is " +
		   "Discover here what has befallen the fallen.";

		HP.world.addGraphic(text);
		text.x = EDGE_MARGIN_X;
		text.y = Std.int(HP.screen.height * 1 / 4 + EDGE_MARGIN_Y);
		/*
		bgMusic = new Sfx(BG_MUSIC_ID, null, "bg_music");
		
		bgMusic.loop(.025, 0);
		
		whiffSfx = new Sfx(SFX_WHIFF_ID);
		*/
		stage.addChild(new FPS(5, 30, 0xFFFFFF));

		
		var str:Bytes = Bytes.ofString("0000122223334444ÇÇüÚ·²²²üü╝qqäXx¶¶");
		var b:String = "";
		for (i in 0...str.length) {
			b += String.fromCharCode(str.get(i)) + "";
		}
		trace("0000122223334444ÇÇüÚ·²²²üü╝qqäXx¶¶");
		trace(b);
		trace(str.toString());
		
		trace("╝".charCodeAt(0));
		trace(StringTools.fastCodeAt("╝", 0));
		trace(Utf8.charCodeAt("╝", 0));
		trace(Bytes.ofString("╝").toHex());
		trace(String.fromCharCode(Utf8.charCodeAt("╝", 0)));
		trace(String.fromCharCode(9565));
		trace(Bytes.ofString("╝").toString());
		var bdata:BytesData = Bytes.ofString("╝").getData();
		var uEnc:String = StringTools.urlEncode("╝");
		trace(StringTools.urlDecode(uEnc));
		trace(Bytes.ofData(bdata));
		//for (i in 0...BytesData.bdata.length) trace(bdata[i]);
		

		var enc;
		var dec;
		/*trace(enc = BitmapFont.rleEncodeStr(str));
		trace(dec = BitmapFont.rleDecodeStr(str));
		trace(dec == str);*/
	
	/*
	#if !web
		Sys.exit(0);
	#else
		System.exit(0);
	#end
	*/
		var textBytes = Assets.getText("assets/04b.fnt");
		var XMLData = Xml.parse(textBytes);
		font2 = new BitmapFont().fromXML(Assets.getBitmapData("assets/04b.png"), XMLData);
		//var font3 = new BitmapFont().loadFromPixelizer(Assets.getBitmapData("assets/round_font.png"), " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz[|]~\\");
		
		var ss = String.fromCharCode(188);
		//trace("utf188", Utf8.charCodeAt(ss, 0));
		trace(font2.serialize());
	
		/*
	#if !web
		Sys.exit(0);
	#else
		System.exit(0);
	#end
	*/	
		tf = new BitmapText("hola\ncom pagneros~\n", 0, 0);
		tf.text += BitmapFont.fetch("default").supportedGlyphs.substr(0, 30) + "\n";
		tf.text += BitmapFont.fetch("default").supportedGlyphs.substr(30, 30) + "\n";
		tf.text += BitmapFont.fetch("default").supportedGlyphs.substr(60) + "\n";
		tf.align = TextFormatAlign.CENTER;
		tf.centerOrigin();
		tf.outlineColor = 0x0;
		tf.shadowColor = 0xff0000;
		tf.shadow = true;
		tf.outline = true;
		tf.smooth = true;
		tf.fontScale = 1;
		//tf.angle = 30;
		tf.flipped = true;
		
		trace(String.fromCharCode(127).charCodeAt(0));
		//trace(font2.numGlyphs, font2.supportedGlyphs);
		
		var pixelizerFont = new BitmapFont().fromPixelizer(
			HP.getBitmapData("assets/round_font-pixelizer.png"), 
			" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂", 
			0xFF202020);
		var pixelizerText:BitmapText = new BitmapText("pixelizedr all wthe waeey!", 0, 0, pixelizerFont);
		HP.world.addGraphic(pixelizerText, 0, 100, 170);
		pixelizerText.scale = 2;

		//trace(font2.getSerializedData());
		//bd = BitmapFont.createDefaultFont();
		
		//tf.color = 0x0000ff;
		//tf.background = true;
		
	//	addChild(tf); // I don't add this component to display list as you can see
		/*tf.text = "Hello World!\nand this is\nmultiline!!!";
		
		tf.color = 0x0000ff;
		tf.background = true;
		tf.fixedWidth = false;
		tf.multiLine = true;
		tf.backgroundColor = 0x00ff00;
		tf.shadow = true;
		tf.setWidth(250);
		tf.align = TextFormatAlign.CENTER;
		tf.lineSpacing = 5;
		tf.fontScale = 2.5;
		tf.padding = 5;
		tf.scaleX = tf.scaleY = 2.5;
	//	tf.setAlpha(0.5);
		
	*/
		HP.world.addGraphic(tf, 0, HP.halfWidth, HP.halfHeight);
		
		//HP.world.addGraphic(new Image(bd), 0, 30, 30);
		
		/*
		var chars:Array<String> = new Array<String>();
		for (i in 0...256) {
			var u:UInt = i & 0xFF;
			chars.push(Std.string(u));
			var ch:String = String.fromCharCode(u);
			trace(StringTools.lpad(Std.string(u), "0", 3) + "\t" + byte2bits(u) + "\t" + ch);
		}*/
	}
	
	public function byte2bits(u:Int):String 
	{ 
		var res:String = "";
		var i:Int = 8;
		while (i > 0) {
			res = (u & 1 == 1 ? "1" : "0") + res;
			u = u >> 1;
			i--;
		}
		return res;
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
		
		var fe:FriendlyEntity = e;
		var hitbox:Mask = fe.HITBOX;
		
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
		
		if (Input.check(Key.Z) || Input.mousePressed) {
			new Sfx(SFX_WHIFF_ID).play();
			emitter.emit("squares", 0, 0);
			Draw.enqueueCall(function ():Void 
			{
				Draw.dot(emitterEntity.x, emitterEntity.y);
			});
		}
		
		if (Input.pressed(Key.SPACE)) {
			bgMusic.isPlaying ? bgMusic.stop() : bgMusic.resume();
		}
		
		
		if (Input.check(Key.I)) HP.volume += .05;
		if (Input.check(Key.K)) HP.volume -= .05;
		if (Input.check(Key.L)) HP.pan += .05;
		if (Input.check(Key.J)) HP.pan -= .05;
		
		//text.richText = "<bah>v:" + HP.toFixed(HP.volume, 1) + " </bah>p:" + HP.toFixed(HP.pan, 1) + "  part:" + emitter.particleCount;
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
