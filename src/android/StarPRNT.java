package starprnt.cordova;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;


import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.nio.charset.UnsupportedCharsetException;
import java.util.Locale;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


import com.starmicronics.stario.PortInfo;
import com.starmicronics.stario.StarIOPort;
import com.starmicronics.stario.StarIOPortException;
import com.starmicronics.stario.StarPrinterStatus;
import com.starmicronics.starioextension.IConnectionCallback;
import com.starmicronics.starioextension.StarIoExt;
import com.starmicronics.starioextension.StarIoExt.Emulation;
import com.starmicronics.starioextension.ICommandBuilder;
import com.starmicronics.starioextension.ICommandBuilder.CutPaperAction;
import com.starmicronics.starioextension.ICommandBuilder.CodePageType;
import com.starmicronics.starioextension.StarIoExtManager;
import com.starmicronics.starioextension.StarIoExtManagerListener;


import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.ContentResolver;
import android.net.Uri;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.provider.MediaStore;
import android.telephony.IccOpenLogicalChannelResponse;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.util.Log;




/**
 * This class echoes a string called from JavaScript.
 */
public class StarPRNT extends CordovaPlugin {


    private CallbackContext _callbackContext = null;
    String strInterface;
    private StarIoExtManager starIoExtManager;


    /**
     * Executes the request and returns PluginResult.
     *
     * @param action            The action to execute.
     * @param args              JSONArry of arguments for the plugin.
     * @param callbackContext   The callback id used when calling back into JavaScript.
     * @return                  True if the action was valid, false otherwise.
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (action.equals("checkStatus")) {
            String portName = args.getString(0);
            String portSettings = getPortSettingsOption(portName, args.getString(1));
            this.checkStatus(portName, portSettings, callbackContext);
            return true;
        }else if (action.equals("portDiscovery")) {
            String port = args.getString(0);
            this.portDiscovery(port, callbackContext);
            return true;
        }else if (action.equals("printRasterReceipt")) {
            String portName = args.getString(0);
            String portSettings = getPortSettingsOption(portName, args.getString(1));
            Emulation emulation = getEmulation(args.getString(1));
            String printObj = args.getString(2);
            this.printRasterReceipt(portName, portSettings, emulation, printObj, callbackContext);
            return true;

        }else if (action.equals("printRawText")){
            String portName = args.getString(0);
            String portSettings = getPortSettingsOption(portName, args.getString(1));
            Emulation emulation = getEmulation(args.getString(1));
            String printObj = args.getString(2);

            this.printRawText(portName, portSettings, emulation, printObj, callbackContext);
            return true;
        }else if (action.equals("printRasterData")){
        String portName = args.getString(0);
        String portSettings = getPortSettingsOption(portName, args.getString(1));
        Emulation emulation = getEmulation(args.getString(1));
        String printObj = args.getString(2);

            try {
                this.printRasterData(portName, portSettings, emulation, printObj, callbackContext);
            } catch (IOException e) {
               // e.printStackTrace();
            }
            return true;
    }else if (action.equals("print")){
        String portName = args.getString(0);
        String portSettings = getPortSettingsOption(portName, args.getString(1));
        Emulation emulation = getEmulation(args.getString(1));
        JSONArray printCommands = args.getJSONArray(2);
        this.print(portName, portSettings, emulation, printCommands, callbackContext);
        return true;
    }else if (action.equals("openCashDrawer")){
        String portName = args.getString(0);
        String portSettings = getPortSettingsOption(portName, args.getString(1));
        Emulation emulation = getEmulation(args.getString(1));
        this.openCashDrawer(portName, portSettings, emulation, callbackContext);
        return true;
    } else if (action.equals("connect")){
        String portName = args.getString(0);
        String portSettings = getPortSettingsOption(portName, args.getString(1)); //get port settings using emulation parameter
        Boolean hasBarcodeReader = args.getBoolean(2);
        _callbackContext = callbackContext;
        this.connect(portName, portSettings, hasBarcodeReader, callbackContext);
        return true;
    }else if (action.equals("disconnect")){
        this.disconnect(callbackContext);
        return true;
        }
        return false;
    }


    public void checkStatus(String portName, String portSettings, CallbackContext callbackContext) {

        final Context context = this.cordova.getActivity();
        final CallbackContext _callbackContext = callbackContext;

        final String _portName = portName;
        final String _portSettings = portSettings;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        StarIOPort port = null;
                        try {

                            port = StarIOPort.getPort(_portName, _portSettings, 10000, context);

                            // A sleep is used to get time for the socket to completely open
                            try {
                                Thread.sleep(500);
                            } catch (InterruptedException e) {
                            }

                            StarPrinterStatus status;
                            Map<String, String> firmwareInformationMap = port.getFirmwareInformation();
                            status = port.retreiveStatus();


                            JSONObject json = new JSONObject();
                            try {
                                json.put("offline", status.offline);
                                json.put("coverOpen", status.coverOpen);
                                json.put("cutterError", status.cutterError);
                                json.put("receiptPaperEmpty", status.receiptPaperEmpty);
                                json.put("ModelName", firmwareInformationMap.get("ModelName"));
                                json.put("FirmwareVersion", firmwareInformationMap.get("FirmwareVersion"));
                            } catch (JSONException ex) {

                            } finally {
                                _callbackContext.success(json);
                            }


                        } catch (StarIOPortException e) {
                            _callbackContext.error("Failed to connect to printer :" + e.getMessage());
                        } finally {

                            if (port != null) {
                                try {

                                    StarIOPort.releasePort(port);
                                } catch (StarIOPortException e) {
                                    _callbackContext.error("Failed to connect to printer" + e.getMessage());
                                }
                            }

                        }

                    }
                });
    }


    private void portDiscovery(String strInterface, CallbackContext callbackContext) {

        final CallbackContext _callbackContext = callbackContext;
        final String _strInterface = strInterface;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {
                        JSONArray result = new JSONArray();
                        try {

                            if (_strInterface.equals("LAN")) {
                                result = getPortDiscovery("LAN");
                            } else if (_strInterface.equals("Bluetooth")) {
                                result = getPortDiscovery("Bluetooth");
                            } else if (_strInterface.equals("USB")) {
                                result = getPortDiscovery("USB");
                            } else {
                                result = getPortDiscovery("All");
                            }

                        } catch (StarIOPortException exception) {
                            _callbackContext.error(exception.getMessage());

                        } catch (JSONException e) {

                        } finally {

                            Log.d("Discovered ports", result.toString());
                            _callbackContext.success(result);
                        }
                    }
                });
    }


    private JSONArray getPortDiscovery(String interfaceName) throws StarIOPortException, JSONException {
        List<PortInfo> BTPortList;
        List<PortInfo> TCPPortList;
        List<PortInfo> USBPortList;

        final Context context = this.cordova.getActivity();
        final ArrayList<PortInfo> arrayDiscovery = new ArrayList<PortInfo>();

        JSONArray arrayPorts = new JSONArray();


        if (interfaceName.equals("Bluetooth") || interfaceName.equals("All")) {
            BTPortList = StarIOPort.searchPrinter("BT:");

            for (PortInfo portInfo : BTPortList) {
                arrayDiscovery.add(portInfo);
            }
        }
        if (interfaceName.equals("LAN") || interfaceName.equals("All")) {
            TCPPortList = StarIOPort.searchPrinter("TCP:");

            for (PortInfo portInfo : TCPPortList) {
                arrayDiscovery.add(portInfo);
            }
        }
        if (interfaceName.equals("USB") || interfaceName.equals("All")) {
            try {
                USBPortList = StarIOPort.searchPrinter("USB:", context);
            }catch (StarIOPortException e) {
                USBPortList = new ArrayList<PortInfo>();
            }
            for (PortInfo portInfo : USBPortList) {
                arrayDiscovery.add(portInfo);
            }
        }

        for (PortInfo discovery : arrayDiscovery) {
            String portName;

            JSONObject port = new JSONObject();
            if (discovery.getPortName().startsWith("BT:"))
                port.put("portName", "BT:" +  discovery.getMacAddress());
            else port.put("portName", discovery.getPortName());

            if (!discovery.getMacAddress().equals("")) {

                port.put("macAddress", discovery.getMacAddress());

                    if (discovery.getPortName().startsWith("BT:")) {
                        port.put("modelName", discovery.getPortName());
                    }else if (!discovery.getModelName().equals("")){
                        port.put("modelName", discovery.getModelName());
                }
            } else if (interfaceName.equals("USB") || interfaceName.equals("All")) {
                if (!discovery.getModelName().equals("")) {
                    port.put("modelName", discovery.getModelName());
                }
                if (!discovery.getUSBSerialNumber().equals(" SN:")) {
                    port.put("USBSerialNumber", discovery.getUSBSerialNumber());
                }
            }

            arrayPorts.put(port);
        }

        return arrayPorts;
    }

    private Emulation getEmulation(String emulation){

        if(emulation.equals("StarPRNT")) return Emulation.StarPRNT;
        else if (emulation.equals("StarPRNTL")) return Emulation.StarPRNTL;
        else if (emulation.equals("StarLine")) return Emulation.StarLine;
        else if (emulation.equals("StarGraphic")) return Emulation.StarGraphic;
        else if (emulation.equals("EscPos")) return Emulation.EscPos;
        else if (emulation.equals("EscPosMobile")) return Emulation.EscPosMobile;
        else if (emulation.equals("StarDotImpact")) return Emulation.StarDotImpact;
        else return Emulation.StarLine;
    };

    private String getPortSettingsOption(String portName, String emulation) { // generate the portsettings depending on the emulation type

        String portSettings = "";

     if (emulation.equals("EscPosMobile")) portSettings += "mini";
     else if (emulation.equals("EscPos")) portSettings += "escpos";
     else //StarLine, StarGraphic, StarDotImpact
         if (emulation.equals("StarPRNT") || emulation.equals("StarPRNTL")) {
        portSettings += "Portable";
        portSettings += ";l"; //retry on
     }else portSettings += "";
        return portSettings;
    }

    private void connect(final CallbackContext callbackContext){

        if (starIoExtManager != null) starIoExtManager.connect(new IConnectionCallback() {
            @Override
            public void onConnected(ConnectResult connectResult) {
                if (connectResult == ConnectResult.Success || connectResult == ConnectResult.AlreadyConnected) {

                    PluginResult result = new PluginResult(PluginResult.Status.OK, "Printer Connected");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);

                    //callbackContext.success("Printer Connected!");

                }else{
                    callbackContext.error("Error Connecting to the printer");
                }

            }

            @Override
            public void onDisconnected() {
                //Do nothing
            }
        });



    }
    private void connect(String portName, String portSettings, Boolean hasBarcodeReader, CallbackContext callbackContext) {

        final Context context = this.cordova.getActivity();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final CallbackContext _callbackContext = callbackContext;

        if(starIoExtManager != null && starIoExtManager.getPort() != null){
            starIoExtManager.disconnect(null);
        }
        starIoExtManager = new StarIoExtManager(hasBarcodeReader ? StarIoExtManager.Type.WithBarcodeReader : StarIoExtManager.Type.Standard, _portName, _portSettings, 10000, context);
        starIoExtManager.setListener(starIoExtManagerListener);

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {
                        connect(_callbackContext);
                    }
                });
        PluginResult result = new  PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true); // Keep callback
    }
    private void disconnect(CallbackContext callbackContext) {

        final Context context = this.cordova.getActivity();

        final CallbackContext _callbackContext = callbackContext;


        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        if(starIoExtManager != null &&  starIoExtManager.getPort() != null){
                            starIoExtManager.disconnect(new IConnectionCallback() {
                                @Override
                                public void onConnected(ConnectResult connectResult) {
                                    // nothing
                                }

                                @Override
                                public void onDisconnected() {
                                    sendEvent("printerOffline", null);
                                    starIoExtManager.setListener(null); //remove the listener?
                                    _callbackContext.success("Printer Disconnected!");
                                }
                            });
                        }else{
                            _callbackContext.success("No printers connected");
                        }

                    }
                });
    }



    private void printRawText(final String portName, String portSettings, Emulation emulation, String printObj, CallbackContext callbackContext) throws JSONException {

        final Context context = this.cordova.getActivity();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final Emulation _emulation = emulation;
        final JSONObject print = new JSONObject(printObj);
        final String text = print.optString("text");
        final Boolean cutReceipt = (print.has("cutReceipt") ? print.getBoolean("cutReceipt"): true);
        final Boolean openCashDrawer = (print.has("openCashDrawer")) ? print.getBoolean("openCashDrawer") : true;
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        builder.append(createCpUTF8(text));

                        if(cutReceipt){
                            builder.appendCutPaper(CutPaperAction.PartialCutWithFeed);
                        }

                        if(openCashDrawer){
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No1); // Kick cash drawer No1
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No2); // Kick cash drawer No2
                        }

                        builder.endDocument();

                        byte[] commands = builder.getCommands();

                        if(_portName == "null"){ // use StarIOExtManager
                             sendCommand(commands, starIoExtManager.getPort(), _callbackContext);

                        }else{//use StarIOPort
                        sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                        }
                    }
                });
    }
    private void printRasterReceipt(String portName, String portSettings, Emulation emulation, String printObj, CallbackContext callbackContext) throws JSONException {

        final Context context = this.cordova.getActivity();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final Emulation _emulation = emulation;
        final JSONObject print = new JSONObject(printObj);
        final String text = print.getString("text");
        final int fontSize = (print.has("fontSize")) ? print.getInt("fontSize") : 25;
        final int paperWidth = (print.has("paperWidth")) ? print.getInt("paperWidth"): 576;
        final Boolean cutReceipt = (print.has("cutReceipt") ? print.getBoolean("cutReceipt"): true);
        final Boolean openCashDrawer = (print.has("openCashDrawer")) ? print.getBoolean("openCashDrawer") : true;
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        Typeface typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL);

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        Bitmap image = createBitmapFromText(text, fontSize, paperWidth, typeface);

                        builder.appendBitmap(image, false);

                        if(cutReceipt){
                            builder.appendCutPaper(CutPaperAction.PartialCutWithFeed);
                        }

                        if(openCashDrawer){
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No1); // Kick cash drawer No1
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No2); // Kick cash drawer No2
                        }

                        builder.endDocument();

                        byte[] commands = builder.getCommands();


                        if(_portName == "null"){ // use StarIOExtManager
                            sendCommand(commands, starIoExtManager.getPort(), _callbackContext);

                        }else{//use StarIOPort
                            sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                        }

                    }
                });
    }
    private void print(String portName, String portSettings, Emulation emulation, JSONArray printCommands, CallbackContext callbackContext) throws JSONException {

        final Context context = this.cordova.getActivity();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final Emulation _emulation = emulation;
        final JSONArray _printCommands = printCommands;

        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        appendCommands(builder, _printCommands, context);

                        builder.endDocument();

                        byte[] commands = builder.getCommands();

                        if(_portName == "null"){ // use StarIOExtManager
                            sendCommand(commands, starIoExtManager.getPort(), _callbackContext);

                        }else{//use StarIOPort
                            sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                        }
                    }
                });
    }

    private void printRasterData(String portName, String portSettings, Emulation emulation, String printObj, CallbackContext callbackContext) throws IOException, JSONException {

        final Context context = this.cordova.getActivity();
        final ContentResolver contentResolver = context.getContentResolver();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final Emulation _emulation = emulation;
        final JSONObject print = new JSONObject(printObj);
        final String uriString = print.optString("uri");
        final int width = (print.has("width")) ? print.getInt("width") : 576;
        final Boolean cutReceipt = (print.has("cutReceipt") ? print.getBoolean("cutReceipt"): true);
        final Boolean openCashDrawer = (print.has("openCashDrawer")) ? print.getBoolean("openCashDrawer") : true;
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        Uri imageUri = null;
                        Bitmap bitmap = null;
                        try {
                            imageUri =  Uri.parse(uriString);
                            bitmap = MediaStore.Images.Media.getBitmap(contentResolver, imageUri);
                        } catch (IOException e) {
                            _callbackContext.error(e.getMessage());
                        }

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        builder.appendBitmap(bitmap, true, width, true);

                        if(cutReceipt){
                            builder.appendCutPaper(CutPaperAction.PartialCutWithFeed);
                        }

                        if(openCashDrawer){
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No1); // Kick cash drawer No1
                            builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No2); // Kick cash drawer No2
                        }


                        builder.endDocument();

                        byte[] commands = builder.getCommands();

                        if(_portName == "null"){ // use StarIOExtManager
                            sendCommand(commands, starIoExtManager.getPort(), _callbackContext);

                        }else{//use StarIOPort
                            sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                        }

                    }
                });
    }
    private void openCashDrawer(String portName, String portSettings, Emulation emulation, CallbackContext callbackContext) throws JSONException {
        final Context context = this.cordova.getActivity();
        final String _portName = portName;
        final String _portSettings = portSettings;
        final Emulation _emulation = emulation;
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No1);
                        builder.appendPeripheral(ICommandBuilder.PeripheralChannel.No2);

                        builder.endDocument();

                        byte[] commands = builder.getCommands();

                        if(_portName == "null"){ // use StarIOExtManager
                            sendCommand(commands, starIoExtManager.getPort(), _callbackContext);

                        }else{//use StarIOPort
                            sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                        }

                    }
                });


    }

    private boolean sendCommand(byte[] commands, StarIOPort port, CallbackContext callbackContext) {

        try {
			/*
			 * using StarIOPort3.1.jar (support USB Port) Android OS Version: upper 2.2
			 */
            try {
                Thread.sleep(200);
            } catch (InterruptedException e) {
            }
            if(port == null){ //Not connected or port closed
                callbackContext.error("Unable to Open Port, Please Connect to the printer before sending commands");
                return false;
            }

