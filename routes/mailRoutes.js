const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

/**
 * POST /mail/send-profit-report
 * Sends profit report via email using Gmail SMTP
 * Generates an account statement Excel file with revenue and expense breakdown
 * 
 * Fetches fresh data from database using get_profittomail function
 * 
 * Setup Instructions:
 * 1. Enable 2-Step Verification on your Gmail account
 * 2. Visit https://myaccount.google.com/apppasswords
 * 3. Select "Mail" and "Windows Computer" to generate App Password
 * 4. Copy the 16-character App Password
 * 5. Update .env file:
 *    EMAIL_USER=your_gmail@gmail.com
 *    EMAIL_PASSWORD=your_16_char_app_password
 * 6. Restart server and try sending email
 * 7. Check your Gmail inbox for received emails
 */
router.post('/send-profit-report', async (req, res) => {
  const { selectedDate, recipientEmail } = req.body;

  let excelFilePath = null;

  try {
    const emailUser = process.env.EMAIL_USER;
    const emailPassword = process.env.EMAIL_PASSWORD;
    
    console.log('\n=== POST /mail/send-profit-report API called ===');
    console.log('Request body:', req.body);
    
    if (!emailUser || !emailPassword) {
      console.error('❌ EMAIL_USER or EMAIL_PASSWORD not set in .env');
      return res.status(400).json({ 
        error: 'Email service not configured',
        details: 'Gmail credentials missing from .env',
        setup: 'Add EMAIL_USER and EMAIL_PASSWORD (Gmail App Password) to .env file'
      });
    }

    if (!selectedDate) {
      console.error('❌ selectedDate is missing');
      return res.status(400).json({ 
        error: 'Invalid request',
        details: 'selectedDate is required',
        received: { selectedDate, recipientEmail }
      });
    }

    if (!recipientEmail) {
      console.error('❌ recipientEmail is missing');
      return res.status(400).json({ 
        error: 'Invalid request',
        details: 'recipientEmail is required',
        received: { selectedDate, recipientEmail }
      });
    }

    // Parse date to YYYY-MM-DD format
    let dateForQuery = selectedDate;
    if (selectedDate instanceof Date) {
      dateForQuery = selectedDate.toISOString().split('T')[0];
    } else if (typeof selectedDate === 'string') {
      // If it's an ISO string like "2026-04-15T00:00:00.000Z", extract date part
      if (selectedDate.includes('T')) {
        dateForQuery = selectedDate.split('T')[0];
      }
      // If it's already in YYYY-MM-DD format, use as is
      // If it's a date string like "Mon Apr 15 2026...", parse it
      else if (!selectedDate.match(/^\d{4}-\d{2}-\d{2}$/)) {
        dateForQuery = new Date(selectedDate).toISOString().split('T')[0];
      }
    }

    const reportDate = new Date(dateForQuery).toLocaleDateString('en-IN');
    console.log(`📧 Using Ethereal Email: ${emailUser}`);
    console.log(`📊 Original date received: ${selectedDate}`);
    console.log(`📊 Parsed date for query: ${dateForQuery}`);
    console.log(`📊 Fetching profit data for date: ${reportDate} from database...`);

    // ==========================================
    // STEP 1: Fetch Fresh Data from Database
    // ==========================================
    const dbUrl = `http://localhost:${process.env.PORT || 3000}/profit/email/${dateForQuery}`;
    console.log(`📂 Calling internal API: ${dbUrl}`);
    
    let profitData = [];
    try {
      const response = await axios.get(dbUrl);
      profitData = response.data || [];
      console.log(`✓ Fetched ${profitData.length} record(s) from database`);
    } catch (dbErr) {
      console.error('❌ Failed to fetch profit data from database:', dbErr.message);
      return res.status(500).json({
        error: 'Failed to fetch profit data',
        details: dbErr.message,
        hint: 'Ensure the profit API endpoint is accessible'
      });
    }

    if (!profitData || profitData.length === 0) {
      return res.status(400).json({
        error: 'No profit data found',
        details: `No profit records found for date: ${reportDate}`,
        selectedDate: selectedDate
      });
    }

    console.log(`📊 Generating Excel for date: ${reportDate}`);
    console.log(`📊 Data structure received:`, {
      totalRecords: profitData.length,
      sampleRecord: profitData[0]
    });

    // ==========================================
    // STEP 2: Generate Account Statement Excel
    // Account Format: Fish Names/Revenue on LEFT | Expense Categories on RIGHT
    // ==========================================
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Account Statement');

    // Set column widths - date + 2 columns for revenue side, spacer, 2 columns for expense side
    worksheet.columns = [
      { header: 'Date', key: 'statementDate', width: 12 },
      { header: 'Fish Name', key: 'fishName', width: 20 },
      { header: 'Revenue (₹)', key: 'fishRevenue', width: 15 },
      { header: '', key: 'spacer1', width: 2 },
      { header: 'Expense Category', key: 'expenseCat', width: 20 },
      { header: 'Expense (₹)', key: 'expenseAmount', width: 15 }
    ];

    // Style header row
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 12 };
    headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF6200EE' } };
    headerRow.alignment = { horizontal: 'center', vertical: 'center' };
    headerRow.height = 25;

    // Extract statement date from first record
    const statementDate = profitData[0]?.statement_date 
      ? new Date(profitData[0].statement_date).toLocaleDateString('en-IN')
      : reportDate;

    // Group data by fish names and expense categories
    const fishRevenues = {};
    const expenseCategories = {};
    let totalRevenue = 0;
    let totalExpense = 0;

    // Process data to build summary
    profitData.forEach(item => {
      if (item.fish_name && item.fish_revenue) {
        totalRevenue += parseFloat(item.fish_revenue) || 0;
        fishRevenues[item.fish_name] = (fishRevenues[item.fish_name] || 0) + parseFloat(item.fish_revenue);
      }
      if (item.expense_cat && item.expense_amount) {
        totalExpense += parseFloat(item.expense_amount) || 0;
        expenseCategories[item.expense_cat] = (expenseCategories[item.expense_cat] || 0) + parseFloat(item.expense_amount);
      }
    });

    // Convert to arrays
    const revenueRows = Object.entries(fishRevenues).map(([name, amount]) => ({
      fishName: name,
      fishRevenue: parseFloat(amount).toFixed(2)
    })).sort((a, b) => parseFloat(b.fishRevenue) - parseFloat(a.fishRevenue));

    const expenseRows = Object.entries(expenseCategories).map(([cat, amount]) => ({
      expenseCat: cat,
      expenseAmount: parseFloat(amount).toFixed(2)
    })).sort((a, b) => parseFloat(b.expenseAmount) - parseFloat(a.expenseAmount));

    // Add data rows with accounting statement format (left fish revenue, right expense categories)
    const maxRows = Math.max(revenueRows.length, expenseRows.length);
    for (let i = 0; i < maxRows; i++) {
      const row = worksheet.addRow({
        statementDate: i === 0 ? statementDate : '', // Only show date on first row
        fishName: revenueRows[i]?.fishName || '',
        fishRevenue: revenueRows[i]?.fishRevenue ? `₹${revenueRows[i].fishRevenue}` : '',
        spacer1: '',
        expenseCat: expenseRows[i]?.expenseCat || '',
        expenseAmount: expenseRows[i]?.expenseAmount ? `₹${expenseRows[i].expenseAmount}` : ''
      });

      // Style data rows
      row.font = { size: 11 };
      row.alignment = { horizontal: 'right', vertical: 'center' };
      
      // Alternate row colors
      if (i % 2 === 0) {
        row.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F5F5' } };
      }
    }

    // Add summary row
    const totalProfit = totalRevenue - totalExpense;

    const summaryRow = worksheet.addRow({
      statementDate: '',
      fishName: 'TOTAL',
      fishRevenue: `₹${totalRevenue.toFixed(2)}`,
      spacer1: '',
      expenseCat: 'TOTAL',
      expenseAmount: `₹${totalExpense.toFixed(2)}`
    });

    summaryRow.font = { bold: true, size: 12, color: { argb: 'FFFFFFFF' } };
    summaryRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF6200EE' } };
    summaryRow.alignment = { horizontal: 'right', vertical: 'center' };

    // Add profit row
    const profitRow = worksheet.addRow({
      statementDate: '',
      fishName: '',
      fishRevenue: '',
      spacer1: '',
      expenseCat: 'PROFIT',
      expenseAmount: `₹${totalProfit.toFixed(2)}`
    });

    profitRow.font = { bold: true, size: 12, color: { argb: totalProfit >= 0 ? 'FF2E7D32' : 'FFC62828' } };
    profitRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: totalProfit >= 0 ? 'FFC8E6C9' : 'FFFFCDD2' } };
    profitRow.alignment = { horizontal: 'right', vertical: 'center' };

    // Save Excel file temporarily
    excelFilePath = path.join(__dirname, '../temp', `Profit_Report_${Date.now()}.xlsx`);
    
    // Create temp directory if it doesn't exist
    const tempDir = path.dirname(excelFilePath);
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    await workbook.xlsx.writeFile(excelFilePath);
    console.log(`✓ Excel file generated: ${excelFilePath}`);

    // ==========================================
    // STEP 2: Create Gmail SMTP Transporter
    // ==========================================
    const transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: emailUser.trim(),
        pass: emailPassword.trim()
      }
    });

    // ==========================================
    // STEP 3: Prepare Email Content
    // ==========================================
    const mailContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333; border-bottom: 2px solid #6200EE; padding-bottom: 10px;">
          📈 Daily Profit Report - Account Statement
        </h2>
        
        <div style="margin: 20px 0; background-color: #f5f5f5; padding: 15px; border-radius: 5px;">
          <p><strong>Report Date:</strong> ${reportDate}</p>
          <p><strong>Report Generated:</strong> ${new Date().toLocaleDateString('en-IN')} ${new Date().toLocaleTimeString('en-IN')}</p>
          <p><strong>Fish Types:</strong> ${revenueRows.length} | <strong>Expense Categories:</strong> ${expenseRows.length}</p>
          
          <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
            <tr style="background-color: #6200EE; color: white;">
              <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Metric</th>
              <th style="padding: 10px; text-align: right; border: 1px solid #ddd;">Amount</th>
            </tr>
            <tr style="background-color: #fff;">
              <td style="padding: 10px; border: 1px solid #ddd;">Total Revenue (Fish Sales)</td>
              <td style="padding: 10px; text-align: right; border: 1px solid #ddd;">₹${totalRevenue.toFixed(2)}</td>
            </tr>
            <tr style="background-color: #f9f9f9;">
              <td style="padding: 10px; border: 1px solid #ddd;">Total Expense (Categories)</td>
              <td style="padding: 10px; text-align: right; border: 1px solid #ddd;">₹${totalExpense.toFixed(2)}</td>
            </tr>
            <tr style="background-color: ${totalProfit >= 0 ? '#c8e6c9' : '#ffcdd2'}; font-weight: bold;">
              <td style="padding: 10px; border: 1px solid #ddd;">Total Profit</td>
              <td style="padding: 10px; text-align: right; border: 1px solid #ddd; color: ${totalProfit >= 0 ? '#2e7d32' : '#c62828'};">
                ₹${totalProfit.toFixed(2)}
              </td>
            </tr>
          </table>
        </div>

        <div style="margin-top: 20px; padding: 10px; background-color: #e3f2fd; border-left: 4px solid #2196F3; border-radius: 3px;">
          <p style="margin: 0; color: #1976D2; font-size: 12px;">
            📎 Detailed account statement is attached as Excel file (Profit_Report.xlsx)
          </p>
        </div>

        <p style="color: #666; font-size: 12px; margin-top: 20px; text-align: center;">
          This is an automated email from Billing Software.
        </p>
      </div>
    `;

    console.log(`📧 Sending email to: ${recipientEmail}`);

    // ==========================================
    // STEP 4: Send Email with Excel Attachment
    // ==========================================
    const mailOptions = {
      from: `Billing Software <${emailUser}>`,
      to: recipientEmail,
      subject: `Profit Report - ${reportDate}`,
      html: mailContent,
      attachments: [
        {
          filename: `Profit_Report_${reportDate.replace(/\//g, '-')}.xlsx`,
          path: excelFilePath
        }
      ]
    };

    const info = await transporter.sendMail(mailOptions);

    console.log(`✓ Email sent successfully!`);
    console.log(`📨 Sent to: ${recipientEmail}`);

    res.status(200).json({ 
      success: true,
      message: 'Profit report sent successfully with Excel attachment',
      sentTo: recipientEmail,
      hint: 'Check your Gmail inbox for the profit report'
    });

  } catch (err) {
    console.error('❌ Email send error:', err.message);
    console.error('Full error:', err);
    
    res.status(500).json({ 
      error: 'Failed to send email',
      details: err.message,
      hint: 'Check Gmail credentials: EMAIL_USER and EMAIL_PASSWORD in .env. Make sure 2FA is enabled and App Password is correct.'
    });
  } finally {
    // ==========================================
    // STEP 5: Cleanup - Delete temporary Excel file
    // ==========================================
    if (excelFilePath && fs.existsSync(excelFilePath)) {
      try {
        fs.unlinkSync(excelFilePath);
        console.log(`🗑️  Cleaned up temporary file: ${excelFilePath}`);
      } catch (deleteErr) {
        console.error('Warning: Could not delete temporary file:', deleteErr.message);
      }
    }
  }
});

module.exports = router;
