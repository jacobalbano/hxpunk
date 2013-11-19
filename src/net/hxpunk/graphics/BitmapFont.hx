package net.hxpunk.graphics;
import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.Serializer;
import net.hxpunk.HP;
import net.hxpunk.utils.Draw;


/**
 * Holds information and bitmap glyphs for a bitmap font.
 * 
 * Adapted from Beeblerox work (which built upon Pixelizer implementation).
 * 
 * @see https://github.com/Beeblerox/BitmapFont
 */
class BitmapFont 
{
	
	/**
	 * Creates a new bitmap font. Use one of the load_ methods to actually load the font.
	 */
	public function new() 
	{
		if (_storedFonts == null) _storedFonts = new Map<String, BitmapFont>();
		
		_maxHeight = 0;
		_colorTransform = new ColorTransform();
		_glyphs = new Array<BitmapData>();
	}
	
	/**
	 * Loads font data from Pixelizer's format
	 * @param	bitmapData	Font source image
	 * @param	letters		All letters contained in this font
	 * @return this BitmapFont
	 */
	public function loadFromPixelizer(bitmapData:BitmapData, letters:String):BitmapFont
	{
		reset();
		_glyphString = letters;
		
		if (bitmapData != null) 
		{
			var tileRects:Array<Rectangle> = [];
			var result:BitmapData = prepareBitmapData(bitmapData, tileRects);
			var currRect:Rectangle;
			
			for (letterID in 0...(tileRects.length))
			{
				currRect = tileRects[letterID];
				
				// create glyph
				var bd:BitmapData = new BitmapData(Math.floor(currRect.width), Math.floor(currRect.height), true, 0x0);
				bd.copyPixels(bitmapData, currRect, HP.zero, null, null, true);
				
				// store glyph
				setGlyph(_glyphString.charCodeAt(letterID), bd);
			}
		}
		
		return this;
	}
	
	/**
	 * Loads font data form XML (AngelCode's) format
	 * @param	bitmapData		Font image source
	 * @param	XMLData			Font data in XML format
	 * @return	this BitmapFont
	 */
	public function loadFromXML(bitmapData:BitmapData, XMLData:Xml):BitmapFont
	{
		reset();
		
		if (bitmapData != null) 
		{
			_glyphString = "";
			var rect:Rectangle = new Rectangle();
			var point:Point = new Point();
			var bd:BitmapData;
			var letterID:Int = 0;
			var charCode:Int;
			var charString:String;
			
			var chars:Xml = null;
			for (node in XMLData.elements())
			{
				if (node.nodeName == "font")
				{
					for (nodeChild in node.elements())
					{
						if (nodeChild.nodeName == "chars")
						{
							chars = nodeChild;
							break;
						}
					}
				}
			}
			
			if (chars != null)
			{
				for (node in chars.elements())
				{
					if (node.nodeName == "char")
					{
						rect.x = Std.parseInt(node.get("x"));
						rect.y = Std.parseInt(node.get("y"));
						rect.width = Std.parseInt(node.get("width"));
						rect.height = Std.parseInt(node.get("height"));
						
						point.x = Std.parseInt(node.get("xoffset"));
						point.y = Std.parseInt(node.get("yoffset"));
						
						charCode = Std.parseInt(node.get("id"));
						charString = String.fromCharCode(charCode);
						_glyphString += charString;
						
						var xadvance:Int = Std.parseInt(node.get("xadvance"));
						var charWidth:Int = xadvance;
						
						if (rect.width > xadvance)
						{
							charWidth = Std.int(rect.width);
							point.x = 0;
						}
						
						// create glyph
						bd = null;
						if (charString != " " && charString != "")
						{
							bd = new BitmapData(charWidth, Std.parseInt(node.get("height")) + Std.parseInt(node.get("yoffset")), true, 0x0);
						}
						else
						{
							bd = new BitmapData(charWidth, 1, true, 0x0);
						}
						bd.copyPixels(bitmapData, rect, point, null, null, true);
						
						// store glyph
						setGlyph(charCode, bd);
						
						letterID++;
					}
				}
			}
		}
		
		return this;
	}
	
