/**
 * Google Apps Script – Per-Cell Timestamp Tracker & Instant Webhook
 *
 * This script combines the original Timestamp logic (required for the
 * app to show new Hindi News) with the NEW Instant Push logic (for
 * instant 0-second price notifications).
 */

var TIMESTAMP_SHEET_NAME = "_timestamps";
var TIMEZONE = "Asia/Kolkata";
var DATE_FORMAT = "dd-MM-yyyy HH:mm:ss";

var WEBHOOK_URL = "https://mehrgrewal.com/markethub/api/spot_price_monitor.php";
var CRON_SECRET = "mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC";

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

    // ─── 1. Write timestamp to _timestamps sheet (Restored) ───
    // This is required so the Mobile App knows there's new News or Prices
    var tsSheet = ss.getSheetByName(TIMESTAMP_SHEET_NAME);
    if (!tsSheet) {
      tsSheet = ss.insertSheet(TIMESTAMP_SHEET_NAME);
      tsSheet.getRange("A1").setValue("Sheet Name");
      tsSheet.getRange("B1").setValue("Last Updated");
      tsSheet.getRange("C1").setValue("Cell Edited");
      tsSheet.getRange("D1").setValue("Global Last Updated");
      tsSheet.hideSheet();
    }

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

    // Always update Global Last Updated in D2
    tsSheet.getRange("D2").setValue(formattedTime);
    // ────────────────────────────────────────────────────────

    // ─── 2. Instant Webhook Push for Prices ───
    // If we just edited Hindi News (ALL_INDIA_MSG) or FOR APP, we don't need to push prices
    if (editedSheetName === "FOR APP" || editedSheetName === "ALL_INDIA_MSG") {
      return; // App will detect news change via _timestamps above
    }

    var forAppSheet = ss.getSheetByName("FOR APP");
    if (!forAppSheet) return;

    // Force spreadsheet to calculate all cross-sheet formulas immediately
    SpreadsheetApp.flush();

    // Grab the LIVE data array from the FOR APP tab instantly
    var gridData = forAppSheet.getDataRange().getValues();

    // Convert 2D array to CSV string
    var csvLines = [];
    for (var i = 0; i < gridData.length; i++) {
      var rowStr = gridData[i].map(function (cell) {
        var str = String(cell);
        // Simple CSV escaping
        if (str.indexOf(',') !== -1 || str.indexOf('"') !== -1 || str.indexOf('\n') !== -1) {
          str = '"' + str.replace(/"/g, '""') + '"';
        }
        return str;
      });
      csvLines.push(rowStr.join(","));
    }

    // Build POST payload
    var payload = {
      "key": CRON_SECRET,
      "sheet_type": "non_ferrous",
      "csv_data": csvLines.join("\n")
    };

    var options = {
      "method": "post",
      "payload": payload,
      "muteHttpExceptions": true
    };

    // Push instantly
    UrlFetchApp.fetch(WEBHOOK_URL, options);

  } catch (err) {
    console.error(err.toString());
  }
}
