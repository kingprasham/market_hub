// =========================================================================
// INSTANT PUSH WEBHOOK FOR MARKET HUB (Non-Ferrous Sheet)
// =========================================================================
// REPLACE your entire current Apps Script with this code.
// This version bypasses Google's slow CSV cache by instantly extracting
// the live data from the "FOR APP" tab and pushing it securely to your server.

var WEBHOOK_URL = "https://mehrgrewal.com/markethub/api/spot_price_monitor.php";
var CRON_SECRET = "mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC";

// ─── Main Trigger ────────────────────────────────────────────────
function onSheetEdit(e) {
  try {
    var editedSheet = e.source.getActiveSheet();
    var editedSheetName = editedSheet.getName();

    // Ignore edits on the FOR APP tab itself, we only care about source data tabs (e.g. DELHI)
    if (editedSheetName === "FOR APP" || editedSheetName === "ALL_INDIA_MSG") return;

    // Use PropertiesService to debounce rapid consecutive edits (like when typing 3 numbers fast)
    var now = new Date().getTime();
    var properties = PropertiesService.getScriptProperties();
    properties.setProperty('lastEditTime', now.toString());

    // Wait 2.5 seconds to let the user finish their fast edits and formulas to calculate
    Utilities.sleep(2500);
    
    // Only the last edit will trigger the push
    var lastEdit = parseInt(properties.getProperty('lastEditTime') || "0", 10);
    if (now === lastEdit) {
      _executeWebhookPush();
    }

  } catch (err) {
    console.error("Error in onSheetEdit: " + err.toString());
  }
}

// ─── Execute POST Push ───────────────────────────────────────────
function _executeWebhookPush() {
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var forAppSheet = ss.getSheetByName("FOR APP");
    
    if (!forAppSheet) {
      console.error("Could not find 'FOR APP' tab!");
      return;
    }
    
    // Force spreadsheet to calculate all cross-sheet formulas immediately!
    SpreadsheetApp.flush();
    
    // Grab the LIVE data array from the FOR APP tab instantly (0 seconds delay)
    var data = forAppSheet.getDataRange().getValues();
    
    // Convert the 2D array to a CSV string to stay perfectly compatible with the PHP parser
    var csvLines = [];
    for (var i = 0; i < data.length; i++) {
       var rowStr = data[i].map(function(cell) {
           var str = String(cell);
           // Simple CSV escaping for commas or quotes
           if (str.indexOf(',') !== -1 || str.indexOf('"') !== -1 || str.indexOf('\n') !== -1) {
               str = '"' + str.replace(/"/g, '""') + '"';
           }
           return str;
       });
       csvLines.push(rowStr.join(","));
    }
    var finalCsvString = csvLines.join("\n");
    
    // Build the POST payload
    var payload = {
      "key": CRON_SECRET,
      "sheet_type": "non_ferrous",
      "csv_data": finalCsvString
    };
    
    var options = {
      "method": "post",
      "payload": payload,
      "muteHttpExceptions": true
    };
    
    console.log("Pushing LIVE CSV data to webhook...");
    var response = UrlFetchApp.fetch(WEBHOOK_URL, options);
    console.log("Webhook Response: " + response.getContentText());
    
  } catch (err) {
    console.error("Error pushing webhook: " + err.toString());
  }
}
