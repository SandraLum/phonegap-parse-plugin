package org.apache.cordova.core;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.leotech.globetrekker.Globetrekker;
import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseInstallation;
import com.parse.PushService;

public class ParsePlugin extends CordovaPlugin {
    public static final String ACTION_INITIALIZE = "initialize";
    public static final String ACTION_GET_INSTALLATION_ID = "getInstallationId";
    public static final String ACTION_GET_INSTALLATION_OBJECT_ID = "getInstallationObjectId";
    public static final String ACTION_GET_SUBSCRIPTIONS = "getSubscriptions";
    public static final String ACTION_SUBSCRIBE = "subscribe";
    public static final String ACTION_UNSUBSCRIBE = "unsubscribe";
    public static final String ACTION_REGISTER_LISTENER = "registerListener";
    public static final String ACTION_FLUSH_NOTIFICATIONS = "flushNotifications";
    
    public static List<JSONObject> pendingNotifications = new ArrayList<JSONObject>();
    public static CallbackContext listenerCallbackContext;
    public static boolean isListening = false;
    private static boolean autoflush = true;
    

    @Override
    public boolean execute(String action, JSONArray args,
            CallbackContext callbackContext) throws JSONException {
        if (action.equals(ACTION_INITIALIZE)) {
            this.initialize(callbackContext, args);
            this.registerListener(callbackContext);
            return true;
        }
        if (action.equals(ACTION_GET_INSTALLATION_ID)) {
            this.getInstallationId(callbackContext);
            return true;
        }

        if (action.equals(ACTION_GET_INSTALLATION_OBJECT_ID)) {
            this.getInstallationObjectId(callbackContext);
            return true;
        }
        if (action.equals(ACTION_GET_SUBSCRIPTIONS)) {
            this.getSubscriptions(callbackContext);
            return true;
        }
        if (action.equals(ACTION_SUBSCRIBE)) {
            this.subscribe(args.getString(0), callbackContext);
            return true;
        }
        if (action.equals(ACTION_UNSUBSCRIBE)) {
            this.unsubscribe(args.getString(0), callbackContext);
            return true;
        }
        if (action.equals(ACTION_REGISTER_LISTENER)) {
            this.registerListener(callbackContext);
            return true;
        }
        if (action.equals(ACTION_FLUSH_NOTIFICATIONS)) {
            ParsePlugin.flushNotificationToClient();
            return true;
        }
        return false;
    }
    
    private void registerListener(CallbackContext callbackContext){ 
        //Set to a listenerCallback variable to be accessed upon receiving a broadcast
        listenerCallbackContext = callbackContext;
        isListening = true;
        
    	PluginResult result = new PluginResult(PluginResult.Status.OK, "Registered Listener");
    	result.setKeepCallback(true);
    	
        listenerCallbackContext.sendPluginResult(result);
        autoflush = true;
        flushNotificationToClient();
    }
    
    public static void addNotification(String data) throws JSONException{
        pendingNotifications.add(new JSONObject(data));
        if(isListening && autoflush){
            flushNotificationToClient();
        }
    }
    
    public static void flushNotificationToClient(){
        Iterator<JSONObject> iNotifications = pendingNotifications.iterator();
        while(iNotifications.hasNext()) {
        	PluginResult result = new PluginResult(PluginResult.Status.OK, iNotifications.next());
        	result.setKeepCallback(true);       	
            listenerCallbackContext.sendPluginResult(result);
            
            iNotifications.remove();
        }
    }

    private void initialize(final CallbackContext callbackContext,
    	final JSONArray args) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String appId = args.getString(0);
                    String clientKey = args.getString(1);
                    Parse.initialize(cordova.getActivity(), appId, clientKey);
                     PushService.setDefaultPushCallback(cordova.getActivity(),Globetrekker.class);
                    ParseInstallation.getCurrentInstallation()
                            .saveInBackground();
                    ParseAnalytics.trackAppOpened(cordova.getActivity()
                            .getIntent());
                    callbackContext.success();
                } catch (JSONException e) {
                    callbackContext.error("JSONException");
                }
            }
        });
    }

    private void getInstallationId(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                String installationId = ParseInstallation
                        .getCurrentInstallation().getInstallationId();
                callbackContext.success(installationId);
            }
        });
    }

    private void getInstallationObjectId(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                String objectId = ParseInstallation.getCurrentInstallation()
                        .getObjectId();
                callbackContext.success(objectId);
            }
        });
    }

    private void getSubscriptions(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                Set<String> subscriptions = PushService
                        .getSubscriptions(cordova.getActivity());
                callbackContext.success(subscriptions.toString());
            }
        });
    }

    private void subscribe(final String channel,
            final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                PushService.subscribe(cordova.getActivity(), channel, cordova
                        .getActivity().getClass());
                callbackContext.success();
            }
        });
    }

    private void unsubscribe(final String channel,
            final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                PushService.unsubscribe(cordova.getActivity(), channel);
                callbackContext.success();
            }
        });
    }
    
    public static void startFlush(){
    	autoflush = true;
    }
   
    public static void stopFlush(){
    	autoflush = false;
    }
    
    @Override
    public void onDestroy() {
    	super.onDestroy();
    	stopFlush();
    }
    @Override
    public void onReset() {
    	super.onReset();
    	stopFlush();
    	//ParsePlugin.flushNotificationToClient();
    }        
}
