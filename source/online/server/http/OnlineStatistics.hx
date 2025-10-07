package ;

import sys.Http;
import sys.thread.Thread;

class OnlineStatistics {
    public static final REQUEST_INTERVAL:Float = 60;
    public static final API_URL:String = "https://online.novaflare.top/api.php";
    public static final API_KEY:String = "114514";
    public static final APP_NAME:String = "NovaFlare-Engine";

    private var running:Bool = false;
    private var thread:Thread;

    public function new() {
    }

    public function start():Void {
        if (running) return;
        
        running = true;
        thread = Thread.create(function() {
            while (running) {
                try {
                    sendRequest();
                }
                
                var sleepTime = Std.int(REQUEST_INTERVAL * 1000);
                var slept = 0;
                while (running && slept < sleepTime) {
                    var chunk = Std.int(Math.min(1000, sleepTime - slept));
                    Sys.sleep(chunk / 1000);
                    slept += chunk;
                }
            }
        });
    }

    public function stop():Void {
        running = false;
    }

    private function sendRequest():Void {
        var http = new Http(API_URL);
        
        var platform = getPlatform();
        http.setHeader("X-Platform", platform);
        http.setHeader("X-API-KEY", API_KEY);
        http.setHeader("X-Api-App", APP_NAME);
        
        #if (sys && !nodejs)
        http.cnxTimeout = 10;
        #end
        
        http.request(true);
    }

    private function getPlatform():String {
        return 
            #if android "android"
            #elseif ios "ios"
            #elseif linux "linux"
            #elseif windows "windows"
            #elseif mac "mac"
            #else "unknown" #end;
    }
}