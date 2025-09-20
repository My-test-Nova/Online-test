package online.states;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

class MyRoomState extends Schema {
	@:type("string")
	public var mySynchronizedProperty:String = "Hello world";
	
	@:type("string")
	public var sessionId:String = "MaoPou";
}
