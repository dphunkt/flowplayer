package org.flowplayer.util {
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.crypto.symmetric.IPad;
	import com.hurlant.crypto.symmetric.IVMode;
	import com.hurlant.crypto.symmetric.NullPad;
	import com.hurlant.util.Hex;
	
	import flash.utils.ByteArray;	
	/**
	 * @author api
	 */
	public class DecryptUtil {
		private static var log:Log = new Log("org.flowplayer.util::DecryptUtil");
		private static const KEY:String = "dbf8a9efe09130e02d8628d5019db882";
		
		public static function decrypt(iv:String, cipher:String):String {
			var append:String = "";
			// get a key
			var kdata:ByteArray;
			kdata = Hex.toArray(KEY);
			// get an output
			var data:ByteArray = Hex.toArray(cipher);
			
			// get an algorithm..
			var name:String = "aes-cbc";
			
			var pad:IPad = new NullPad();
			var mode:ICipher = Crypto.getCipher(name, kdata, pad);
			//pad.setBlockSize(mode.getBlockSize());
			// set IV
			var ivmode:IVMode = mode as IVMode;
			ivmode.IV = Hex.toArray(iv);
			
			try{
				mode.decrypt(data);
				append = Hex.toString(Hex.fromArray(data));
			} catch (e:Error){
				trace(e);
			}
			return append;
		}
	}
}