package net.hxpunk.graphics;
import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Utf8;
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
		
		_colorTransform = new ColorTransform();
		_glyphs = new Array<BitmapData>();
	}
	
	/**
	 * Loads font data from Pixelizer's format.
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	letters		All letters (in sequential order) contained in this font.
	 * @return this BitmapFont
	 */
	public function loadFromPixelizer(source:Dynamic, letters:String):BitmapFont
	{
		reset();
		
		var bitmapData:BitmapData = HP.getBitmapData(source);
		if (bitmapData == null) throw new Error("Font source must be of type BitmapData, String or Class.");

		_glyphString = letters;
		
		var tileRects:Array<Rectangle> = [];
		var result:BitmapData = preparePixelizerBMD(bitmapData, tileRects);
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
		
		return this;
	}
	
	/**
	 * Loads font data from XML (AngelCode's) format.
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	XMLData		Font data in XML format.
	 * @return	this BitmapFont.
	 */
	public function loadFromXML(source:Dynamic, XMLData:Xml):BitmapFont
	{
		reset();
		
		var bitmapData:BitmapData = HP.getBitmapData(source);
		if (bitmapData == null) throw new Error("Font source must be of type BitmapData, String or Class.");

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
		
		return this;
	}
	
	/**
	 * Deserializes a font encoded with serialize().
	 * 
	 * @return	The deserialized BitmapFont.
	 */
	public static function loadFromSerialized(encodedFont:String):BitmapFont 
	{
		var haxeDeserialized:String = Unserializer.run(encodedFont);
		var rleDecoded:String = rleDecodeStr(haxeDeserialized);
		var letters:String = "";
		var letterPos:Int = 0;
		var i:Int = 0;
		
		var n:Int = rleDecoded.charCodeAt(i) - 32;		// number of glyphs
		var w:Int = rleDecoded.charCodeAt(++i) - 32;	// max width of single glyph
		var h:Int = rleDecoded.charCodeAt(++i) - 32;	// max height of single glyph
		
		var size:Int = Std.int(Math.ceil(Math.sqrt(n * (w + 1) * (h + 1))) + Math.max(w, h));
		var rows:Int = Std.int(size / (h + 1));
		var cols:Int = Std.int(size / (w + 1));
		var bd:BitmapData = new BitmapData(size, size, true, 0xFFFF0000);
		var len:Int = rleDecoded.length;
		
		while (i < len)
		{
			letters += rleDecoded.charAt(++i);
			
			if (i >= len) break;
			
			var gw:Int = rleDecoded.charCodeAt(++i) - 32;
			var gh:Int = rleDecoded.charCodeAt(++i) - 32;
			for (py in 0...gh) 
			{
				for (px in 0...gw) 
				{
					i++;
					
					var pixelOn:Bool = rleDecoded.charAt(i) == "1"; 
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
	 * Serializes the font as a bit font by encoding it into a big string (only extended-ASCII glyphs between in the range [32..254] are valid, no alpha is encoded, pixels are either on (if alpha == 1) or off (otherwise)).
	 * 
	 * Format:
	 * 	   [fromCharCode(numGlyphs + 32)][fromCharCode(maxWidth + 32)][fromCharCode(height + 32)] then for each glyph [char][fromCharCode(width + 32)][fromCharCode(height + 32)][series of 0 or 1 for each pixel of the glyph]...
	 * 
	 *     the resulting string is then passed to rleEncodeStr() for compressing and to haxe.Serializer() for cross-platform compatibility, and returned.
	 * 
	 * @return	Serialized font string.
	 */
	public function serialize():String 
	{
		var charCode:Int;
		var glyph:BitmapData;
		var nGlyphs:Int = _glyphString.length;
		var outputBuf:StringBuf = new StringBuf();
		
		outputBuf.addChar(nGlyphs + 32);
		outputBuf.addChar(maxWidth + 32);
		outputBuf.addChar(height + 32);

		for (i in 0...nGlyphs) 
		{
			charCode = _glyphString.charCodeAt(i);
			glyph = _glyphs[charCode];
			
			outputBuf.add(_glyphString.substr(i, 1));
			outputBuf.addChar(glyph.width + 32);
			outputBuf.addChar(glyph.height + 32);
			
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					outputBuf.add(((glyph.getPixel32(px, py) & 0xFF000000) == 0xFF000000) ? "1" : "0");
				}
			}
		}
		
		var rleEncoded:String = rleEncodeStr(outputBuf.toString());
		var haxeSerialized:String = Serializer.run(rleEncoded);
		return haxeSerialized;
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
	private function preparePixelizerBMD(bitmapData:BitmapData, rects:Array<Rectangle>):BitmapData
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

	/** Encodes an extended-ASCII string using a run-length algorithm. 
	 * 
	 *  Format:
	 *      if more than 2 characters are repeated in sequence this gets appended to output 
	 *
	 * 			[RLE_MARKER][number of repetitions + 32][char to repeat]
	 * 
	 * 		otherwise the character itself is appended (so the encoded string is never longer than the original one).
	 * 
	 *  @param str	The string to encode (must have characters with values in the range [32..254] - 255 is used as marker)
	 *  @return The encoded string.
	 */
	public static function rleEncodeStr(str:String):String 
	{
		var RLE_MARKER:Int = 255;
		var FIRST_VALID_CHAR:Int = 32;
		var outputBuf:StringBuf = new StringBuf();
		var runlength:Int = 0;
		var currChar:Int = -1;
		var lastChar:Int = -1;
		
		for (i in 0...str.length) {
			currChar = str.charCodeAt(i);
			
		#if debug
			if (currChar < FIRST_VALID_CHAR || currChar >= RLE_MARKER) {
				trace("Encountered char outside valid range in string to encode [pos:" + i + " value:" + currChar + " char:'" + str.charAt(i) + "'].");
				throw new Error("Encountered char outside valid range in string to encode [pos:" + i + " value:" + currChar + " char:'" + str.charAt(i) + "'].");
			}
		#end
		
			if (lastChar == currChar || lastChar < 0) {
				runlength++;
			} else if (lastChar != currChar || runlength == RLE_MARKER - FIRST_VALID_CHAR - 1) {
				if (runlength > 1) {
					if (runlength == 2) {
						outputBuf.addChar(lastChar);
					} else {
						outputBuf.addChar(RLE_MARKER);
						outputBuf.addChar(runlength + FIRST_VALID_CHAR);
					}
				}
				outputBuf.addChar(lastChar);
				runlength = 1;
			}
			lastChar = currChar;
		}
		
		if (runlength > 0) {
			if (runlength > 1) {
				if (runlength == 2) {
					outputBuf.addChar(lastChar);
				} else {
					outputBuf.addChar(RLE_MARKER);
					outputBuf.addChar(runlength + FIRST_VALID_CHAR);
				}
			}
			outputBuf.addChar(lastChar);
		}
		
		return outputBuf.toString();
	}
	
	/** Decodes a string encoded with rleEncodeStr(). */
	public static function rleDecodeStr(str:String):String 
	{
		var RLE_MARKER:Int = 255;
		var FIRST_VALID_CHAR:Int = 32;
		var outputBuf:StringBuf = new StringBuf();
		var runlength:Int = 0;
		var encodedChar:Int;
		var currChar:Int;
		var i:Int = 0;
		var len:Int = str.length;
		
		while (i < len) {
			encodedChar = str.charCodeAt(i);
			if (encodedChar == RLE_MARKER) { 
				runlength = str.charCodeAt(++i) - FIRST_VALID_CHAR;
				currChar = str.charCodeAt(++i);
				for (r in 0...runlength) outputBuf.addChar(currChar);
			} else {
				outputBuf.addChar(encodedChar);
			}
			i++;
		}
		
		return outputBuf.toString();
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
		return _glyphString.length;
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
		var defaultFont:BitmapFont = loadFromSerialized(_DEFAULT_FONT_DATA);
		BitmapFont.store("default", defaultFont);
	}

	/** Serialized default font data. (04B_03__.ttf @ 8px) */
#if web
	private static inline var _DEFAULT_FONT_DATA:String = "y4763:%7F%26(%20%24!%C3%BF%240!%22%260010101%C3%BF%23010%22%24%24%C3%BF%2401010101%C3%BF%250%23%26%26%C3%BF'010100%C3%BF%2510010100%C3%BF%2510010100%24%25'%C3%BF'01%C3%BF%230%C3%BF%231011%C3%BF%250110%C3%BF%231%C3%BF%240100%25%26%26%C3%BF%2601001%C3%BF%2501%C3%BF%2401%C3%BF%2401%C3%BF%25010010%C3%BF%23%26%C3%BF'011%C3%BF%2301%C3%BF%260110101001%C3%BF%23011010'%22%2400101%C3%BF%230(%23%26%C3%BF%240101001001%C3%BF%23010)%23%26%C3%BF%2301%C3%BF%23010010010100*%24%25%C3%BF%24010100100101%C3%BF%250%2B%24%26%C3%BF)0100%C3%BF%231001%C3%BF%260%2C%23'%C3%BF0010100-%24%25%C3%BF%2C0%C3%BF%231%C3%BF%250.%22%26%C3%BF*010%2F%26%26%C3%BF*01%C3%BF%2401%C3%BF%2401%C3%BF%2401%C3%BF%2401%C3%BF%260%25%26%C3%BF%2601100100101001010010011001%23%26%C3%BF%2301100100100100102%25%26%C3%BF%250%C3%BF%231%C3%BF%25010011001%C3%BF%240%C3%BF%24103%25%26%C3%BF%250%C3%BF%231%C3%BF%25010011%C3%BF%25010%C3%BF%231004%25%26%C3%BF'01%C3%BF%230110010100%C3%BF%241%C3%BF%2301005%25%26%C3%BF%250%C3%BF%24101%C3%BF%240%C3%BF%231%C3%BF%25010%C3%BF%231006%25%26%C3%BF%26011001%C3%BF%240%C3%BF%2310010010011007%25%26%C3%BF%250%C3%BF%241%C3%BF%2401%C3%BF%2301%C3%BF%2301%C3%BF%2401%C3%BF%2308%25%26%C3%BF%2601100100100110010010011009%25%26%C3%BF%2601100100100%C3%BF%231%C3%BF%2401001100%3A%22%26%C3%BF%2401%C3%BF%2301%C3%BF%230%3B%22%26%C3%BF%2401%C3%BF%2301010%3C%24%26%C3%BF%2601001001%C3%BF%2401%C3%BF%24010%3D%24%26%C3%BF(0%C3%BF%231%C3%BF%250%C3%BF%231%C3%BF%250%3E%24%26%C3%BF%2401%C3%BF%2401%C3%BF%2401001001%C3%BF%230%3F%25%26%C3%BF%250%C3%BF%231%C3%BF%25010011%C3%BF(01%C3%BF%230%40%26%26%C3%BF'0%C3%BF%231001%C3%BF%2301010%C3%BF%23101010100%C3%BF%23100A%25%26%C3%BF%26011001001010010%C3%BF%241010010B%25%26%C3%BF%250%C3%BF%2310010010%C3%BF%2310010010%C3%BF%23100C%24%26%C3%BF%2501101%C3%BF%2301%C3%BF%2301%C3%BF%240110D%25%26%C3%BF%250%C3%BF%23100100101001010010%C3%BF%23100E%24%26%C3%BF%240%C3%BF%23101%C3%BF%230%C3%BF%23101%C3%BF%230%C3%BF%2310F%24%26%C3%BF%240%C3%BF%23101%C3%BF%230%C3%BF%23101%C3%BF%2301%C3%BF%230G%25%26%C3%BF%260%C3%BF%23101%C3%BF%24010110100100%C3%BF%2310H%25%26%C3%BF%2501001010010%C3%BF%24101001010010I%24%26%C3%BF%240%C3%BF%231001%C3%BF%2301%C3%BF%230100%C3%BF%2310J%25%26%C3%BF'011%C3%BF%2401%C3%BF%240101001001100K%25%26%C3%BF%250100101010011%C3%BF%2301010010010L%24%26%C3%BF%2401%C3%BF%2301%C3%BF%2301%C3%BF%2301%C3%BF%230%C3%BF%2310M%26%26%C3%BF%2601%C3%BF%230101101101010101%C3%BF%230101%C3%BF%23010N%25%26%C3%BF%2501001011010101101001010010O%25%26%C3%BF%260110010010100101001001100P%25%26%C3%BF%250%C3%BF%231001001010010%C3%BF%231001%C3%BF%240Q%25'%C3%BF%2601100100101001010010011%C3%BF%25010R%25%26%C3%BF%250%C3%BF%231001001010010%C3%BF%2310010010S%25%26%C3%BF%260%C3%BF%23101%C3%BF%25011%C3%BF%25010%C3%BF%23100T%24%26%C3%BF%240%C3%BF%231001%C3%BF%2301%C3%BF%2301%C3%BF%230100U%25%26%C3%BF%2501001010010100101001001100V%25%26%C3%BF%250100101001010100101%C3%BF%2301%C3%BF%230W%26%26%C3%BF%2601%C3%BF%23010101010101010101010010100X%25%26%C3%BF%2501001010010011001001010010Y%25%26%C3%BF%25010010100100%C3%BF%231%C3%BF%2401001100Z%24%26%C3%BF%240%C3%BF%231%C3%BF%2301001001%C3%BF%230%C3%BF%2310%5B%23%26%C3%BF%230110100100100110%5C%26%26%C3%BF%2601%C3%BF%2601%C3%BF%2601%C3%BF%2601%C3%BF%26010%5D%23%26%C3%BF%230110010010010110%5E%24%24%C3%BF%250100101%C3%BF%250_%25%26%C3%BF90%C3%BF%2410%60%23%24%C3%BF%2301%C3%BF%2301%C3%BF%240a%25%26%C3%BF%2B0%C3%BF%231010010100100%C3%BF%2310b%25%26%C3%BF%2501%C3%BF%240%C3%BF%231001001010010%C3%BF%23100c%24%26%C3%BF)01101%C3%BF%2301%C3%BF%240110d%25%26%C3%BF(0100%C3%BF%231010010100100%C3%BF%2310e%25%26%C3%BF%2B011001011011%C3%BF%2401100f%24%26%C3%BF%260100100%C3%BF%231001%C3%BF%230100g%25(%C3%BF%2B0%C3%BF%231010010100100%C3%BF%231%C3%BF%2401001100h%25%26%C3%BF%2501%C3%BF%240%C3%BF%23100100101001010010i%22%26001%C3%BF%230101010j%23(%C3%BF%2401%C3%BF%25010010010010100k%25%26%C3%BF%2501%C3%BF%2401001010100%C3%BF%2310010010l%22%26001010101010m%26%26%C3%BF%2C0%C3%BF%24100101010101010101010n%25%26%C3%BF*0%C3%BF%23100100101001010010o%25%26%C3%BF%2B01100100101001001100p%25(%C3%BF*0%C3%BF%231001001010010%C3%BF%231001%C3%BF%2401%C3%BF%240q%25(%C3%BF%2B0%C3%BF%231010010100100%C3%BF%231%C3%BF%2401%C3%BF%24010r%24%26%C3%BF(0101011001%C3%BF%2301%C3%BF%230s%25%26%C3%BF%2B0%C3%BF%231011%C3%BF%250110%C3%BF%23100t%24%26%C3%BF%250100%C3%BF%231001%C3%BF%2301%C3%BF%24010u%25%26%C3%BF*01001010010100100%C3%BF%2310v%25%26%C3%BF*01001010010101%C3%BF%2301%C3%BF%230w%26%26%C3%BF%2C01010101010100101%C3%BF%23010100x%24%26%C3%BF(0101001%C3%BF%2301001010y%25(%C3%BF*01001010010100100%C3%BF%231%C3%BF%2401001100z%25%26%C3%BF*0%C3%BF%241%C3%BF%2301%C3%BF%2301%C3%BF%230%C3%BF%2410%7B%24%26%C3%BF%25011001001%C3%BF%2401%C3%BF%230110%7C%22%26001010101010%7D%24%26%C3%BF%24011%C3%BF%2301%C3%BF%2401001001100~%25%24%C3%BF%2601010101%C3%BF'0";
#else
	private static inline var _DEFAULT_FONT_DATA:String = "y3966:%7F%26%28%20%24%21%FF%240%21%22%260010101%FF%23010%22%24%24%FF%2401010101%FF%250%23%26%26%FF%27010100%FF%2510010100%FF%2510010100%24%25%27%FF%2701%FF%230%FF%231011%FF%250110%FF%231%FF%240100%25%26%26%FF%2601001%FF%2501%FF%2401%FF%2401%FF%25010010%FF%23%26%FF%27011%FF%2301%FF%260110101001%FF%23011010%27%22%2400101%FF%230%28%23%26%FF%240101001001%FF%23010%29%23%26%FF%2301%FF%23010010010100%2A%24%25%FF%24010100100101%FF%250%2B%24%26%FF%290100%FF%231001%FF%260%2C%23%27%FF0010100-%24%25%FF%2C0%FF%231%FF%250.%22%26%FF%2A010%2F%26%26%FF%2A01%FF%2401%FF%2401%FF%2401%FF%2401%FF%260%25%26%FF%2601100100101001010010011001%23%26%FF%2301100100100100102%25%26%FF%250%FF%231%FF%25010011001%FF%240%FF%24103%25%26%FF%250%FF%231%FF%25010011%FF%25010%FF%231004%25%26%FF%2701%FF%230110010100%FF%241%FF%2301005%25%26%FF%250%FF%24101%FF%240%FF%231%FF%25010%FF%231006%25%26%FF%26011001%FF%240%FF%2310010010011007%25%26%FF%250%FF%241%FF%2401%FF%2301%FF%2301%FF%2401%FF%2308%25%26%FF%2601100100100110010010011009%25%26%FF%2601100100100%FF%231%FF%2401001100%3A%22%26%FF%2401%FF%2301%FF%230%3B%22%26%FF%2401%FF%2301010%3C%24%26%FF%2601001001%FF%2401%FF%24010%3D%24%26%FF%280%FF%231%FF%250%FF%231%FF%250%3E%24%26%FF%2401%FF%2401%FF%2401001001%FF%230%3F%25%26%FF%250%FF%231%FF%25010011%FF%2801%FF%230%40%26%26%FF%270%FF%231001%FF%2301010%FF%23101010100%FF%23100A%25%26%FF%26011001001010010%FF%241010010B%25%26%FF%250%FF%2310010010%FF%2310010010%FF%23100C%24%26%FF%2501101%FF%2301%FF%2301%FF%240110D%25%26%FF%250%FF%23100100101001010010%FF%23100E%24%26%FF%240%FF%23101%FF%230%FF%23101%FF%230%FF%2310F%24%26%FF%240%FF%23101%FF%230%FF%23101%FF%2301%FF%230G%25%26%FF%260%FF%23101%FF%24010110100100%FF%2310H%25%26%FF%2501001010010%FF%24101001010010I%24%26%FF%240%FF%231001%FF%2301%FF%230100%FF%2310J%25%26%FF%27011%FF%2401%FF%240101001001100K%25%26%FF%250100101010011%FF%2301010010010L%24%26%FF%2401%FF%2301%FF%2301%FF%2301%FF%230%FF%2310M%26%26%FF%2601%FF%230101101101010101%FF%230101%FF%23010N%25%26%FF%2501001011010101101001010010O%25%26%FF%260110010010100101001001100P%25%26%FF%250%FF%231001001010010%FF%231001%FF%240Q%25%27%FF%2601100100101001010010011%FF%25010R%25%26%FF%250%FF%231001001010010%FF%2310010010S%25%26%FF%260%FF%23101%FF%25011%FF%25010%FF%23100T%24%26%FF%240%FF%231001%FF%2301%FF%2301%FF%230100U%25%26%FF%2501001010010100101001001100V%25%26%FF%250100101001010100101%FF%2301%FF%230W%26%26%FF%2601%FF%23010101010101010101010010100X%25%26%FF%2501001010010011001001010010Y%25%26%FF%25010010100100%FF%231%FF%2401001100Z%24%26%FF%240%FF%231%FF%2301001001%FF%230%FF%2310%5B%23%26%FF%230110100100100110%5C%26%26%FF%2601%FF%2601%FF%2601%FF%2601%FF%26010%5D%23%26%FF%230110010010010110%5E%24%24%FF%250100101%FF%250_%25%26%FF90%FF%2410%60%23%24%FF%2301%FF%2301%FF%240a%25%26%FF%2B0%FF%231010010100100%FF%2310b%25%26%FF%2501%FF%240%FF%231001001010010%FF%23100c%24%26%FF%2901101%FF%2301%FF%240110d%25%26%FF%280100%FF%231010010100100%FF%2310e%25%26%FF%2B011001011011%FF%2401100f%24%26%FF%260100100%FF%231001%FF%230100g%25%28%FF%2B0%FF%231010010100100%FF%231%FF%2401001100h%25%26%FF%2501%FF%240%FF%23100100101001010010i%22%26001%FF%230101010j%23%28%FF%2401%FF%25010010010010100k%25%26%FF%2501%FF%2401001010100%FF%2310010010l%22%26001010101010m%26%26%FF%2C0%FF%24100101010101010101010n%25%26%FF%2A0%FF%23100100101001010010o%25%26%FF%2B01100100101001001100p%25%28%FF%2A0%FF%231001001010010%FF%231001%FF%2401%FF%240q%25%28%FF%2B0%FF%231010010100100%FF%231%FF%2401%FF%24010r%24%26%FF%280101011001%FF%2301%FF%230s%25%26%FF%2B0%FF%231011%FF%250110%FF%23100t%24%26%FF%250100%FF%231001%FF%2301%FF%24010u%25%26%FF%2A01001010010100100%FF%2310v%25%26%FF%2A01001010010101%FF%2301%FF%230w%26%26%FF%2C01010101010100101%FF%23010100x%24%26%FF%280101001%FF%2301001010y%25%28%FF%2A01001010010100100%FF%231%FF%2401001100z%25%26%FF%2A0%FF%241%FF%2301%FF%2301%FF%230%FF%2410%7B%24%26%FF%25011001001%FF%2401%FF%230110%7C%22%26001010101010%7D%24%26%FF%24011%FF%2301%FF%2401001001100%7E%25%24%FF%2601010101%FF%270";
#end

	// BitmapFont information
	private var _glyphs:Array<BitmapData>;

	private var _glyphString:String;
	private var _maxHeight:Int = 0;
	private var _maxWidth:Int = 0;
	
	private var _colorTransform:ColorTransform;
	
	
	// BitmapFonts cache
	private static var _storedFonts:Map<String, BitmapFont>;
	
}