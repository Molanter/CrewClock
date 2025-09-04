//
//  GoogleSheets functions.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/2/25.
//

//// functions/sheets.js
//// Reusable Google Sheets helpers for Firebase Functions (Node.js 18+)
//
//const { google } = require("googleapis");
//const { GoogleAuth } = require("google-auth-library");
//
//// Scopes needed for Sheets read/write
//const SHEETS_SCOPES = ["https://www.googleapis.com/auth/spreadsheets"];
//
///**
// * Get an authenticated Google Sheets client using the Cloud Functions
// * service account credentials (recommended).
// */
//async function getSheetsClient() {
//  const auth = new GoogleAuth({ scopes: SHEETS_SCOPES });
//  const sheets = google.sheets({ version: "v4", auth });
//  return sheets;
//}
//
///**
// * Read a range (e.g., "Sheet1!A1:D50").
// * Returns a 2D array of values (rows of arrays). Empty cells may be undefined.
// */
//async function readRange(spreadsheetId, range, valueRenderOption = "UNFORMATTED_VALUE") {
//  const sheets = await getSheetsClient();
//  const res = await sheets.spreadsheets.values.get({
//    spreadsheetId,
//    range,
//    valueRenderOption, // "FORMATTED_VALUE" | "UNFORMATTED_VALUE" | "FORMULA"
//  });
//  return res.data.values || [];
//}
//
///**
// * Append a row (array of values) at the end of the sheet.
// * range can be "Sheet1!A1" (only sheet name matters for append).
// */
//async function appendRow(spreadsheetId, range, rowValues, valueInputOption = "USER_ENTERED") {
//  const sheets = await getSheetsClient();
//  const res = await sheets.spreadsheets.values.append({
//    spreadsheetId,
//    range,
//    valueInputOption, // "RAW" | "USER_ENTERED"
//    insertDataOption: "INSERT_ROWS",
//    requestBody: { values: [rowValues] },
//  });
//  return res.data;
//}
//
///**
// * Overwrite values in a specific range with a 2D array (rows x cols).
// * range like "Sheet1!A2:D2"
// */
//async function updateRange(spreadsheetId, range, values2D, valueInputOption = "USER_ENTERED") {
//  const sheets = await getSheetsClient();
//  const res = await sheets.spreadsheets.values.update({
//    spreadsheetId,
//    range,
//    valueInputOption,
//    requestBody: { values: values2D },
//  });
//  return res.data;
//}
//
///**
// * Batch update multiple ranges at once.
// * updates = [{ range: "Sheet1!A2:B2", values: [["x","y"]] }, ...]
// */
//async function batchUpdateValues(spreadsheetId, updates, valueInputOption = "USER_ENTERED") {
//  const sheets = await getSheetsClient();
//  const res = await sheets.spreadsheets.values.batchUpdate({
//    spreadsheetId,
//    requestBody: {
//      valueInputOption,
//      data: updates.map(u => ({ range: u.range, values: u.values })),
//    },
//  });
//  return res.data;
//}
//
///**
// * Ensure a sheet (tab) exists by title; if not, create it.
// * Returns the sheetId (gid).
// */
//async function ensureSheet(spreadsheetId, sheetTitle) {
//  const sheets = await getSheetsClient();
//
//  // Get spreadsheet metadata
//  const meta = await sheets.spreadsheets.get({ spreadsheetId });
//  const existing = meta.data.sheets?.find(s => s.properties?.title === sheetTitle);
//
//  if (existing) return existing.properties.sheetId;
//
//  // Add sheet
//  const addRes = await sheets.spreadsheets.batchUpdate({
//    spreadsheetId,
//    requestBody: {
//      requests: [{
//        addSheet: { properties: { title: sheetTitle } }
//      }]
//    }
//  });
//
//  const sheetId = addRes.data.replies?.[0]?.addSheet?.properties?.sheetId;
//  return sheetId;
//}
//
///**
// * Find the first row index (1-based, including header) where a given column equals value.
// * Example: findRowByValue(id, "Sheet1", 1, "ABC123") -> returns row number or -1 if not found.
// */
//async function findRowByValue(spreadsheetId, sheetTitle, columnIndex1Based, matchValue) {
//  const colLetter = columnToLetter(columnIndex1Based);
//  const range = `${sheetTitle}!${colLetter}:${colLetter}`; // whole column
//  const values = await readRange(spreadsheetId, range);
//  for (let i = 0; i < values.length; i++) {
//    const cell = values[i]?.[0];
//    if (String(cell) === String(matchValue)) return i + 1; // convert to 1-based row
//  }
//  return -1;
//}
//
///**
// * Upsert (update or append) a row based on a key column match.
// * - If a row in keyColumnIndex1Based equals keyValue, update that row with newValues (starting at startColumnIndex1Based).
// * - Otherwise, append a new row.
// * Returns { action: "updated"|"appended", rowNumber }.
// */
//async function upsertRow({
//  spreadsheetId,
//  sheetTitle,
//  keyColumnIndex1Based,
//  keyValue,
//  startColumnIndex1Based = 1,
//  newValues,
//}) {
//  const rowNumber = await findRowByValue(spreadsheetId, sheetTitle, keyColumnIndex1Based, keyValue);
//  if (rowNumber > 0) {
//    // Update existing row
//    const startCol = columnToLetter(startColumnIndex1Based);
//    const endCol = columnToLetter(startColumnIndex1Based + newValues.length - 1);
//    const range = `${sheetTitle}!${startCol}${rowNumber}:${endCol}${rowNumber}`;
//    await updateRange(spreadsheetId, range, [newValues]);
//    return { action: "updated", rowNumber };
//  } else {
//    // Append new row
//    await appendRow(spreadsheetId, `${sheetTitle}!A1`, newValues);
//    // Not trivial to know the row number without re-reading; return appended.
//    return { action: "appended", rowNumber: null };
//  }
//}
//
///**
// * Delete a row by number (1-based).
// */
//async function deleteRowByIndex(spreadsheetId, sheetTitle, rowNumber1Based) {
//  const sheets = await getSheetsClient();
//  // Need sheetId for dimension delete
//  const meta = await sheets.spreadsheets.get({ spreadsheetId });
//  const sheet = meta.data.sheets?.find(s => s.properties?.title === sheetTitle);
//  if (!sheet) throw new Error(`Sheet "${sheetTitle}" not found`);
//
//  const sheetId = sheet.properties.sheetId;
//
//  const res = await sheets.spreadsheets.batchUpdate({
//    spreadsheetId,
//    requestBody: {
//      requests: [{
//        deleteDimension: {
//          range: {
//            sheetId,
//            dimension: "ROWS",
//            startIndex: rowNumber1Based - 1, // 0-based inclusive
//            endIndex: rowNumber1Based,       // 0-based exclusive
//          }
//        }
//      }]
//    }
//  });
//
//  return res.data;
//}
//
///** Helpers */
//function columnToLetter(n) {
//  let s = "";
//  while (n > 0) {
//    const mod = (n - 1) % 26;
//    s = String.fromCharCode(65 + mod) + s;
//    n = Math.floor((n - mod) / 26);
//  }
//  return s;
//}
//
//module.exports = {
//  getSheetsClient,
//  readRange,
//  appendRow,
//  updateRange,
//  batchUpdateValues,
//  ensureSheet,
//  findRowByValue,
//  upsertRow,
//  deleteRowByIndex,
//  columnToLetter,
//};
