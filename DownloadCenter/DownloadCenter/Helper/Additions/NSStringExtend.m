//
//  NSStringExtend.m
//  fushihui
//
//  Created by jinzhu on 10-8-11.
//  Copyright 2010 Sharppoint Group All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CoreText/CoreText.h>

#import "NSStringExtend.h"
#import "NSDataAdditions.h"
#import "NSURLAdditions.h"


#pragma mark -
@implementation NSString(ExtendedForUrlComponents)
- (NSString *)stringByAppendingUrlComponent:(NSString *)urlComponent
{	
	if(urlComponent == nil || [urlComponent length] == 0)
		return self;
	
	NSString *url = self;
	int len = [url length];
	unichar tail = [url characterAtIndex:len-1];
	unichar head = [urlComponent characterAtIndex:0];
	unichar sep = (unichar)'/';
	if(tail != sep && head != sep)
	{
		url = [url stringByAppendingString:@"/"];
	}
	url = [url stringByAppendingString:urlComponent];
	return url;
}

- (NSString *)stringByAppendingUrlParameter:(NSString *)param forKey:(NSString *)key
{
	NSString *url = self;
	NSRange ret = [url rangeOfString:@"?"];
	if(ret.location == NSNotFound)
	{
		url = [url stringByAppendingFormat:@"?%@=%@", key, param];
	}
	else
	{
		url = [url stringByAppendingFormat:@"&%@=%@", key, param];
	}
	
	return url;
}

- (NSString *)stringByAddPrefix:(NSString *)prefix
{
	NSString *url = self;
	if (![url hasPrefix:prefix]) 
	{
		//NSAssert(0, (@"url missing the prefix:%@",url)); 
		url = [NSString stringWithFormat:@"%@%@",prefix,url];
		
	}
	return url;
}

- (NSString *)stringByReplaceUrlHost:(NSString *)newHost
{	
	NSURL *tmpUrl = [NSURL URLWithString:self];
	return [tmpUrl stringByReplacingUrlHost:newHost];
}

- (BOOL)isAppUrlString
{
	return [[NSURL URLWithString:self] isAppURL];
}

- (BOOL)isNmuberString
{
    BOOL isNmuberString = NO;
    long long int n = [self longLongValue];
    if (n < 18999999999 && n > 13000000000) {
        isNmuberString = YES;
    }
    return isNmuberString;
} 

- (BOOL)isEmailString 
{
    BOOL isEmailString = NO;
    NSRange range = [self rangeOfString:@"@"];
    if (range.length > 0) {
        isEmailString = YES;
    }
    return isEmailString;
}

@end


#pragma mark -
@implementation NSString(URLEncodeExtended)

+ (NSString*)stringWithStringEncodeUTF8:(NSString *)strToEncode
{
	if (strToEncode == nil ) {
		return @"";	
	}
	
	return [strToEncode urlEncodedStringUsingEncoding:NSUTF8StringEncoding];
}


- (NSString *)encodedUTF8String
{
	return [self urlEncodedStringUsingEncoding:NSUTF8StringEncoding];
}


+ (NSString*)stringWithStringUrlEncoded:(NSString *)strToEncode usingEncoding:(NSStringEncoding)encoding
{
	if (strToEncode == nil ) {
		return @"";	
	}
	
	return [strToEncode urlEncodedStringUsingEncoding:encoding];
}

- (NSString *)urlEncodedStringUsingEncoding:(NSStringEncoding)encoding
{
	CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);

	return [self urlEncodedUsingCFStringEncoding:cfencoding alreadyPercentEscaped: NO];
}

- (NSString *)urlEncodedUsingCFStringEncoding:(CFStringEncoding)cfencoding alreadyPercentEscaped:(BOOL)percentEscaped
{
    //CFStringRef nonAlphaNumValidChars = CFSTR("![ DISCUZ_CODE_1 ]’()*+,-./:;=?@_~");
	CFStringRef nonAlphaNumValidChars = CFSTR("![ ]’()*+,-./:;=?@_~&");
	CFStringRef preprocessedString = NULL;
    if(percentEscaped)
    {
        preprocessedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), cfencoding);
    }
	CFStringRef newStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,preprocessedString ? preprocessedString : (CFStringRef)self,
                                                                 NULL,nonAlphaNumValidChars, cfencoding);
	if(preprocessedString)
    {
        CFRelease(preprocessedString);
    }
	NSString *re = [NSString stringWithFormat:@"%@",(NSString *)newStr];
	CFRelease(newStr);
	return re;
}

- (NSString *)urlDedcodeStringUsingEncoding:(NSStringEncoding)encoding
{
	CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
	return [self urlDecodeUsingCFStringEncoding:cfencoding alreadyPercentEscaped: NO];
}

- (NSString *)urlDecodeUsingCFStringEncoding:(CFStringEncoding)cfencoding alreadyPercentEscaped:(BOOL)percentEscaped
{
	CFStringRef newStr = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), cfencoding);
    NSString *re = self;
    if (newStr) {
        re = [NSString stringWithFormat:@"%@",(NSString *)newStr];
        CFRelease(newStr);
    }
    
	return re;
}

- (NSString *)urlEncodedUsingCFStringEncoding:(CFStringEncoding)cfencoding
{
    return [self urlEncodedUsingCFStringEncoding: cfencoding alreadyPercentEscaped:YES];
}


@end

