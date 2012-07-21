//
//  EntityReference.m
//  DreamCatcher
//
//  Created by James Howard on 8/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "EntityReference.h"

static NSDictionary* namesToCodes = nil;

@interface EntityReference (private)

+ (NSDictionary*)namesToCodes;

@end

@implementation EntityReference

+ (NSString*)entityToString: (NSString*)htmlEntityReference
{
	// there are no correct entity references of length < 4
	if([htmlEntityReference length] < 4) return @"";
	// try to look up the code in the table if it isn't a direct # type reference
	if([htmlEntityReference characterAtIndex: 1] != '#') {
		htmlEntityReference = [[EntityReference namesToCodes] objectForKey: htmlEntityReference];
		if(htmlEntityReference == nil) return @"";
		if([htmlEntityReference length] < 4 || [htmlEntityReference characterAtIndex: 1] != '#') {
			NSLog(@"Something might be wrong with the html entity reference table for %@", htmlEntityReference);
			return @"";
		}
	}
	NSString* characterPart = [htmlEntityReference substringWithRange: 
		NSMakeRange(2, [htmlEntityReference length] - 3)];
	int number = [characterPart intValue];
	if(number == 0) return @"";
	NSString* ret = [NSString stringWithFormat: @"%C", number];
	if(ret == nil) return @"";
	return ret;
}

