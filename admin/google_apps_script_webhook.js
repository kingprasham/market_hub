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

var CRON_SECRET = "mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC";
var WEBHOOK_URL = "https://mehrgrewal.com/markethub/api/spot_price_monitor.php?key=" + CRON_SECRET;

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
    // If we just edited Hindi News (ALL_INDIA_MSG), we don't need to push prices
    // NOTE: "FOR APP" is the non-ferrous price sheet and MUST trigger notifications
    if (editedSheetName === "ALL_INDIA_MSG") {
      return; // App will detect news change via _timestamps above
    }

    // Wait for Sheets to finish recalculating formulas before reading values
    // (Google Sheets has a ~3s sync delay after edits; without this sleep we
    //  capture the old formula results and detect no price change)
    Utilities.sleep(3000);

    // Grab the LIVE data array from the EDITED sheet instantly
    var gridData = editedSheet.getDataRange().getValues();

    // Map sheet names to the types expected by spot_price_monitor.php
    var sheetTypeMap = {
      "FOR APP STOCK-SETTELMENT-SBI-RBI": "app_unified",
      "FOR APP": "non_ferrous",
      "FOR APP MINOR & FERRO": "key_value",
      "Steel": "key_value"
    };

    var sheetType = sheetTypeMap[editedSheetName] || "non_ferrous";

    // For non_ferrous sheet: detect which city was edited so PHP can filter
    // changes to only that city (prevents formula-cascaded changes in other cities
    // from appearing in the notification, e.g. Delhi edit showing Chennai rates).
    var filterCity = '';
    if (sheetType === 'non_ferrous' && e.range) {
      var editedCol = e.range.columnStart - 1; // convert to 0-indexed
      var colCityMap = {
        0: 'DELHI',      1: 'DELHI',
        4: 'MUMBAI',     5: 'MUMBAI',
        7: 'HYDERABAD',  8: 'HYDERABAD',
        10: 'AHMEDABAD', 11: 'AHMEDABAD',
        13: 'PUNE',      14: 'PUNE',
        16: 'CHENNAI',   17: 'CHENNAI',
        19: 'JODHPUR',   20: 'JODHPUR',
        22: 'KOLKATA',   23: 'KOLKATA',
        25: 'JAMNAGAR',  26: 'JAMNAGAR',
        28: 'JAGADHRI',  29: 'JAGADHRI',
        31: 'MORADABAD', 32: 'MORADABAD',
        34: 'HATHRAS',   35: 'HATHRAS',
        37: 'JALANDHAR', 38: 'JALANDHAR',
        40: 'BME',       41: 'BME'
      };
      filterCity = colCityMap[editedCol] || '';
    }

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
      "sheet_type": sheetType,
      "csv_data": csvLines.join("\n"),
      "filter_city": filterCity
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