#pragma mark -	
@implementation NSString(MD5Extended)
+ (NSString *)stringWithUUIDGenerated
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
	NSString *finalStr = [NSString stringWithString:(NSString *)uuidStr];
	CFRelease(uuid);
	CFRelease(uuidStr);
	
	return finalStr;
}


+(NSString*)generatingMD5:(NSArray *)array
{
    if(array==nil ) 
		return @"ERROR GETTING MD5";
	
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
	
	for(NSString *string in array)
	{
		const char* data = [string UTF8String];
        CC_MD5_Update(&md5, data, strlen(data));
	}
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
	NSString* md5String = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
						   digest[0], digest[1], 
						   digest[2], digest[3],
						   digest[4], digest[5],
						   digest[6], digest[7],
						   digest[8], digest[9],
						   digest[10], digest[11],
						   digest[12], digest[13],
						   digest[14], digest[15]];
	
	
    return md5String;
}

- (NSString*)md5Hash 
{
	return [[self dataUsingEncoding:NSUTF8StringEncoding] md5Hash];
}
@end

#pragma mark --
@implementation NSString(Base64Extended)
- (NSString*)base64Encoding
{
	NSData* data;
    data = [NSData base64EncodedData:self withWrapped:NO];
	NSString* string = [[NSString alloc] initWithCString:(const char*)[data bytes] encoding:NSUTF8StringEncoding];
	
	return [string autorelease];
}

- (NSString*)base64Decoding
{
	NSData* data;
	data = [NSData base64DecodedData:self];
	NSString* string = [[NSString alloc] initWithCString:(const char*)[data bytes] encoding:NSUTF8StringEncoding];
	return [string autorelease];
}

@end


#pragma mark -
@implementation NSString (WhitespaceExtention)

- (NSString *) trimmedString {
    NSString *trimmedString = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return [trimmedString length] ? trimmedString : nil;
}

- (BOOL)isWhitespaceAndNewlines {
    NSCharacterSet* whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSInteger i = 0; i < self.length; ++i) {
        unichar c = [self characterAtIndex:i];
        if (![whitespace characterIsMember:c]) {
            return NO;
        }
    }
    return YES;
}


- (BOOL)isEmptyOrWhitespace {
    // A nil or NULL string is not the same as an empty string
    return 0 == self.length ||
    ![self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
}

@end

#pragma mark -
@implementation NSString (HexString2Data)
- (NSData*)hexString2Data
{
    if(self.length)
    {
        int j=0;
        Byte bytes[self.length];
        for(int i = 0; i < [self length]; i++)
        {
            int int_ch;  /// 两位16进制数转化后的10进制数
            unichar hex_char1 = [self characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
            int int_ch1;
            if(hex_char1 >= '0' && hex_char1 <='9')
                int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
            else if(hex_char1 >= 'A' && hex_char1 <='F')
                int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
            else
                int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
            i++;
            unichar hex_char2 = [self characterAtIndex:i]; ///两位16进制数中的第二位(低位)
            int int_ch2;
            if(hex_char2 >= '0' && hex_char2 <='9')
                int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
            else if(hex_char2 >= 'A' && hex_char1 <='F')
                int_ch2 = hex_char2-55; //// A 的Ascll - 65
            else
                int_ch2 = hex_char2-87; //// a 的Ascll - 97
            
            int_ch = int_ch1+int_ch2;
            bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
            j++;
        }
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:self.length / 2];
        return [newData autorelease];
    }
    return nil;
}
@end

#pragma mark -
@implementation NSString (AESEncryptExtention)
- (NSString*)aesEncryptWithKey:(NSString*)key
{
    if([key length])
    {
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptedData = [data AES256EncryptWithKey:key encrypt:YES];
        if(encryptedData.length)
        {
            return [encryptedData data2HexString];
        }
    }
    return nil;
}

- (NSString*)aesDecryptWithKey:(NSString*)key
{
    if([key length])
    {
        NSData* encryptedData = [self hexString2Data];
        if([encryptedData length])
        {
            NSData* decryptedData = [encryptedData AES256EncryptWithKey:key
                                                                encrypt:NO];
            if([decryptedData length])
            {
                NSString* decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
                return [decryptedStr autorelease];
            }
        }
    }
    return nil;
}
@end

#pragma mark -
@implementation NSString (DESEncryptExtention)

- (NSString*)desEncryptWithKey:(NSString*)key
{
    if([key length])
    {
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptedData = [data  DES256EncryptWithKey:key encrypt:YES];
        if(encryptedData.length)
        {
            return [encryptedData data2HexString];
        }
    }
    return nil;
}

- (NSString*)desDecryptWithKey:(NSString*)key;
{
    if([key length])
    {
        NSData* encryptedData = [self hexString2Data];
        if([encryptedData length])
        {
            NSData* decryptedData = [encryptedData DES256EncryptWithKey:key
                                                                encrypt:NO];
            if([decryptedData length])
            {
                NSString* decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
                return [decryptedStr autorelease];
            }
        }
    }
    return nil;
}

@end

#pragma mark -
@implementation NSString (StringSizeExtention)

- (CGSize)stringSizeWithFont:(UIFont *)font {
    if ([self respondsToSelector:@selector(sizeWithAttributes:)]) {
        return [self sizeWithAttributes:@{ NSFontAttributeName: font }];
    }
    else {
        return [self sizeWithFont:font];
    }
}

@end

