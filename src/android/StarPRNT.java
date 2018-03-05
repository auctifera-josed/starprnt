package starprnt.cordova;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;


import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Locale;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


import com.starmicronics.stario.PortInfo;
import com.starmicronics.stario.StarIOPort;
import com.starmicronics.stario.StarIOPortException;
import com.starmicronics.stario.StarPrinterStatus;
import com.starmicronics.starioextension.StarIoExt;
import com.starmicronics.starioextension.StarIoExt.Emulation;
import com.starmicronics.starioextension.ICommandBuilder;
import com.starmicronics.starioextension.ICommandBuilder.CutPaperAction;

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

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if(_callbackContext == null){
            _callbackContext = callbackContext;
        }

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
            port.put("portName", discovery.getPortName());

            if (!discovery.getMacAddress().equals("")) {

                port.put("macAddress", discovery.getMacAddress());

                if (!discovery.getModelName().equals("")) {
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
        else return Emulation.None;
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


    private void printRawText(String portName, String portSettings, Emulation emulation, String printObj, CallbackContext callbackContext) throws JSONException {

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
                            builder.append(new byte[]{0x07}); // Kick cash drawer
                        }

                        builder.endDocument();

                        byte[] commands = builder.getCommands();


                        sendCommand(context, _portName, _portSettings, commands, _callbackContext);
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
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool()
                .execute(new Runnable() {
                    public void run() {

                        Typeface typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL);

                        ICommandBuilder builder = StarIoExt.createCommandBuilder(_emulation);

                        builder.beginDocument();

                        Bitmap image = createBitmapFromText(text, fontSize, paperWidth, typeface);

                        builder.appendBitmap(image, false);

                        builder.appendCutPaper(CutPaperAction.PartialCutWithFeed);

                        builder.endDocument();

                        byte[] commands = builder.getCommands();


                        sendCommand(context, _portName, _portSettings, commands, _callbackContext);
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

                        builder.appendCutPaper(CutPaperAction.PartialCutWithFeed);

                        builder.endDocument();

                        byte[] commands = builder.getCommands();


                        sendCommand(context, _portName, _portSettings, commands, _callbackContext);
                    }
                });
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
                sendEvent("printerOffline", null);
                return false;
            }

            port.writePort(commands, 0, commands.length);


            port.setEndCheckedBlockTimeoutMillis(30000);// Change the timeout time of endCheckedBlock method.
            status = port.endCheckedBlock();

            if (status.coverOpen) {
                callbackContext.error("Cover open");
                sendEvent("printerCoverOpen", null);
                return false;
            } else if (status.receiptPaperEmpty) {
                callbackContext.error("Empty paper");
                sendEvent("printerPaperEmpty", null);
                return false;
            } else if (status.offline) {
                callbackContext.error("Printer offline");
                sendEvent("printerOffline", null);
                return false;
            }
            callbackContext.success("Success!");

        } catch (StarIOPortException e) {
            sendEvent("printerImpossible", e.getMessage());
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
            PluginResult result = new PluginResult(PluginResult.Status.OK, info);
            result.setKeepCallback(true);
            this._callbackContext.sendPluginResult(result);
        }
    }

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