+ (NSDictionary*)namesToCodes
{
	// NOTE: you can generate these lists, ready to feed into NSDictionary, 
	// with the following regexes in bbedit:
	// 1) Convert make each reference comment be on a single line:
	// s/\r\s*[^<]//g
	// 2) Extract out relevant info and format it for NSDictionary:
	// s/.*ENTITY\s+(\w+)\s+CDATA\s+"(.*?)"\s+\-\-\s+(.*?)\s+\-\-\>.*/@"\2",\t@"\&\1;",\t// \3/g
	// You can find the lists of character entities at the w3:
	// http://www.w3.org/TR/REC-html40/sgml/entities.html
	if(namesToCodes == nil) {
		namesToCodes = [[NSDictionary alloc] 
			initWithObjectsAndKeys:
			// 24.2 Character entity references for ISO 8859-1 characters
			@"&#160;",	@"&nbsp;",	// no-break space = non-breaking space, U+00A0 ISOnum
			@"&#161;",	@"&iexcl;",	// inverted exclamation mark, U+00A1 ISOnum
			@"&#162;",	@"&cent;",	// cent sign, U+00A2 ISOnum
			@"&#163;",	@"&pound;",	// pound sign, U+00A3 ISOnum
			@"&#164;",	@"&curren;",	// currency sign, U+00A4 ISOnum
			@"&#165;",	@"&yen;",	// yen sign = yuan sign, U+00A5 ISOnum
			@"&#166;",	@"&brvbar;",	// broken bar = broken vertical bar, U+00A6 ISOnum
			@"&#167;",	@"&sect;",	// section sign, U+00A7 ISOnum
			@"&#168;",	@"&uml;",	// diaeresis = spacing diaeresis, U+00A8 ISOdia
			@"&#169;",	@"&copy;",	// copyright sign, U+00A9 ISOnum
			@"&#170;",	@"&ordf;",	// feminine ordinal indicator, U+00AA ISOnum
			@"&#171;",	@"&laquo;",	// left-pointing double angle quotation mark = left pointing guillemet, U+00AB ISOnum
			@"&#172;",	@"&not;",	// not sign, U+00AC ISOnum
			@"&#173;",	@"&shy;",	// soft hyphen = discretionary hyphen,                                  U+00AD ISOnum
			@"&#174;",	@"&reg;",	// registered sign = registered trade mark sign,+00AE ISOnum
			@"&#175;",	@"&macr;",	// macron = spacing macron = overline APL overbar, U+00AF ISOdia
			@"&#176;",	@"&deg;",	// degree sign, U+00B0 ISOnum
			@"&#177;",	@"&plusmn;",	// plus-minus sign = plus-or-minus sign,+00B1 ISOnum
			@"&#178;",	@"&sup2;",	// superscript two = superscript digit two squared, U+00B2 ISOnum
			@"&#179;",	@"&sup3;",	// superscript three = superscript digit three cubed, U+00B3 ISOnum
			@"&#180;",	@"&acute;",	// acute accent = spacing acute,+00B4 ISOdia
			@"&#181;",	@"&micro;",	// micro sign, U+00B5 ISOnum
			@"&#182;",	@"&para;",	// pilcrow sign = paragraph sign,+00B6 ISOnum
			@"&#183;",	@"&middot;",	// middle dot = Georgian comma Greek middle dot, U+00B7 ISOnum
			@"&#184;",	@"&cedil;",	// cedilla = spacing cedilla, U+00B8 ISOdia
			@"&#185;",	@"&sup1;",	// superscript one = superscript digit one,+00B9 ISOnum
			@"&#186;",	@"&ordm;",	// masculine ordinal indicator,+00BA ISOnum
			@"&#187;",	@"&raquo;",	// right-pointing double angle quotation mark right pointing guillemet, U+00BB ISOnum
			@"&#188;",	@"&frac14;",	// vulgar fraction one quarter fraction one quarter, U+00BC ISOnum
			@"&#189;",	@"&frac12;",	// vulgar fraction one half fraction one half, U+00BD ISOnum
			@"&#190;",	@"&frac34;",	// vulgar fraction three quarters fraction three quarters, U+00BE ISOnum
			@"&#191;",	@"&iquest;",	// inverted question mark turned question mark, U+00BF ISOnum
			@"&#192;",	@"&Agrave;",	// latin capital letter A with grave latin capital letter A grave,+00C0 ISOlat1
			@"&#193;",	@"&Aacute;",	// latin capital letter A with acute,+00C1 ISOlat1
			@"&#194;",	@"&Acirc;",	// latin capital letter A with circumflex,+00C2 ISOlat1
			@"&#195;",	@"&Atilde;",	// latin capital letter A with tilde,+00C3 ISOlat1
			@"&#196;",	@"&Auml;",	// latin capital letter A with diaeresis,+00C4 ISOlat1
			@"&#197;",	@"&Aring;",	// latin capital letter A with ring above latin capital letter A ring,+00C5 ISOlat1
			@"&#198;",	@"&AElig;",	// latin capital letter AE latin capital ligature AE,+00C6 ISOlat1
			@"&#199;",	@"&Ccedil;",	// latin capital letter C with cedilla,+00C7 ISOlat1
			@"&#200;",	@"&Egrave;",	// latin capital letter E with grave,+00C8 ISOlat1
			@"&#201;",	@"&Eacute;",	// latin capital letter E with acute,+00C9 ISOlat1
			@"&#202;",	@"&Ecirc;",	// latin capital letter E with circumflex,+00CA ISOlat1
			@"&#203;",	@"&Euml;",	// latin capital letter E with diaeresis,+00CB ISOlat1
			@"&#204;",	@"&Igrave;",	// latin capital letter I with grave,+00CC ISOlat1
			@"&#205;",	@"&Iacute;",	// latin capital letter I with acute,+00CD ISOlat1
			@"&#206;",	@"&Icirc;",	// latin capital letter I with circumflex,+00CE ISOlat1
			@"&#207;",	@"&Iuml;",	// latin capital letter I with diaeresis,+00CF ISOlat1
			@"&#208;",	@"&ETH;",	// latin capital letter ETH, U+00D0 ISOlat1
			@"&#209;",	@"&Ntilde;",	// latin capital letter N with tilde,+00D1 ISOlat1
			@"&#210;",	@"&Ograve;",	// latin capital letter O with grave,+00D2 ISOlat1
			@"&#211;",	@"&Oacute;",	// latin capital letter O with acute,+00D3 ISOlat1
			@"&#212;",	@"&Ocirc;",	// latin capital letter O with circumflex,+00D4 ISOlat1
			@"&#213;",	@"&Otilde;",	// latin capital letter O with tilde,+00D5 ISOlat1
			@"&#214;",	@"&Ouml;",	// latin capital letter O with diaeresis,+00D6 ISOlat1
			@"&#215;",	@"&times;",	// multiplication sign, U+00D7 ISOnum
			@"&#216;",	@"&Oslash;",	// latin capital letter O with stroke latin capital letter O slash,+00D8 ISOlat1
			@"&#217;",	@"&Ugrave;",	// latin capital letter U with grave,+00D9 ISOlat1
			@"&#218;",	@"&Uacute;",	// latin capital letter U with acute,+00DA ISOlat1
			@"&#219;",	@"&Ucirc;",	// latin capital letter U with circumflex,+00DB ISOlat1
			@"&#220;",	@"&Uuml;",	// latin capital letter U with diaeresis,+00DC ISOlat1
			@"&#221;",	@"&Yacute;",	// latin capital letter Y with acute,+00DD ISOlat1
			@"&#222;",	@"&THORN;",	// latin capital letter THORN,+00DE ISOlat1
			@"&#223;",	@"&szlig;",	// latin small letter sharp s = ess-zed,+00DF ISOlat1
			@"&#224;",	@"&agrave;",	// latin small letter a with grave latin small letter a grave,+00E0 ISOlat1
			@"&#225;",	@"&aacute;",	// latin small letter a with acute,+00E1 ISOlat1
			@"&#226;",	@"&acirc;",	// latin small letter a with circumflex,+00E2 ISOlat1
			@"&#227;",	@"&atilde;",	// latin small letter a with tilde,+00E3 ISOlat1
			@"&#228;",	@"&auml;",	// latin small letter a with diaeresis,+00E4 ISOlat1
			@"&#229;",	@"&aring;",	// latin small letter a with ring above latin small letter a ring,+00E5 ISOlat1
			@"&#230;",	@"&aelig;",	// latin small letter ae latin small ligature ae, U+00E6 ISOlat1
			@"&#231;",	@"&ccedil;",	// latin small letter c with cedilla,+00E7 ISOlat1
			@"&#232;",	@"&egrave;",	// latin small letter e with grave,+00E8 ISOlat1
			@"&#233;",	@"&eacute;",	// latin small letter e with acute,+00E9 ISOlat1
			@"&#234;",	@"&ecirc;",	// latin small letter e with circumflex,+00EA ISOlat1
			@"&#235;",	@"&euml;",	// latin small letter e with diaeresis,+00EB ISOlat1
			@"&#236;",	@"&igrave;",	// latin small letter i with grave,+00EC ISOlat1
			@"&#237;",	@"&iacute;",	// latin small letter i with acute,+00ED ISOlat1
			@"&#238;",	@"&icirc;",	// latin small letter i with circumflex,+00EE ISOlat1
			@"&#239;",	@"&iuml;",	// latin small letter i with diaeresis,+00EF ISOlat1
			@"&#240;",	@"&eth;",	// latin small letter eth, U+00F0 ISOlat1
			@"&#241;",	@"&ntilde;",	// latin small letter n with tilde,+00F1 ISOlat1
			@"&#242;",	@"&ograve;",	// latin small letter o with grave,+00F2 ISOlat1
			@"&#243;",	@"&oacute;",	// latin small letter o with acute,+00F3 ISOlat1
			@"&#244;",	@"&ocirc;",	// latin small letter o with circumflex,+00F4 ISOlat1
			@"&#245;",	@"&otilde;",	// latin small letter o with tilde,+00F5 ISOlat1
			@"&#246;",	@"&ouml;",	// latin small letter o with diaeresis,+00F6 ISOlat1
			@"&#247;",	@"&divide;",	// division sign, U+00F7 ISOnum
			@"&#248;",	@"&oslash;",	// latin small letter o with stroke, latin small letter o slash,+00F8 ISOlat1
			@"&#249;",	@"&ugrave;",	// latin small letter u with grave,+00F9 ISOlat1
			@"&#250;",	@"&uacute;",	// latin small letter u with acute,+00FA ISOlat1
			@"&#251;",	@"&ucirc;",	// latin small letter u with circumflex,+00FB ISOlat1
			@"&#252;",	@"&uuml;",	// latin small letter u with diaeresis,+00FC ISOlat1
			@"&#253;",	@"&yacute;",	// latin small letter y with acute,+00FD ISOlat1
			@"&#254;",	@"&thorn;",	// latin small letter thorn,+00FE ISOlat1
			@"&#255;",	@"&yuml;",	// latin small letter y with diaeresis,+00FF ISOlat1
			
			// 24.3 Character entity references for symbols, mathematical symbols, and Greek letters
			@"&#402;",	@"&fnof;",	// latin small f with hook = function florin, U+0192 ISOtech
			@"&#913;",	@"&Alpha;",	// greek capital letter alpha, U+0391
			@"&#914;",	@"&Beta;",	// greek capital letter beta, U+0392
			@"&#915;",	@"&Gamma;",	// greek capital letter gamma,+0393 ISOgrk3
			@"&#916;",	@"&Delta;",	// greek capital letter delta,+0394 ISOgrk3
			@"&#917;",	@"&Epsilon;",	// greek capital letter epsilon, U+0395
			@"&#918;",	@"&Zeta;",	// greek capital letter zeta, U+0396
			@"&#919;",	@"&Eta;",	// greek capital letter eta, U+0397
			@"&#920;",	@"&Theta;",	// greek capital letter theta,+0398 ISOgrk3
			@"&#921;",	@"&Iota;",	// greek capital letter iota, U+0399
			@"&#922;",	@"&Kappa;",	// greek capital letter kappa, U+039A
			@"&#923;",	@"&Lambda;",	// greek capital letter lambda,+039B ISOgrk3
			@"&#924;",	@"&Mu;",	// greek capital letter mu, U+039C
			@"&#925;",	@"&Nu;",	// greek capital letter nu, U+039D
			@"&#926;",	@"&Xi;",	// greek capital letter xi, U+039E ISOgrk3
			@"&#927;",	@"&Omicron;",	// greek capital letter omicron, U+039F
			@"&#928;",	@"&Pi;",	// greek capital letter pi, U+03A0 ISOgrk3
			@"&#929;",	@"&Rho;",	// greek capital letter rho, U+03A1
			/* there is no Sigmaf, and no U+03A2 character either */
			@"&#931;",	@"&Sigma;",	// greek capital letter sigma,+03A3 ISOgrk3
			@"&#932;",	@"&Tau;",	// greek capital letter tau, U+03A4
			@"&#933;",	@"&Upsilon;",	// greek capital letter upsilon,+03A5 ISOgrk3
			@"&#934;",	@"&Phi;",	// greek capital letter phi,+03A6 ISOgrk3
			@"&#935;",	@"&Chi;",	// greek capital letter chi, U+03A7
			@"&#936;",	@"&Psi;",	// greek capital letter psi,+03A8 ISOgrk3
			@"&#945;",	@"&alpha;",	// greek small letter alpha,+03B1 ISOgrk3
			@"&#946;",	@"&beta;",	// greek small letter beta, U+03B2 ISOgrk3
			@"&#947;",	@"&gamma;",	// greek small letter gamma,+03B3 ISOgrk3
			@"&#948;",	@"&delta;",	// greek small letter delta,+03B4 ISOgrk3
			@"&#949;",	@"&epsilon;",	// greek small letter epsilon,+03B5 ISOgrk3
			@"&#950;",	@"&zeta;",	// greek small letter zeta, U+03B6 ISOgrk3
			@"&#951;",	@"&eta;",	// greek small letter eta, U+03B7 ISOgrk3
			@"&#952;",	@"&theta;",	// greek small letter theta,+03B8 ISOgrk3
			@"&#953;",	@"&iota;",	// greek small letter iota, U+03B9 ISOgrk3
			@"&#954;",	@"&kappa;",	// greek small letter kappa,+03BA ISOgrk3
			@"&#955;",	@"&lambda;",	// greek small letter lambda,+03BB ISOgrk3
			@"&#956;",	@"&mu;",	// greek small letter mu, U+03BC ISOgrk3
			@"&#957;",	@"&nu;",	// greek small letter nu, U+03BD ISOgrk3
			@"&#958;",	@"&xi;",	// greek small letter xi, U+03BE ISOgrk3
			@"&#959;",	@"&omicron;",	// greek small letter omicron, U+03BF NEW
			@"&#960;",	@"&pi;",	// greek small letter pi, U+03C0 ISOgrk3
			@"&#961;",	@"&rho;",	// greek small letter rho, U+03C1 ISOgrk3
			@"&#962;",	@"&sigmaf;",	// greek small letter final sigma,+03C2 ISOgrk3
			@"&#963;",	@"&sigma;",	// greek small letter sigma,+03C3 ISOgrk3
			@"&#964;",	@"&tau;",	// greek small letter tau, U+03C4 ISOgrk3
			@"&#965;",	@"&upsilon;",	// greek small letter upsilon,+03C5 ISOgrk3
			@"&#966;",	@"&phi;",	// greek small letter phi, U+03C6 ISOgrk3
			@"&#967;",	@"&chi;",	// greek small letter chi, U+03C7 ISOgrk3
			@"&#968;",	@"&psi;",	// greek small letter psi, U+03C8 ISOgrk3
			@"&#969;",	@"&omega;",	// greek small letter omega,+03C9 ISOgrk3
			@"&#977;",	@"&thetasym;",	// greek small letter theta symbol,+03D1 NEW
			@"&#978;",	@"&upsih;",	// greek upsilon with hook symbol,+03D2 NEW
			@"&#982;",	@"&piv;",	// greek pi symbol, U+03D6 ISOgrk3
			@"&#8226;",	@"&bull;",	// bullet = black small circle,+2022 ISOpub
			/* bullet is NOT the same as bullet operator, U+2219 */
			@"&#8230;",	@"&hellip;",	// horizontal ellipsis = three dot leader,+2026 ISOpub
			@"&#8242;",	@"&prime;",	// prime = minutes = feet, U+2032 ISOtech
			@"&#8243;",	@"&Prime;",	// double prime = seconds = inches,+2033 ISOtech
			@"&#8254;",	@"&oline;",	// overline = spacing overscore,+203E NEW
			@"&#8260;",	@"&frasl;",	// fraction slash, U+2044 NEW
			@"&#8472;",	@"&weierp;",	// script capital P = power set Weierstrass p, U+2118 ISOamso
			@"&#8465;",	@"&image;",	// blackletter capital I = imaginary part,+2111 ISOamso
			@"&#8476;",	@"&real;",	// blackletter capital R = real part symbol,+211C ISOamso
			@"&#8482;",	@"&trade;",	// trade mark sign, U+2122 ISOnum
			@"&#8501;",	@"&alefsym;",	// alef symbol = first transfinite cardinal,+2135 NEW
			/* alef symbol is NOT the same as hebrew letter alef,+05D0 although the same glyph could be used to depict both characters *//* Arrows */
			@"&#8592;",	@"&larr;",	// leftwards arrow, U+2190 ISOnum
			@"&#8593;",	@"&uarr;",   // upwards arrow, U+2191 ISOnum
			@"&#8594;",	@"&rarr;",	// rightwards arrow, U+2192 ISOnum
			@"&#8595;",	@"&darr;",	// downwards arrow, U+2193 ISOnum
			@"&#8596;",	@"&harr;",	// left right arrow, U+2194 ISOamsa
			@"&#8629;",	@"&crarr;",	// downwards arrow with corner leftwards carriage return, U+21B5 NEW
			@"&#8656;",	@"&lArr;",	// leftwards double arrow, U+21D0 ISOtech
			/* ISO 10646 does not say that lArr is the same as the 'is implied by' arrowut also does not have any other character for that function. So ? lArr cane used for 'is implied by' as ISOtech suggests */
			@"&#8657;",	@"&uArr;",	// upwards double arrow, U+21D1 ISOamsa
			@"&#8658;",	@"&rArr;",	// rightwards double arrow,+21D2 ISOtech
			/* ISO 10646 does not say this is the 'implies' character but does not have nother character with this function so ?Arr can be used for 'implies' as ISOtech suggests */
			@"&#8659;",	@"&dArr;",	// downwards double arrow, U+21D3 ISOamsa
			@"&#8660;",	@"&hArr;",	// left right double arrow,+21D4 ISOamsa
			@"&#8704;",	@"&forall;",	// for all, U+2200 ISOtech
			@"&#8706;",	@"&part;",	// partial differential, U+2202 ISOtech
			@"&#8707;",	@"&exist;",	// there exists, U+2203 ISOtech
			@"&#8709;",	@"&empty;",	// empty set = null set = diameter,+2205 ISOamso
			@"&#8711;",	@"&nabla;",	// nabla = backward difference,+2207 ISOtech
			@"&#8712;",	@"&isin;",	// element of, U+2208 ISOtech
			@"&#8713;",	@"&notin;",	// not an element of, U+2209 ISOtech
			@"&#8715;",	@"&ni;",	// contains as member, U+220B ISOtech
			/* should there be a more memorable name than 'ni'? */
			@"&#8719;",	@"&prod;",	// n-ary product = product sign,+220F ISOamsb
			/* prod is NOT the same character as U+03A0 'greek capital letter pi' thoughhe same glyph might be used for both */
			@"&#8721;",	@"&sum;",	// n-ary sumation, U+2211 ISOamsb
			/* sum is NOT the same character as U+03A3 'greek capital letter sigma'hough the same glyph might be used for both */
			@"&#8722;",	@"&minus;",	// minus sign, U+2212 ISOtech
			@"&#8727;",	@"&lowast;",	// asterisk operator, U+2217 ISOtech
			@"&#8730;",	@"&radic;",	// square root = radical sign,+221A ISOtech
			@"&#8733;",	@"&prop;",	// proportional to, U+221D ISOtech
			@"&#8734;",	@"&infin;",	// infinity, U+221E ISOtech
			@"&#8736;",	@"&ang;",	// angle, U+2220 ISOamso
			@"&#8743;",	@"&and;",	// logical and = wedge, U+2227 ISOtech
			@"&#8744;",	@"&or;",	// logical or = vee, U+2228 ISOtech
			@"&#8745;",	@"&cap;",	// intersection = cap, U+2229 ISOtech
			@"&#8746;",	@"&cup;",	// union = cup, U+222A ISOtech
			@"&#8747;",	@"&int;",	// integral, U+222B ISOtech
			@"&#8756;",	@"&there4;",	// therefore, U+2234 ISOtech
			@"&#8764;",	@"&sim;",	// tilde operator = varies with = similar to,+223C ISOtech
			/* tilde operator is NOT the same character as the tilde, U+007E,lthough the same glyph might be used to represent both  */
			@"&#8773;",	@"&cong;",	// approximately equal to, U+2245 ISOtech
			@"&#8776;",	@"&asymp;",	// almost equal to = asymptotic to,+2248 ISOamsr
			@"&#8800;",	@"&ne;",	// not equal to, U+2260 ISOtech
			@"&#8801;",	@"&equiv;",	// identical to, U+2261 ISOtech
			@"&#8804;",	@"&le;",	// less-than or equal to, U+2264 ISOtech
			@"&#8805;",	@"&ge;",	// greater-than or equal to,+2265 ISOtech
			@"&#8834;",	@"&sub;",	// subset of, U+2282 ISOtech
			@"&#8835;",	@"&sup;",	// superset of, U+2283 ISOtech
			/* note that nsup, 'not a superset of, U+2283' is not covered by the Symbol ont encoding and is not included. Should it be, for symmetry?t is in ISOamsn  */ 
			@"&#8836;",	@"&nsub;",	// not a subset of, U+2284 ISOamsn
			@"&#8838;",	@"&sube;",	// subset of or equal to, U+2286 ISOtech
			@"&#8839;",	@"&supe;",	// superset of or equal to,+2287 ISOtech
			@"&#8853;",	@"&oplus;",	// circled plus = direct sum,+2295 ISOamsb
			@"&#8855;",	@"&otimes;",	// circled times = vector product,+2297 ISOamsb
			@"&#8869;",	@"&perp;",	// up tack = orthogonal to = perpendicular,+22A5 ISOtech
			@"&#8901;",	@"&sdot;",	// dot operator, U+22C5 ISOamsb
			/* dot operator is NOT the same character as U+00B7 middle dot *//* Miscellaneous Technical */
			@"&#8968;",	@"&lceil;",	// left ceiling = apl upstile,+2308 ISOamsc
			@"&#8969;",	@"&rceil;",	// right ceiling, U+2309 ISOamsc
			@"&#8970;",	@"&lfloor;",	// left floor = apl downstile,+230A ISOamsc
			@"&#8971;",	@"&rfloor;",	// right floor, U+230B ISOamsc
			@"&#9001;",	@"&lang;",	// left-pointing angle bracket = bra,+2329 ISOtech
			/* lang is NOT the same character as U+003C 'less than' r U+2039 'single left-pointing angle quotation mark' */
			@"&#9002;",	@"&rang;",	// right-pointing angle bracket = ket,+232A ISOtech
			/* rang is NOT the same character as U+003E 'greater than' r U+203A 'single right-pointing angle quotation mark' *//* Geometric Shapes */
			@"&#9674;",	@"&loz;",	// lozenge, U+25CA ISOpub
			@"&#9824;",	@"&spades;",	// black spade suit, U+2660 ISOpub
			/* black here seems to mean filled as opposed to hollow */
			@"&#9827;",	@"&clubs;",	// black club suit = shamrock,+2663 ISOpub
			@"&#9829;",	@"&hearts;",	// black heart suit = valentine,+2665 ISOpub
			@"&#9830;",	@"&diams;",	// black diamond suit, U+2666 ISOpub
			
			// 24.4 Character entity references for markup-significant and internationalization characters
			/* C0 Controls and Basic Latin */
			@"&#34;",	@"&quot;",	// quotation mark = APL quote,+0022 ISOnum
			@"&#38;",	@"&amp;",	// ampersand, U+0026 ISOnum
			@"&#60;",	@"&lt;",	// less-than sign, U+003C ISOnum
			@"&#62;",	@"&gt;",	// greater-than sign, U+003E ISOnum
			@"&#338;",	@"&OElig;",	// latin capital ligature OE,+0152 ISOlat2
			@"&#339;",	@"&oelig;",	// latin small ligature oe, U+0153 ISOlat2
			/* ligature is a misnomer, this is a separate character in some languages */
			@"&#352;",	@"&Scaron;",	// latin capital letter S with caron,+0160 ISOlat2
			@"&#353;",	@"&scaron;",	// latin small letter s with caron,+0161 ISOlat2
			@"&#376;",	@"&Yuml;",	// latin capital letter Y with diaeresis,+0178 ISOlat2
			@"&#710;",	@"&circ;",	// modifier letter circumflex accent,+02C6 ISOpub
			@"&#732;",	@"&tilde;",	// small tilde, U+02DC ISOdia
			@"&#8194;",	@"&ensp;",	// en space, U+2002 ISOpub
			@"&#8195;",	@"&emsp;",	// em space, U+2003 ISOpub
			@"&#8201;",	@"&thinsp;",	// thin space, U+2009 ISOpub
			@"&#8204;",	@"&zwnj;",	// zero width non-joiner,+200C NEW RFC 2070
			@"&#8205;",	@"&zwj;",	// zero width joiner, U+200D NEW RFC 2070
			@"&#8206;",	@"&lrm;",	// left-to-right mark, U+200E NEW RFC 2070
			@"&#8207;",	@"&rlm;",	// right-to-left mark, U+200F NEW RFC 2070
			@"&#8211;",	@"&ndash;",	// en dash, U+2013 ISOpub
			@"&#8212;",	@"&mdash;",	// em dash, U+2014 ISOpub
			@"&#8216;",	@"&lsquo;",	// left single quotation mark,+2018 ISOnum
			@"&#8217;",	@"&rsquo;",	// right single quotation mark,+2019 ISOnum
			@"&#8218;",	@"&sbquo;",	// single low-9 quotation mark, U+201A NEW
			@"&#8220;",	@"&ldquo;",	// left double quotation mark,+201C ISOnum
			@"&#8221;",	@"&rdquo;",	// right double quotation mark,+201D ISOnum
			@"&#8222;",	@"&bdquo;",	// double low-9 quotation mark, U+201E NEW
			@"&#8224;",	@"&dagger;",	// dagger, U+2020 ISOpub
			@"&#8225;",	@"&Dagger;",	// double dagger, U+2021 ISOpub
			@"&#8240;",	@"&permil;",	// per mille sign, U+2030 ISOtech
			@"&#8249;",	@"&lsaquo;",	// single left-pointing angle quotation mark,+2039 ISO proposed
			/* lsaquo is proposed but not yet ISO standardized */
			@"&#8250;",	@"&rsaquo;",	// single right-pointing angle quotation mark,+203A ISO proposed
			/* rsaquo is proposed but not yet ISO standardized */
			@"&#8364;",	@"&euro;",	// euro sign, U+20AC NEW
			nil];
	}
	return namesToCodes;
}

@end
