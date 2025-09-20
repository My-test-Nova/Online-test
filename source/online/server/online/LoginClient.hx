package online.server.online;

import haxe.Http;
import haxe.Json;

import server.encrypt.Aes256;

class LoginClient {
    static final API_URL:String = "https://online.novaflare.top/user/login/api.php";

    public var decision:Dynamic->Void = null;
    
    public function new() {}
    
    /**
     * 主登录方法
     */
    public function login(username:String, password:String):Void {
        var loginData:Dynamic = {
            "username": username,
            "password": password
        };
        
        var requestJson:String = Json.stringify(loginData);
        var encryptedRequest:String = Aes256.encrypt(requestJson);
        //trace('加密后的请求: $encryptedRequest');
        
        var http = new Http(API_URL);
        http.setHeader("Content-Type", "text/plain");
        http.setPostData(encryptedRequest);
        
        http.onError = function(error:String) {
            //trace('请求失败: $error');
            decision({
                message: error
            });
        };
        
        http.onData = function(encryptedResponse:String) {
            try {
                var decryptedResponse:String = Aes256.decrypt(encryptedResponse);
                
                var result:Dynamic = Json.parse(decryptedResponse);
                if (result.success) {
                    //trace('登录成功！用户组: ${result.user_info.user_group}');
                    decision({
                        message: 'Good',
                        name: result.user_info.username,
                        member: result.user_info.user_group,
                    });
                } else {
                    //trace('登录失败: ${result.message}');
                    decision({
                        message: result.message
                    });
                }
            } catch (e:Dynamic) {
                //trace('解密失败: $e');
            }
        };
        
        http.request(true);
    }
}