			/*
			 * Using Begin / End Checked Block method When sending large amounts of raster data,
			 * adjust the value in the timeout in the "StarIOPort.getPort" in order to prevent
			 * "timeout" of the "endCheckedBlock method" while a printing.
			 *
			 * If receipt print is success but timeout error occurs(Show message which is "There
			 * was no response of the printer within the timeout period." ), need to change value
			 * of timeout more longer in "StarIOPort.getPort" method.
			 * (e.g.) 10000 -> 30000
			 */
            StarPrinterStatus status;

            status = port.beginCheckedBlock();

            if (status.offline) {
                //sendEvent("printerOffline", null);
                throw new StarIOPortException("A printer is offline");
                //callbackContext.error("The printer is offline");
            }

            port.writePort(commands, 0, commands.length);

            port.setEndCheckedBlockTimeoutMillis(30000);// Change the timeout time of endCheckedBlock method.

            status = port.endCheckedBlock();

            if (status.coverOpen) {
                callbackContext.error("Cover open");
                //sendEvent("printerCoverOpen", null);
                return false;
            } else if (status.receiptPaperEmpty) {
                callbackContext.error("Empty paper");
                //sendEvent("printerPaperEmpty", null);
                return false;
            } else if (status.offline) {
                callbackContext.error("Printer offline");
                //sendEvent("printerOffline", null);
                return false;
            }
            callbackContext.success("Success!");

        } catch (StarIOPortException e) {
            //sendEvent("printerImpossible", e.getMessage());
            callbackContext.error(e.getMessage());
            return false;
        } finally {
            return true;
        }
    }
    private boolean sendCommand(Context context, String portName, String portSettings, byte[] commands, CallbackContext callbackContext) {

        StarIOPort port = null;
        try {
			/*
			 * using StarIOPort3.1.jar (support USB Port) Android OS Version: upper 2.2
			 */
                port = StarIOPort.getPort(portName, portSettings, 10000, context);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
            }

			/*
			 * Using Begin / End Checked Block method When sending large amounts of raster data,
			 * adjust the value in the timeout in the "StarIOPort.getPort" in order to prevent
			 * "timeout" of the "endCheckedBlock method" while a printing.
			 *
			 * If receipt print is success but timeout error occurs(Show message which is "There
			 * was no response of the printer within the timeout period." ), need to change value
			 * of timeout more longer in "StarIOPort.getPort" method.
			 * (e.g.) 10000 -> 30000
			 */
            StarPrinterStatus status = port.beginCheckedBlock();

            if (status.offline) {
                //throw new StarIOPortException("A printer is offline");
                callbackContext.error("The printer is offline");
                return false;
            }

            port.writePort(commands, 0, commands.length);


            port.setEndCheckedBlockTimeoutMillis(30000);// Change the timeout time of endCheckedBlock method.
            status = port.endCheckedBlock();

            if (status.coverOpen) {
                callbackContext.error("Cover open");
                return false;
            } else if (status.receiptPaperEmpty) {
                callbackContext.error("Empty paper");
                return false;
            } else if (status.offline) {
                callbackContext.error("Printer offline");
                return false;
            }
            callbackContext.success("Success!");

        } catch (StarIOPortException e) {
            callbackContext.error(e.getMessage());
        } finally {
            if (port != null) {
                try {
                    StarIOPort.releasePort(port);
                } catch (StarIOPortException e) {
                }
            }
            return true;
        }
    }

    private void appendCommands(ICommandBuilder builder, JSONArray printCommands, Context context) {
        Charset encoding = Charset.forName("US-ASCII");
        try {
            for (int i = 0; i < printCommands.length(); i++) {
                JSONObject command = (JSONObject) printCommands.get(i);
                if(command.has("appendCharacterSpace")) builder.appendCharacterSpace(command.getInt("appendCharacterSpace"));
                else if (command.has("appendEncoding")) encoding = getEncoding(command.getString("appendEncoding"));
                else if (command.has("appendCodePage")) builder.appendCodePage(getCodePageType(command.getString("appendCodePage")));
                else if (command.has("append")) builder.append(command.getString("append").getBytes(encoding));
                else if (command.has("appendRaw")) builder.append(command.getString("appendRaw").getBytes(encoding));
                else if (command.has("appendEmphasis")) builder.appendEmphasis(command.getString("appendEmphasis").getBytes(encoding));
                else if (command.has("enableEmphasis")) builder.appendEmphasis(command.getBoolean("enableEmphasis"));
                else if (command.has("appendInvert")) builder.appendInvert(command.getString("appendInvert").getBytes(encoding));
                else if (command.has("enableInvert")) builder.appendInvert(command.getBoolean("enableInvert"));
                else if (command.has("appendUnderline")) builder.appendUnderLine(command.getString("appendUnderline").getBytes(encoding));
                else if (command.has("enableUnderline")) builder.appendUnderLine(command.getBoolean("enableUnderline"));
                else if (command.has("appendInternational")) builder.appendInternational(getInternational(command.getString("appendInternational")));
                else if (command.has("appendLineFeed")) builder.appendLineFeed(command.getInt("appendLineFeed"));
                else if (command.has("appendUnitFeed")) builder.appendUnitFeed(command.getInt("appendUnitFeed"));
                else if (command.has("appendLineSpace")) builder.appendLineSpace(command.getInt("appendLineSpace"));
                else if (command.has("appendFontStyle")) builder.appendFontStyle(getFontStyle(command.getString("appendFontStyle")));
                else if (command.has("appendCutPaper")) builder.appendCutPaper(getCutPaperAction(command.getString("appendCutPaper")));
                else if (command.has("openCashDrawer")) builder.appendPeripheral(getPeripheralChannel(command.getInt("openCashDrawer")));
                else if (command.has("appendBlackMark")) builder.appendBlackMark(getBlackMarkType(command.getString("appendBlackMark")));
                else if (command.has("appendBytes")) {
                    JSONArray bytesArray = command.getJSONArray("appendBytes");
                    if (bytesArray == null ) bytesArray = new JSONArray();
                    byte[] byteData = new byte[bytesArray.length()+1];
                    for(int j=0; j < bytesArray.length(); j++){
                        byteData[j] = (byte)bytesArray.getInt(j);
                    }
                    builder.append(byteData);
                }else if (command.has("appendRawBytes")) {
                        JSONArray rawBytesArray = command.getJSONArray("appendRawBytes");
                        if (rawBytesArray == null ) rawBytesArray = new JSONArray();
                        byte[] rawByteData = new byte[rawBytesArray.length()+1];
                        for(int j=0; j < rawBytesArray.length(); j++){
                            rawByteData[j] = (byte)rawBytesArray.getInt(j);
                        }
                        builder.appendRaw(rawByteData);
                }else if (command.has("appendAbsolutePosition")) {
                    if(command.has("data")) builder.appendAbsolutePosition((command.getString("data").getBytes(encoding)), command.getInt("appendAbsolutePosition"));
                    else builder.appendAbsolutePosition(command.getInt("appendAbsolutePosition"));
                } else if (command.has("appendAlignment")) {
                    if(command.has("data")) builder.appendAlignment((command.getString("data").getBytes(encoding)), getAlignment(command.getString("appendAlignment")));
                    else builder.appendAlignment(getAlignment(command.getString("appendAlignment")));
                } else if (command.has("appendHorizontalTabPosition")) {
                    JSONArray tabPositionsArray = command.getJSONArray("appendHorizontalTabPosition");
                    if (tabPositionsArray == null ) tabPositionsArray = new JSONArray();
                    int[] tabPositions = new int[tabPositionsArray.length()];
                    for(int j=0; j < tabPositionsArray.length(); j++){
                        tabPositions[j] = tabPositionsArray.optInt(j);
                    }
                    builder.appendHorizontalTabPosition(tabPositions);
                } else if (command.has("appendLogo")){
                    ICommandBuilder.LogoSize logoSize = (command.has("logoSize") ? getLogoSize(command.getString("logoSize")): getLogoSize("Normal"));
                    builder.appendLogo(logoSize, command.getInt("appendLogo"));
                } else if (command.has("appendBarcode")){
                    ICommandBuilder.BarcodeSymbology barcodeSymbology =  (command.has("BarcodeSymbology") ? getBarcodeSymbology(command.getString("BarcodeSymbology")): getBarcodeSymbology("Code128"));
                    ICommandBuilder.BarcodeWidth barcodeWidth = (command.has("BarcodeWidth") ? getBarcodeWidth(command.getString("BarcodeWidth")): getBarcodeWidth("Mode2"));
                    int height = (command.has("height") ? command.getInt("height"): 40);
                    Boolean hri = (command.has("hri") ? command.getBoolean("hri"): true);
                    if(command.has("absolutePosition")){
                        int position =  command.getInt("absolutePosition");
                        builder.appendBarcodeWithAbsolutePosition(command.getString("appendBarcode").getBytes(encoding), barcodeSymbology, barcodeWidth, height, hri, position);
                    }else if(command.has("alignment")){
                        ICommandBuilder.AlignmentPosition alignmentPosition = getAlignment(command.getString("alignment"));
                        builder.appendBarcodeWithAlignment(command.getString("appendBarcode").getBytes(encoding), barcodeSymbology, barcodeWidth, height, hri, alignmentPosition);
                    }else builder.appendBarcode(command.getString("appendBarcode").getBytes(encoding), barcodeSymbology, barcodeWidth, height, hri);
                } else if (command.has("appendMultiple")){
                    int width = (command.has("width") ? command.getInt("width"): 1);
                    int height = (command.has("height") ? command.getInt("height"): 1);
                    builder.appendMultiple(command.getString("appendMultiple").getBytes(encoding), width, height);
                } else if (command.has("enableMultiple")){
                    int width = (command.has("width") ? command.getInt("width"): 1);
                    int height = (command.has("height") ? command.getInt("height"): 1);
                    Boolean enableMultiple = command.getBoolean("enableMultiple");
                    if(enableMultiple) builder.appendMultiple(width, height);
                    else builder.appendMultiple(1,1); // Reset to default when false sent
                } else if (command.has("appendQrCode")){
                    ICommandBuilder.QrCodeModel qrCodeModel =  (command.has("QrCodeModel") ? getQrCodeModel(command.getString("QrCodeModel")): getQrCodeModel("No2"));
                    ICommandBuilder.QrCodeLevel qrCodeLevel = (command.has("QrCodeLevel") ? getQrCodeLevel(command.getString("QrCodeLevel")): getQrCodeLevel("H"));
                    int cell = (command.has("cell") ? command.getInt("cell"): 4);
                    if(command.has("absolutePosition")){
                        int position =  command.getInt("absolutePosition");
                        builder.appendQrCodeWithAbsolutePosition(command.getString("appendQrCode").getBytes(encoding), qrCodeModel, qrCodeLevel, cell, position);
                    }else if(command.has("alignment")){
                        ICommandBuilder.AlignmentPosition alignmentPosition = getAlignment(command.getString("alignment"));
                        builder.appendQrCodeWithAlignment(command.getString("appendQrCode").getBytes(encoding), qrCodeModel, qrCodeLevel, cell, alignmentPosition);
                    }else builder.appendQrCode(command.getString("appendQrCode").getBytes(encoding), qrCodeModel, qrCodeLevel, cell);
                } else if (command.has("appendBitmap")){
                    ContentResolver contentResolver = context.getContentResolver();
                    String uriString = command.optString("appendBitmap");
                    boolean diffusion = (command.has("diffusion")) ? command.getBoolean("diffusion") : true;
                    int width = (command.has("width")) ? command.getInt("width") : 576;
                    boolean bothScale = (command.has("bothScale")) ? command.getBoolean("bothScale") : true;
                    ICommandBuilder.BitmapConverterRotation rotation = (command.has("rotation")) ? getConverterRotation(command.getString("rotation")) : getConverterRotation("Normal");
                    try {
                        Uri imageUri =  Uri.parse(uriString);
                        Bitmap bitmap = MediaStore.Images.Media.getBitmap(contentResolver, imageUri);
                        if(command.has("absolutePosition")){
                            int position =  command.getInt("absolutePosition");
                            builder.appendBitmapWithAbsolutePosition(bitmap, diffusion, width, bothScale, rotation, position);
                        }else if(command.has("alignment")){
                            ICommandBuilder.AlignmentPosition alignmentPosition = getAlignment(command.getString("alignment"));
                            builder.appendBitmapWithAlignment(bitmap, diffusion, width, bothScale, rotation, alignmentPosition);
                        }else builder.appendBitmap(bitmap, diffusion, width, bothScale, rotation);
                    } catch (IOException e) {

                    }
                }
            }

        } catch (JSONException e) {

        }

    };

    //ICommandBuilder Constant Functions
    private ICommandBuilder.InternationalType getInternational(String international){
        if(international.equals("UK")) return ICommandBuilder.InternationalType.UK;
        else if (international.equals("USA")) return ICommandBuilder.InternationalType.USA;
        else if (international.equals("France")) return ICommandBuilder.InternationalType.France;
        else if (international.equals("Germany")) return ICommandBuilder.InternationalType.Germany;
        else if (international.equals("Denmark")) return ICommandBuilder.InternationalType.Denmark;
        else if (international.equals("Sweden")) return ICommandBuilder.InternationalType.Sweden;
        else if (international.equals("Italy")) return ICommandBuilder.InternationalType.Italy;
        else if (international.equals("Spain")) return ICommandBuilder.InternationalType.Spain;
        else if (international.equals("Japan")) return ICommandBuilder.InternationalType.Japan;
        else if (international.equals("Norway")) return ICommandBuilder.InternationalType.Norway;
        else if (international.equals("Denmark2")) return ICommandBuilder.InternationalType.Denmark2;
        else if (international.equals("Spain2")) return ICommandBuilder.InternationalType.Spain2;
        else if (international.equals("LatinAmerica")) return ICommandBuilder.InternationalType.LatinAmerica;
        else if (international.equals("Korea")) return ICommandBuilder.InternationalType.Korea;
        else if (international.equals("Ireland")) return ICommandBuilder.InternationalType.Ireland;
        else if (international.equals("Legal")) return ICommandBuilder.InternationalType.Legal;
        else return ICommandBuilder.InternationalType.USA;
    };

    private ICommandBuilder.AlignmentPosition getAlignment(String alignment){
        if(alignment.equals("Left")) return ICommandBuilder.AlignmentPosition.Left;
        else if(alignment.equals("Center")) return ICommandBuilder.AlignmentPosition.Center;
        else if(alignment.equals("Right")) return ICommandBuilder.AlignmentPosition.Right;
        else return ICommandBuilder.AlignmentPosition.Left;
    }

    private ICommandBuilder.BarcodeSymbology getBarcodeSymbology(String barcodeSymbology){
        if(barcodeSymbology.equals("Code128")) return ICommandBuilder.BarcodeSymbology.Code128;
        else if (barcodeSymbology.equals("Code39")) return ICommandBuilder.BarcodeSymbology.Code39;
        else if (barcodeSymbology.equals("Code93")) return ICommandBuilder.BarcodeSymbology.Code93;
        else if (barcodeSymbology.equals("ITF")) return ICommandBuilder.BarcodeSymbology.ITF;
        else if (barcodeSymbology.equals("JAN8")) return ICommandBuilder.BarcodeSymbology.JAN8;
        else if (barcodeSymbology.equals("JAN13")) return ICommandBuilder.BarcodeSymbology.JAN13;
        else if (barcodeSymbology.equals("NW7")) return ICommandBuilder.BarcodeSymbology.NW7;
        else if (barcodeSymbology.equals("UPCA")) return ICommandBuilder.BarcodeSymbology.UPCA;
        else if (barcodeSymbology.equals("UPCE")) return ICommandBuilder.BarcodeSymbology.UPCE;
        else return ICommandBuilder.BarcodeSymbology.Code128;
    }
    private ICommandBuilder.BarcodeWidth getBarcodeWidth (String barcodeWidth){
        if(barcodeWidth.equals("Mode1")) return ICommandBuilder.BarcodeWidth.Mode1;
        if(barcodeWidth.equals("Mode2")) return ICommandBuilder.BarcodeWidth.Mode2;
        if(barcodeWidth.equals("Mode3")) return ICommandBuilder.BarcodeWidth.Mode3;
        if(barcodeWidth.equals("Mode4")) return ICommandBuilder.BarcodeWidth.Mode4;
        if(barcodeWidth.equals("Mode5")) return ICommandBuilder.BarcodeWidth.Mode5;
        if(barcodeWidth.equals("Mode6")) return ICommandBuilder.BarcodeWidth.Mode6;
        if(barcodeWidth.equals("Mode7")) return ICommandBuilder.BarcodeWidth.Mode7;
        if(barcodeWidth.equals("Mode8")) return ICommandBuilder.BarcodeWidth.Mode8;
        if(barcodeWidth.equals("Mode9")) return ICommandBuilder.BarcodeWidth.Mode9;
        return ICommandBuilder.BarcodeWidth.Mode2;
    }
    private ICommandBuilder.FontStyleType getFontStyle(String fontStyle){
        if(fontStyle.equals("A")) return ICommandBuilder.FontStyleType.A;
        if(fontStyle.equals("B")) return ICommandBuilder.FontStyleType.B;
        return ICommandBuilder.FontStyleType.A;
    }
    private ICommandBuilder.LogoSize getLogoSize(String logoSize){
        if(logoSize.equals("Normal")) return ICommandBuilder.LogoSize.Normal;
        else if(logoSize.equals("DoubleWidth")) return ICommandBuilder.LogoSize.DoubleWidth;
        else if(logoSize.equals("DoubleHeight")) return ICommandBuilder.LogoSize.DoubleHeight;
        else if(logoSize.equals("DoubleWidthDoubleHeight")) return ICommandBuilder.LogoSize.DoubleWidthDoubleHeight;
        else return ICommandBuilder.LogoSize.Normal;
    }

    private ICommandBuilder.CutPaperAction getCutPaperAction(String cutPaperAction){
        if(cutPaperAction.equals("FullCut")) return CutPaperAction.FullCut;
        else if(cutPaperAction.equals("FullCutWithFeed")) return CutPaperAction.FullCutWithFeed;
        else if(cutPaperAction.equals("PartialCut")) return CutPaperAction.PartialCut;
        else if(cutPaperAction.equals("PartialCutWithFeed")) return CutPaperAction.PartialCutWithFeed;
        else return CutPaperAction.PartialCutWithFeed;
    }
    private ICommandBuilder.PeripheralChannel getPeripheralChannel(int peripheralChannel){
        if(peripheralChannel == 1) return ICommandBuilder.PeripheralChannel.No1;
        else if(peripheralChannel == 2) return ICommandBuilder.PeripheralChannel.No2;
        else return ICommandBuilder.PeripheralChannel.No1;
    }
    private ICommandBuilder.QrCodeModel getQrCodeModel (String qrCodeModel){
        if(qrCodeModel.equals("No1")) return ICommandBuilder.QrCodeModel.No1;
        else if(qrCodeModel.equals("No2")) return ICommandBuilder.QrCodeModel.No2;
        else return ICommandBuilder.QrCodeModel.No1;
    }
    private ICommandBuilder.QrCodeLevel getQrCodeLevel (String qrCodeLevel){
        if(qrCodeLevel.equals("H")) return ICommandBuilder.QrCodeLevel.H;
        else if(qrCodeLevel.equals("L")) return ICommandBuilder.QrCodeLevel.L;
        else if(qrCodeLevel.equals("M")) return ICommandBuilder.QrCodeLevel.M;
        else if(qrCodeLevel.equals("Q")) return ICommandBuilder.QrCodeLevel.Q;
        else return ICommandBuilder.QrCodeLevel.H;
    }
    private ICommandBuilder.BitmapConverterRotation getConverterRotation (String converterRotation){
        if(converterRotation.equals("Normal")) return ICommandBuilder.BitmapConverterRotation.Normal;
        else if(converterRotation.equals("Left90")) return ICommandBuilder.BitmapConverterRotation.Left90;
        else if(converterRotation.equals("Right90")) return ICommandBuilder.BitmapConverterRotation.Right90;
        else if(converterRotation.equals("Rotate180")) return ICommandBuilder.BitmapConverterRotation.Rotate180;
        else return ICommandBuilder.BitmapConverterRotation.Normal;
    }
    private ICommandBuilder.BlackMarkType getBlackMarkType(String blackMarkType){
        if(blackMarkType.equals("Valid")) return ICommandBuilder.BlackMarkType.Valid;
        else if(blackMarkType.equals("Invalid")) return ICommandBuilder.BlackMarkType.Invalid;
        else if(blackMarkType.equals("ValidWithDetection")) return ICommandBuilder.BlackMarkType.ValidWithDetection;
        else return ICommandBuilder.BlackMarkType.Valid;
    }
    private ICommandBuilder.CodePageType getCodePageType(String codePageType){
        if (codePageType.equals("CP437")) return CodePageType.CP437;
        else if (codePageType.equals("CP737")) return CodePageType.CP737;
        else if (codePageType.equals("CP772")) return CodePageType.CP772;
        else if (codePageType.equals("CP774")) return CodePageType.CP774;
        else if (codePageType.equals("CP851")) return CodePageType.CP851;
        else if (codePageType.equals("CP852")) return CodePageType.CP852;
        else if (codePageType.equals("CP855")) return CodePageType.CP855;
        else if (codePageType.equals("CP857")) return CodePageType.CP857;
        else if (codePageType.equals("CP858")) return CodePageType.CP858;
        else if (codePageType.equals("CP860")) return CodePageType.CP860;
        else if (codePageType.equals("CP861")) return CodePageType.CP861;
        else if (codePageType.equals("CP862")) return CodePageType.CP862;
        else if (codePageType.equals("CP863")) return CodePageType.CP863;
        else if (codePageType.equals("CP864")) return CodePageType.CP864;
        else if (codePageType.equals("CP865")) return CodePageType.CP866;
        else if (codePageType.equals("CP869")) return CodePageType.CP869;
        else if (codePageType.equals("CP874")) return CodePageType.CP874;
        else if (codePageType.equals("CP928")) return CodePageType.CP928;
        else if (codePageType.equals("CP932")) return CodePageType.CP932;
        else if (codePageType.equals("CP999")) return CodePageType.CP999;
        else if (codePageType.equals("CP1001")) return CodePageType.CP1001;
        else if (codePageType.equals("CP1250")) return CodePageType.CP1250;
        else if (codePageType.equals("CP1251")) return CodePageType.CP1251;
        else if (codePageType.equals("CP1252")) return CodePageType.CP1252;
        else if (codePageType.equals("CP2001")) return CodePageType.CP2001;
        else if (codePageType.equals("CP3001")) return CodePageType.CP3001;
        else if (codePageType.equals("CP3002")) return CodePageType.CP3002;
        else if (codePageType.equals("CP3011")) return CodePageType.CP3011;
        else if (codePageType.equals("CP3012")) return CodePageType.CP3012;
        else if (codePageType.equals("CP3021")) return CodePageType.CP3021;
        else if (codePageType.equals("CP3041")) return CodePageType.CP3041;
        else if (codePageType.equals("CP3840")) return CodePageType.CP3840;
        else if (codePageType.equals("CP3841")) return CodePageType.CP3841;
        else if (codePageType.equals("CP3843")) return CodePageType.CP3843;
        else if (codePageType.equals("CP3845")) return CodePageType.CP3845;
        else if (codePageType.equals("CP3846")) return CodePageType.CP3846;
        else if (codePageType.equals("CP3847")) return CodePageType.CP3847;
        else if (codePageType.equals("CP3848")) return CodePageType.CP3848;
        else if (codePageType.equals("UTF8")) return CodePageType.UTF8;
        else if (codePageType.equals("Blank")) return CodePageType.Blank;
        else return CodePageType.CP998;
    }


    //Helper functions

    private Charset getEncoding(String encoding){

        if (encoding.equals("US-ASCII")) return Charset.forName("US-ASCII"); //English
        else if (encoding.equals("Windows-1252")){
            try {
                return Charset.forName("Windows-1252"); //French, German, Portuguese, Spanish
            }
            catch (UnsupportedCharsetException e) { //not supported using UTF-8 Instead
                return Charset.forName("UTF-8");
            }
        }
        else if (encoding.equals("Shift-JIS")) {
            try {
                return Charset.forName("Shift-JIS"); //Japanese
            }
            catch (UnsupportedCharsetException e) { //not supported using UTF-8 Instead
                return Charset.forName("UTF-8");
            }
        }
        else if (encoding.equals("Windows-1251")){
            try {
                return Charset.forName("Windows-1251"); //Russian
            }
            catch (UnsupportedCharsetException e) { //not supported using UTF-8 Instead
                return Charset.forName("UTF-8");
            }
        }
        else if (encoding.equals("GB2312")) {
            try {
                return Charset.forName("GB2312"); // Simplified Chinese
            }
            catch (UnsupportedCharsetException e) { //not supported using UTF-8 Instead
                return Charset.forName("UTF-8");
            }
        }
        else if (encoding.equals("Big5")) {
            try {
                return Charset.forName("Big5"); // Traditional Chinese
            }
            catch (UnsupportedCharsetException e) { //not supported using UTF-8 Instead
                return Charset.forName("UTF-8");
            }
        }
        else if (encoding.equals("UTF-8")) return Charset.forName("UTF-8"); // UTF-8
        else return Charset.forName("US-ASCII");
    }

    private byte[] createCpUTF8(String inputText) {
        byte[] byteBuffer = null;

        try {
            byteBuffer = inputText.getBytes("UTF-8");
        } catch (UnsupportedEncodingException e) {
            byteBuffer = inputText.getBytes();
        }

        return byteBuffer;
    }


    private byte[] convertFromListByteArrayTobyteArray(List<byte[]> ByteArray) {
        int dataLength = 0;
        for (int i = 0; i < ByteArray.size(); i++) {
            dataLength += ByteArray.get(i).length;
        }

        int distPosition = 0;
        byte[] byteArray = new byte[dataLength];
        for (int i = 0; i < ByteArray.size(); i++) {
            System.arraycopy(ByteArray.get(i), 0, byteArray, distPosition, ByteArray.get(i).length);
            distPosition += ByteArray.get(i).length;
        }

        return byteArray;
    }

    /**
     * Create a new plugin result and send it back to JavaScript
     *
     * @param dataType event type
     */
    private void sendEvent(String dataType, String info) {
        if (this._callbackContext != null) {
            JSONObject status = new JSONObject();
            try {
                status.put("dataType", dataType);
                if (info != null) status.put("data", info);
            }catch (JSONException ex ) {  };
            PluginResult result = new PluginResult(PluginResult.Status.OK, status);
            result.setKeepCallback(true);
            this._callbackContext.sendPluginResult(result);
        }
    }
    private StarIoExtManagerListener starIoExtManagerListener = new StarIoExtManagerListener() {
        @Override
        public void onPrinterImpossible() {
            sendEvent("printerImpossible", null);
        }

        @Override
        public void onPrinterOnline() {
            sendEvent("printerOnline", null);
        }

        @Override
        public void onPrinterOffline() {
           sendEvent("printerOffline", null);
        }

        @Override
        public void onPrinterPaperReady() {
            sendEvent("printerPaperReady", null);
        }

        @Override
        public void onPrinterPaperNearEmpty() {
            sendEvent("printerPaperNearEmpty", null);
        }

        @Override
        public void onPrinterPaperEmpty() {
            sendEvent("printerPaperEmpty", null);
        }

        @Override
        public void onPrinterCoverOpen() {
            sendEvent("printerCoverOpen", null);
        }

        @Override
        public void onPrinterCoverClose() {
            sendEvent("printerCoverClose", null);
        }

        //Cash Drawer events
        @Override
        public void onCashDrawerOpen() {
            sendEvent("cashDrawerOpen", null);
        }

        @Override
        public void onCashDrawerClose() {
            sendEvent("cashDrawerClose", null);
        }

        @Override
        public void onBarcodeReaderImpossible() {
            sendEvent("barcodeReaderImpossible", null);
        }

        @Override
        public void onBarcodeReaderConnect() {
            sendEvent("barcodeReaderConnect", null);
        }

        @Override
        public void onBarcodeReaderDisconnect() {
            sendEvent("barcodeReaderDisconnect", null);
        }

        @Override
        public void onBarcodeDataReceive(byte[] data) {
            sendEvent("barcodeDataReceive", new String(data));
        }

    };

    private Bitmap createBitmapFromText(String printText, int textSize, int printWidth, Typeface typeface) {
        Paint paint = new Paint();
        Bitmap bitmap;
        Canvas canvas;

        paint.setTextSize(textSize);
        paint.setTypeface(typeface);

        paint.getTextBounds(printText, 0, printText.length(), new Rect());

        TextPaint textPaint = new TextPaint(paint);
        android.text.StaticLayout staticLayout = new StaticLayout(printText, textPaint, printWidth, Layout.Alignment.ALIGN_NORMAL, 1, 0, false);

        // Create bitmap
        bitmap = Bitmap.createBitmap(staticLayout.getWidth(), staticLayout.getHeight(), Bitmap.Config.ARGB_8888);

        // Create canvas
        canvas = new Canvas(bitmap);
        canvas.drawColor(Color.WHITE);
        canvas.translate(0, 0);
        staticLayout.draw(canvas);

        return bitmap;
    }


}