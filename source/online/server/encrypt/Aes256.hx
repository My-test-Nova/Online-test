package online.server.encrypt;

import haxe.crypto.Base64;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.PKCS7;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.Aes;

import trandom.Native;

class Aes256 {
    static final BLOCK_SIZE:Int = 16;
    static final ENCRYPTION_KEY_STR:String = "c138265b0f77cccd86192a7173668090";
    static final ENCRYPTION_KEY:Bytes = Bytes.ofString(ENCRYPTION_KEY_STR);
    
    /*
      加密 懂？
    */
    
    public static function encrypt(words:String):String {
        var iv:Bytes = generateRandomIV();
        
        var dataBytes:Bytes = Bytes.ofString(words);
        var paddedData:Bytes = PKCS7.pad(dataBytes, BLOCK_SIZE);
        
        var aes:Aes = new Aes(ENCRYPTION_KEY, iv);
        var encryptedBytes:Bytes = aes.encrypt(Mode.CBC, paddedData);
        
        var combined = new BytesBuffer();
        combined.add(iv);
        combined.add(encryptedBytes);
        var combinedBytes = combined.getBytes();
        
        return Base64.encode(combinedBytes);
    }
    
    /*
      解密 懂？
    */
    
    public static function decrypt(words:String):String {
        var cleanStr:String = words;
        
        cleanStr = stringReplace(cleanStr, " ", "");
        cleanStr = stringReplace(cleanStr, "\n", "");
        cleanStr = stringReplace(cleanStr, "\r", "");
        cleanStr = stringReplace(cleanStr, "\t", "");
        
        var validChars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
        var filtered:String = "";
        for (i in 0...cleanStr.length) {
            var c = cleanStr.charAt(i);
            var isValid = false;
            for (j in 0...validChars.length) {
                if (validChars.charAt(j) == c) {
                    isValid = true;
                    break;
                }
            }
            if (isValid) {
                filtered += c;
            }
        }
        cleanStr = filtered;

        while (cleanStr.length % 4 != 0) {
            cleanStr += "=";
        }

        var encryptedBytes:Bytes;
        try {
            encryptedBytes = Base64.decode(cleanStr);
        } catch (e:Dynamic) {
            throw "Base64解码失败: " + e;
        }

        if (encryptedBytes.length < BLOCK_SIZE) {
            throw "加密数据长度不足（至少需要" + BLOCK_SIZE + "字节）";
        }

        var iv:Bytes = encryptedBytes.sub(0, BLOCK_SIZE);
        var cipherText:Bytes = encryptedBytes.sub(BLOCK_SIZE, encryptedBytes.length - BLOCK_SIZE);

        var aes:Aes = new Aes(ENCRYPTION_KEY, iv);
        var decryptedBytes:Bytes = aes.decrypt(Mode.CBC, cipherText);
        return decryptedBytes.toString();
    }
    
    /*
     * 生成随机IV
    */

    static function generateRandomIV():Bytes {
        var iv = Bytes.alloc(BLOCK_SIZE);
        
        for (i in 0...Std.int(BLOCK_SIZE / 4)) {
            iv.setInt32(i * 4, Native.get());
        }
        
        var remaining = BLOCK_SIZE % 4;
        if (remaining > 0) {
            var lastChunk = Native.get();
            for (i in 0...remaining) {
                iv.set(
                    (BLOCK_SIZE - remaining) + i,
                    (lastChunk >> (8 * i)) & 0xFF  // 按位截取
                );
            }
        }
        
        return iv;
    }
    
    static function stringReplace(str:String, search:String, replace:String):String {
        var result = "";
        var i = 0;
        var len = str.length;
        var searchLen = search.length;
        
        while (i < len) {
            if (i + searchLen <= len && str.substr(i, searchLen) == search) {
                result += replace;
                i += searchLen;
            } else {
                result += str.charAt(i);
                i++;
            }
        }
        return result;
    }
}