	/**
	 * Internal function. Resets current font
	 */
	private function reset():Void
	{
		dispose();
		_maxWidth = 0;
		_maxHeight = 0;
		_glyphs = [];
		_glyphString = "";
	}
	
	/**
	 * Adjusts the font BitmapData making background transparent and stores glyphs positions in the rects array.
	 * @return The modified BitmapData.
	 */
	public function prepareBitmapData(bitmapData:BitmapData, rects:Array<Rectangle>):BitmapData
	{
		var bgColor:Int = bitmapData.getPixel(0, 0);
		var cy:Int = 0;
		var cx:Int;
		
		while (cy < bitmapData.height)
		{
			var rowHeight:Int = 0;
			cx = 0;
			
			while (cx < bitmapData.width)
			{
				if (Std.int(bitmapData.getPixel(cx, cy)) != bgColor) 
				{
					// found non bg pixel
					var gx:Int = cx;
					var gy:Int = cy;
					// find width and height of glyph
					while (Std.int(bitmapData.getPixel(gx, cy)) != bgColor)
					{
						gx++;
					}
					while (Std.int(bitmapData.getPixel(cx, gy)) != bgColor)
					{
						gy++;
					}
					var gw:Int = gx - cx;
					var gh:Int = gy - cy;
					
					rects.push(new Rectangle(cx, cy, gw, gh));
					
					// store max size
					if (gh > rowHeight) 
					{
						rowHeight = gh;
					}
					if (gh > _maxHeight) 
					{
						_maxHeight = gh;
					}
					
					// go to next glyph
					cx += gw;
				}
				
				cx++;
			}
			// next row
			cy += (rowHeight + 1);
		}
		
		var resultBitmapData:BitmapData = bitmapData.clone();
		
		var pixelColor:UInt;
		var bgColor32:UInt = bitmapData.getPixel(0, 0);
		
		cy = 0;
		while (cy < bitmapData.height)
		{
			cx = 0;
			while (cx < bitmapData.width)
			{
				pixelColor = bitmapData.getPixel32(cx, cy);
				if (pixelColor == bgColor32)
				{
					resultBitmapData.setPixel32(cx, cy, 0x00000000);
				}
				cx++;
			}
			cy++;
		}
		
		return resultBitmapData;
	}
	
	/**
	 * Prepares and returns a set of glyphs using the specified parameters.
	 */
	public function getPreparedGlyphs(scale:Float, color:Int, ?useColorTransform:Bool = true):Array<BitmapData>
	{
		var result:Array<BitmapData> = [];
		
		HP.matrix.identity();
		HP.matrix.scale(scale, scale);
		
		var colorMultiplier:Float = 0.00392;
		_colorTransform.redOffset = 0;
		_colorTransform.greenOffset = 0;
		_colorTransform.blueOffset = 0;
		_colorTransform.redMultiplier = (color >> 16) * colorMultiplier;
		_colorTransform.greenMultiplier = (color >> 8 & 0xff) * colorMultiplier;
		_colorTransform.blueMultiplier = (color & 0xff) * colorMultiplier;
		
		var glyph:BitmapData;
		var preparedGlyph:BitmapData;
		for (i in 0...(_glyphs.length))
		{
			glyph = _glyphs[i];
			var bdWidth:Int;
			var bdHeight:Int;
			if (glyph != null)
			{
				if (scale > 0)
				{
					bdWidth = Math.ceil(glyph.width * scale);
					bdHeight = Math.ceil(glyph.height * scale);
				}
				else
				{
					bdWidth = 1;
					bdHeight = 1;
				}
				
				preparedGlyph = new BitmapData(bdWidth, bdHeight, true, 0x00000000);
				if (useColorTransform)
				{
					preparedGlyph.draw(glyph,  HP.matrix, _colorTransform);
				}
				else
				{
					preparedGlyph.draw(glyph,  HP.matrix);
				}
				result[i] = preparedGlyph;
			}
		}
		
		return result;
	}
	
	/** Returns a string with all the supported glyphs. */
	public var supportedGlyphs(get, null):String;
	private function get_supportedGlyphs():String {
		return _glyphString;
	}
	
