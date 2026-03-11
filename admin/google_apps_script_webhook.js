/**
 * Google Apps Script – Per-Cell Timestamp Tracker for Market Hub Spot Prices
 *
 * PURPOSE:
 * Records the exact date & time when ANY price cell is edited in the spot
 * price sheets (Non-Ferrous, Minor & Ferro, Steel). The app can then read
 * a designated "Last Updated" cell to show accurate per-sheet timestamps.
 *
 * INSTALL:
 *   1. Open the Non-Ferrous Google Sheet
 *      (https://docs.google.com/spreadsheets/d/1VrCzC-sDcri5hO_TWfpHGx3ua7iaScLAtf-CFwQYBsI)
 *   2. Go to Extensions → Apps Script
 *   3. Delete any existing code and paste this entire file
 *   4. Click the clock icon (Triggers) → Add Trigger:
 *        Function: onSheetEdit
 *        Event source: From spreadsheet
 *        Event type: On edit
 *   5. Save and authorize when prompted
 *
 * HOW IT WORKS:
 * - On every cell edit, it writes the current timestamp to cell A1 of a
 *   hidden sheet called "_timestamps" (auto-created if missing).
 * - Format: "dd-MM-yyyy HH:mm:ss" in IST (Asia/Kolkata).
 * - It also optionally calls the spot_price_monitor webhook for push
 *   notifications (with a 30-second debounce).
 */

// ─── Configuration ───────────────────────────────────────────────
var TIMESTAMP_SHEET_NAME = "_timestamps";
var TIMEZONE = "Asia/Kolkata";
var DATE_FORMAT = "dd-MM-yyyy HH:mm:ss";

// Webhook (same as the previous script — for push notification triggers)
var WEBHOOK_URL = "https://mehrgrewal.com/markethub/api/spot_price_monitor.php";
var CRON_SECRET = "mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC";
var MIN_INTERVAL_SECONDS = 30;

// ─── Main Trigger ────────────────────────────────────────────────
function onSheetEdit(e) {
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var editedSheet = e.source.getActiveSheet();
    var editedSheetName = editedSheet.getName();

    // Skip if editing the timestamp sheet itself
    if (editedSheetName === TIMESTAMP_SHEET_NAME) return;

    var now = new Date();
    var formattedTime = Utilities.formatDate(now, TIMEZONE, DATE_FORMAT);

    // ── Write timestamp to _timestamps sheet ──
    var tsSheet = ss.getSheetByName(TIMESTAMP_SHEET_NAME);
    if (!tsSheet) {
      tsSheet = ss.insertSheet(TIMESTAMP_SHEET_NAME);
      // Set up headers
      tsSheet.getRange("A1").setValue("Sheet Name");
      tsSheet.getRange("B1").setValue("Last Updated");
      tsSheet.getRange("C1").setValue("Cell Edited");
      tsSheet.getRange("D1").setValue("Global Last Updated");
      // Hide the sheet so users don't accidentally edit it
      tsSheet.hideSheet();
    }

    // Find or create a row for this sheet name
    var data = tsSheet.getDataRange().getValues();
    var rowIndex = -1;
    for (var i = 1; i < data.length; i++) {
      if (data[i][0] === editedSheetName) {
        rowIndex = i + 1; // 1-indexed
        break;
      }
    }

    var editedCell = e.range ? e.range.getA1Notation() : "unknown";

    if (rowIndex === -1) {
      // Append new row
      var newRow = data.length + 1;
      tsSheet.getRange(newRow, 1).setValue(editedSheetName);
      tsSheet.getRange(newRow, 2).setValue(formattedTime);
      tsSheet.getRange(newRow, 3).setValue(editedCell);
    } else {
      // Update existing row
      tsSheet.getRange(rowIndex, 2).setValue(formattedTime);
      tsSheet.getRange(rowIndex, 3).setValue(editedCell);
    }

    // Always update Global Last Updated in D1
    tsSheet.getRange("D2").setValue(formattedTime);

    Logger.log("Timestamp updated for sheet: " + editedSheetName + " at " + formattedTime);

    // ── Optionally trigger webhook (debounced) ──
    _callWebhookDebounced(now);

  } catch (err) {
    Logger.log("Error in onSheetEdit: " + err.message);
  }
}

// ─── Debounced Webhook Call ──────────────────────────────────────
function _callWebhookDebounced(now) {
  try {
    var props = PropertiesService.getScriptProperties();
    var lastCall = parseInt(props.getProperty("lastWebhookCall") || "0", 10);
    var nowSeconds = Math.floor(now.getTime() / 1000);

    if (nowSeconds - lastCall < MIN_INTERVAL_SECONDS) {
      Logger.log("Webhook skipped (debounce: " + (nowSeconds - lastCall) + "s ago)");
      return;
    }

    var url = WEBHOOK_URL + "?key=" + CRON_SECRET;
    var response = UrlFetchApp.fetch(url, {
      method: "get",
      muteHttpExceptions: true,
      followRedirects: true,
    });

    props.setProperty("lastWebhookCall", String(nowSeconds));
    Logger.log("Webhook called: HTTP " + response.getResponseCode());
  } catch (err) {
    Logger.log("Webhook error: " + err.message);
  }
}

// ─── Manual Test ─────────────────────────────────────────────────
// Run this from the Apps Script editor to verify everything works
function testTimestamp() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var fakeEvent = {
    source: ss,
    range: ss.getActiveSheet().getRange("A1"),
  };
  // Simulate source.getActiveSheet()
  fakeEvent.source.getActiveSheet = function() {
    return ss.getSheets()[0];
  };
  onSheetEdit(fakeEvent);
  Logger.log("Test complete. Check _timestamps sheet.");
}
