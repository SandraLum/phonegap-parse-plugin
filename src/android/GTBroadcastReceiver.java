package org.apache.cordova.core;

import org.json.JSONException;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

public class GTBroadcastReceiver extends BroadcastReceiver {
 
	@Override
  	public void onReceive(Context context, Intent intent) {
		
		Bundle extras = intent.getExtras();
		String data = extras.getString("com.parse.Data");
		
		try {
			ParsePlugin.addNotification(data);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	};
}