	/**
	 * Clears all resources used by the font.
	 */
	public function dispose():Void 
	{
		var bd:BitmapData;
		for (i in 0...(_glyphs.length)) 
		{
			bd = _glyphs[i];
			if (bd != null) 
			{
				_glyphs[i].dispose();
			}
		}
		_glyphs = null;
	}
	
	/**
	 * Serializes the font as a bit font by encoding it into a big string (max 224 glyphs, no alpha is encoded, pixels are either on (alpha == 1) or off (otherwise)).
	 * 
	 * Format:
	 * 	   [fromCharCode(numGlyphs + 32)][fromCharCode(maxWidth + 32)][fromCharCode(height + 32)] then for each glyph [char][fromCharCode(width + 32)][fromCharCode(height + 32)][series of 0 or 1 for each pixel of the glyph]...
	 * 
	 * @return	Serialized font string.
	 */
	public function getSerializedData():String 
	{
		var output:String = String.fromCharCode(numGlyphs + 32) + String.fromCharCode(maxWidth + 32)+ String.fromCharCode(height + 32);
		for (i in 0...(_glyphString.length)) 
		{
			var charCode:Int = _glyphString.charCodeAt(i);
			var glyph:BitmapData = _glyphs[charCode];
			output += _glyphString.substr(i, 1);
			output += String.fromCharCode(glyph.width + 32);
			output += String.fromCharCode(glyph.height + 32);
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					output += (((glyph.getPixel32(px, py) & 0xFF000000) == 0xFF000000) ? "1" : "0");
				}
			}
		}
		return output;
	}

	/**
	 * Deserializes a font encoded with getSerializedData().
	 * 
	 * @return	The deserialized BitmapFont.
	 */
	public static function loadFromSerializedData(encodedFont:String):BitmapFont 
	{
		var letters:String = "";
		var letterPos:Int = 0;
		var i:Int = 0;
		
		var n:Int = encodedFont.charCodeAt(i) - 32;		// number of glyphs
		var w:Int = encodedFont.charCodeAt(++i) - 32;	// max width of single glyph
		var h:Int = encodedFont.charCodeAt(++i) - 32;	// max height of single glyph
		var size:Int = Std.int(Math.ceil(Math.sqrt(n * (w + 1) * (h + 1))) + Math.max(w, h));
		var rows:Int = Std.int(size / (h + 1));
		var cols:Int = Std.int(size / (w + 1));
		var bd:BitmapData = new BitmapData(size, size, true, 0xFFFF0000);
		
		while (i < encodedFont.length) 
		{
			letters += encodedFont.substr(++i, 1);
			
			var gw:Int = encodedFont.charCodeAt(++i) - 32;
			var gh:Int = encodedFont.charCodeAt(++i) - 32;
			
			for (py in 0...gh) 
			{
				for (px in 0...gw) 
				{
					i++;
					
					var pixelOn:Bool = encodedFont.substr(i, 1) == "1"; 
					bd.setPixel32(1 + (letterPos % cols) * (w + 1) + px, 1 + Std.int(letterPos / cols) * (h + 1) + py, pixelOn ? 0xFFFFFFFF : 0x0);
				}
			}
			
			letterPos++;
		}
		
		var font:BitmapFont = new BitmapFont().loadFromPixelizer(bd, letters);
		bd.dispose();
		bd = null;
		
		return font;
	}

	/**
	 * Sets the BitmapData for a specific glyph.
	 */
	private function setGlyph(charID:Int, bitmapData:BitmapData):Void 
	{
		if (_glyphs[charID] != null) 
		{
			_glyphs[charID].dispose();
		}
		
		_glyphs[charID] = bitmapData;
		
		if (bitmapData.width > _maxWidth) 
		{
			_maxWidth = bitmapData.width;
		}
		if (bitmapData.height > _maxHeight) 
		{
			_maxHeight = bitmapData.height;
		}
	}
	
	/**
	 * Renders a string of text onto bitmap data using the font.
	 * @param	bitmapData	Where to render the text.
	 * @param	text		Test to render.
	 * @param	color		Color of text to render.
	 * @param	offsetX		X position of text output.
	 * @param	offsetY		Y position of text output.
	 */
	public function render(bitmapData:BitmapData, fontData:Array<BitmapData>, text:String, color:UInt, offsetX:Float, offsetY:Float, letterSpacing:Int):Void 
	{
		HP.point.x = offsetX;
		HP.point.y = offsetY;

		var glyph:BitmapData;
		
		for (i in 0...(text.length)) 
		{
			var charCode:Int = text.charCodeAt(i);

			glyph = fontData[charCode];
			if (glyph != null) 
			{
				bitmapData.copyPixels(glyph, glyph.rect, HP.point, null, null, true);
				HP.point.x += glyph.width + letterSpacing;
			}
		}
	}
		
	/**
	 * Returns the width of a certain test string.
	 * @param	text			String to measure.
	 * @param	letterSpacing	Distance between letters.
	 * @param	fontScale		"size" of the font.
	 * @return	Width in pixels.
	 */
	public function getTextWidth(text:String, ?letterSpacing:Int = 0, ?fontScale:Float = 1.0):Int 
	{
		var w:Int = 0;
		
		var textLength:Int = text.length;
		for (i in 0...(textLength)) 
		{
			var charCode:Int = text.charCodeAt(i);
			var glyph:BitmapData = _glyphs[charCode];
			if (glyph != null) 
			{
				
				w += glyph.width;
			}
		}
		
		w = Math.round(w * fontScale);
		
		if (textLength > 1)
		{
			w += (textLength - 1) * letterSpacing;
		}
		
		return w;
	}
	
	/**
	 * Returns the height of font in pixels.
	 */
	public var height(get, null):Int;
	private inline function get_height():Int 
	{
		return _maxHeight;
	}
	
	/**
	 * Returns the width of the largest glyph.
	 */
	public var maxWidth(get, null):Int;
	private inline function get_maxWidth():Int 
	{
		return _maxWidth;
	}
	
	/**
	 * Returns number of glyphs available in this font.
	 * @return Number of glyphs available in this font.
	 */
	public var numGlyphs(get, null):Int;
	private inline function get_numGlyphs():Int 
	{
		return _glyphs.length;
	}
	
	/**
	 * Stores a font for global use using an identifier.
	 * @param	fontName	String identifer for the font.
	 * @param	font		Font to store.
	 */
	public static function store(fontName:String, font:BitmapFont):Void 
	{
		_storedFonts.set(fontName, font);
	}
	
	/**
	 * Retrieves a font previously stored.
	 * @param	fontName	Identifier of font to fetch.
	 * @return	Stored font, or null if no font was found.
	 */
	public static function fetch(fontName:String):BitmapFont 
	{
		var f:BitmapFont = _storedFonts.get(fontName);
		return f;
	}

	/**
	 * Creates and stores the default font for later use.
	 */
	public static function createDefaultFont():Void
	{
		var defaultFont:BitmapFont = loadFromSerializedData(_DEFAULT_FONT_DATA);
		BitmapFont.store("default", defaultFont);
	}

	/** Serialized default font data. (04B_03__.ttf @ 16px) */
	private static inline var _DEFAULT_FONT_DATA:String = "Á,0 (!00000000!$,000000000110011001100110011001100000000001100110\"('00000000000000000110011001100110011001100110011000000000#,,000000000000000000000000000110011000000110011000011111111110011111111110000110011000000110011000011111111110011111111110000110011000000110011000$*.00000000000000000000000001100000000110000001111110000111111001111000000111100000000001111000000111100111111000011111100000000110000000011000%,,000000000000000000000000011000011000011000011000000000011000000000011000000001100000000001100000000110000000000110000000000110000110000110000110&,,000000000000000000000000000111100000000111100000011000000000011000000000000111100110000111100110011000011000011000011000000111100110000111100110'$'0000000001100110011001100000(&,000000000000000110000110011000011000011000011000011000011000000110000110)&,000000000000011000011000000110000110000110000110000110000110011000011000*()000000000000000001100110011001100001100000011000011001100110011000000000+(+0000000000000000000000000000000000011000000110000111111001111110000110000001100000000000,&.000000000000000000000000000000000000000000000000000000000000000110000110011000011000-()000000000000000000000000000000000000000000000000011111100111111000000000.$,000000000000000000000000000000000000000001100110/,,0000000000000000000000000000000001100000000001100000000110000000000110000000011000000000011000000001100000000001100000000110000000000110000000000*,0000000000000000000000011110000001111000011000011001100001100110000110011000011001100001100110000110000111100000011110001&,0000000000000111100111100001100001100001100001100001100001100001100001102*,0000000000000000000001111110000111111000000000011000000001100001111000000111100001100000000110000000011111111001111111103*,0000000000000000000001111110000111111000000000011000000001100001111000000111100000000001100000000110011111100001111110004*,0000000000000000000000000110000000011000000111100000011110000110011000011001100001111111100111111110000001100000000110005*,0000000000000000000001111111100111111110011000000001100000000111111000011111100000000001100000000110011111100001111110006*,0000000000000000000000011110000001111000011000000001100000000111111000011111100001100001100110000110000111100000011110007*,0000000000000000000001111111100111111110000000011000000001100000011000000001100000011000000001100000000110000000011000008*,0000000000000000000000011110000001111000011000011001100001100001111000000111100001100001100110000110000111100000011110009*,000000000000000000000001111000000111100001100001100110000110000111111000011111100000000110000000011000011110000001111000:$+00000000000000000110011000000000011001100000;$,000000000000000001100110000000000110011001100110<(,000000000000000000000110000001100001100000011000011000000110000000011000000110000000011000000110=(+0000000000000000000000000000000001111110011111100000000000000000011111100111111000000000>(,000000000000000001100000011000000001100000011000000001100000011000011000000110000110000001100000?*,000000000000000000000111111000011111100000000001100000000110000111100000011110000000000000000000000000011000000001100000@,,000000000000000000000000000111111000000111111000011000000110011000000110011001111110011001111110011001100110011001100110000111111000000111111000A*,000000000000000000000001111000000111100001100001100110000110011000011001100001100111111110011111111001100001100110000110B*,000000000000000000000111111000011111100001100001100110000110011111100001111110000110000110011000011001111110000111111000C(,000000000000000000011110000111100110000001100000011000000110000001100000011000000001111000011110D*,000000000000000000000111111000011111100001100001100110000110011000011001100001100110000110011000011001111110000111111000E(,000000000000000001111110011111100110000001100000011111100111111001100000011000000111111001111110F(,000000000000000001111110011111100110000001100000011111100111111001100000011000000110000001100000G*,000000000000000000000001111110000111111001100000000110000000011001111001100111100110000110011000011000011111100001111110H*,000000000000000000000110000110011000011001100001100110000110011111111001111111100110000110011000011001100001100110000110I(,000000000000000001111110011111100001100000011000000110000001100000011000000110000111111001111110J*,000000000000000000000000011110000001111000000001100000000110000000011000000001100110000110011000011000011110000001111000K*,000000000000000000000110000110011000011001100110000110011000011110000001111000000110011000011001100001100001100110000110L(,000000000000000001100000011000000110000001100000011000000110000001100000011000000111111001111110M,,000000000000000000000000011000000110011000000110011110011110011110011110011001100110011001100110011000000110011000000110011000000110011000000110N*,000000000000000000000110000110011000011001111001100111100110011001111001100111100110000110011000011001100001100110000110O*,000000000000000000000001111000000111100001100001100110000110011000011001100001100110000110011000011000011110000001111000P*,000000000000000000000111111000011111100001100001100110000110011000011001100001100111111000011111100001100000000110000000Q*.00000000000000000000000111100000011110000110000110011000011001100001100110000110011000011001100001100001111000000111100000000001100000000110R*,000000000000000000000111111000011111100001100001100110000110011000011001100001100111111000011111100001100001100110000110S*,000000000000000000000001111110000111111001100000000110000000000111100000011110000000000110000000011001111110000111111000T(,000000000000000001111110011111100001100000011000000110000001100000011000000110000001100000011000U*,000000000000000000000110000110011000011001100001100110000110011000011001100001100110000110011000011000011110000001111000V*,000000000000000000000110000110011000011001100001100110000110011001100001100110000110011000011001100000011000000001100000W,,000000000000000000000000011000000110011000000110011001100110011001100110011001100110011001100110011001100110011001100110000110011000000110011000X*,000000000000000000000110000110011000011001100001100110000110000111100000011110000110000110011000011001100001100110000110Y*,000000000000000000000110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000Z(,000000000000000001111110011111100000011000000110000110000001100001100000011000000111111001111110[&,000000000000011110011110011000011000011000011000011000011000011110011110\\,,000000000000000000000000011000000000011000000000000110000000000110000000000001100000000001100000000000011000000000011000000000000110000000000110]&,000000000000011110011110000110000110000110000110000110000110011110011110^('00000000000000000001100000011000011001100110011000000000_*,000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100111111110`&'000000000000011000011000000110000110000000a*,000000000000000000000000000000000000000000011111100001111110011000011001100001100110000110011000011000011111100001111110b*,000000000000000000000110000000011000000001111110000111111000011000011001100001100110000110011000011001111110000111111000c(,000000000000000000000000000000000001111000011110011000000110000001100000011000000001111000011110d*,000000000000000000000000000110000000011000011111100001111110011000011001100001100110000110011000011000011111100001111110e*,000000000000000000000000000000000000000000011110000001111000011001111001100111100111100000011110000000011110000001111000f(,000000000000000000000110000001100001100000011000011111100111111000011000000110000001100000011000g*00000000000000000000000000000000000000000000111111000011111100110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000h*,000000000000000000000110000000011000000001111110000111111000011000011001100001100110000110011000011001100001100110000110i$,000000000110011000000000011001100110011001100110j&0000000000000000110000110000000000000000110000110000110000110000110000110000110000110011000011000k*,000000000000000000000110000000011000000001100001100110000110011001100001100110000111111000011111100001100001100110000110l$,000000000110011001100110011001100110011001100110m,,000000000000000000000000000000000000000000000000011111111000011111111000011001100110011001100110011001100110011001100110011001100110011001100110n*,000000000000000000000000000000000000000001111110000111111000011000011001100001100110000110011000011001100001100110000110o*,000000000000000000000000000000000000000000011110000001111000011000011001100001100110000110011000011000011110000001111000p*00000000000000000000000000000000000000000011111100001111110000110000110011000011001100001100110000110011111100001111110000110000000011000000001100000000110000000q*00000000000000000000000000000000000000000000111111000011111100110000110011000011001100001100110000110000111111000011111100000000110000000011000000001100000000110r(,000000000000000000000000000000000110011001100110011110000111100001100000011000000110000001100000s*,000000000000000000000000000000000000000000011111100001111110011110000001111000000000011110000001111001111110000111111000t(,000000000000000000011000000110000111111001111110000110000001100000011000000110000000011000000110u*,000000000000000000000000000000000000000001100001100110000110011000011001100001100110000110011000011000011111100001111110v*,000000000000000000000000000000000000000001100001100110000110011000011001100001100110011000011001100000011000000001100000w,,000000000000000000000000000000000000000000000000011001100110011001100110011001100110011001100110000110011000000110011000000110011000000110011000x(,000000000000000000000000000000000110011001100110000110000001100000011000000110000110011001100110y*00000000000000000000000000000000000000000011000011001100001100110000110011000011001100001100110000110000111111000011111100000000110000000011000011110000001111000z*,000000000000000000000000000000000000000001111111100111111110000001100000000110000001100000000110000001111111100111111110{(,000000000000000000011110000111100001100000011000011000000110000000011000000110000001111000011110|$,000000000110011001100110011001100110011001100110}(,000000000000000001111000011110000001100000011000000001100000011000011000000110000111100001111000~*'0000000000000000000000011001100001100110011001100001100110000000000000 (!00000000";
	
	
	// BitmapFont information
	private var _glyphs:Array<BitmapData>;

	private var _glyphString:String;
	private var _maxHeight:Int = 0;
	private var _maxWidth:Int = 0;
	
	private var _colorTransform:ColorTransform;
	
	
	// BitmapFonts cache
	private static var _storedFonts:Map<String, BitmapFont>;
	
}