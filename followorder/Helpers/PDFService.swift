#if canImport(UIKit)
import Foundation
import PDFKit
import UIKit
import SwiftData

class PDFService {
    static func generateInvoice(for order: Order) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "FollowOrder App",
            kCGPDFContextAuthor: "FollowOrder",
            kCGPDFContextTitle: "Fatura - \(order.orderNumber)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String : Any]
        
        // A4 Paper Size: 595 x 842 points
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "Fatura_\(order.orderNumber.replacingOccurrences(of: "#", with: "")).pdf"
        let outputURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: outputURL) { context in
                context.beginPage()
                
                let margin: CGFloat = 36
                var currentY: CGFloat = 40
                
                // Color theme
                let primaryColor = UIColor(red: 22/255, green: 28/255, blue: 42/255, alpha: 1.0)
                let accentColor = UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1.0) // Violet default
                
                // 1. Header (Title)
                let title = "SİPARİŞ FATURASI"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 22),
                    .foregroundColor: primaryColor
                ]
                title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
                
                // App Logo Placeholder (Text Logo)
                let logoText = "FollowOrder"
                let logoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 18),
                    .foregroundColor: accentColor
                ]
                let logoSize = logoText.size(withAttributes: logoAttributes)
                logoText.draw(at: CGPoint(x: CGFloat(pageWidth) - margin - logoSize.width, y: currentY + 3), withAttributes: logoAttributes)
                
                currentY += 40
                
                // Draw a separator line
                let contextRef = context.cgContext
                contextRef.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.5).cgColor)
                contextRef.setLineWidth(1)
                contextRef.move(to: CGPoint(x: margin, y: currentY))
                contextRef.addLine(to: CGPoint(x: CGFloat(pageWidth) - margin, y: currentY))
                contextRef.strokePath()
                
                currentY += 20
                
                // 2. Info Columns
                let dateStyle = DateFormatter()
                dateStyle.dateStyle = .medium
                dateStyle.timeStyle = .short
                dateStyle.locale = Locale(identifier: "tr_TR")
                
                // Order Info Block (Left side)
                let orderInfo = """
                Sipariş No: \(order.orderNumber)
                Tarih: \(dateStyle.string(from: order.date))
                Durum: \(order.status.localizedName)
                """
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
                orderInfo.draw(at: CGPoint(x: margin, y: currentY), withAttributes: infoAttributes)
                
                // Customer Info Block (Right side)
                var customerInfo = "Müşteri: Perakende Satış (Anonim)"
                if let customer = order.customer {
                    customerInfo = """
                    Müşteri: \(customer.name)
                    Tel: \(customer.phone.isEmpty ? "-" : customer.phone)
                    E-Posta: \(customer.email.isEmpty ? "-" : customer.email)
                    Adres: \(customer.address.isEmpty ? "-" : customer.address)
                    """
                }
                
                let customerInfoSize = customerInfo.boundingRect(
                    with: CGSize(width: 250, height: 100),
                    options: .usesLineFragmentOrigin,
                    attributes: infoAttributes,
                    context: nil
                ).size
                
                customerInfo.draw(
                    in: CGRect(
                        x: CGFloat(pageWidth) - margin - customerInfoSize.width,
                        y: currentY,
                        width: customerInfoSize.width,
                        height: customerInfoSize.height
                    ),
                    withAttributes: infoAttributes
                )
                
                currentY += max(60, customerInfoSize.height + 15)
                
                // 3. Table Header
                let headers = ["Ürün Adı", "Barkod (SKU)", "Adet", "Birim Fiyat", "Toplam"]
                let columnWidths: [CGFloat] = [180, 100, 50, 90, 100]
                var currentX = margin
                
                let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: UIColor.white
                ]
                
                // Draw table header background
                let headerHeight: CGFloat = 25
                let headerRect = CGRect(x: margin, y: currentY, width: CGFloat(pageWidth) - (margin * 2), height: headerHeight)
                contextRef.setFillColor(primaryColor.cgColor)
                contextRef.fill(headerRect)
                
                for i in 0..<headers.count {
                    let rect = CGRect(x: currentX + 5, y: currentY + 6, width: columnWidths[i] - 10, height: headerHeight - 12)
                    headers[i].draw(in: rect, withAttributes: tableHeaderAttributes)
                    currentX += columnWidths[i]
                }
                
                currentY += headerHeight
                
                // 4. Table Items
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                
                let rowHeight: CGFloat = 25
                let items = order.items ?? []
                
                for item in items {
                    currentX = margin
                    
                    // Draw light background alternating rows
                    let rowRect = CGRect(x: margin, y: currentY, width: CGFloat(pageWidth) - (margin * 2), height: rowHeight)
                    let index = items.firstIndex(of: item) ?? 0
                    if index % 2 == 1 {
                        contextRef.setFillColor(UIColor.lightGray.withAlphaComponent(0.15).cgColor)
                        contextRef.fill(rowRect)
                    }
                    
                    // Draw row border bottom
                    contextRef.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
                    contextRef.move(to: CGPoint(x: margin, y: currentY + rowHeight))
                    contextRef.addLine(to: CGPoint(x: CGFloat(pageWidth) - margin, y: currentY + rowHeight))
                    contextRef.strokePath()
                    
                    let pName = item.product?.name ?? "Silinmiş Ürün"
                    let pSku = item.product?.sku ?? "-"
                    let qtyStr = "\(item.quantity)"
                    let priceStr = String(format: "₺%.2f", item.priceAtPurchase)
                    let totalStr = String(format: "₺%.2f", item.priceAtPurchase * Double(item.quantity))
                    
                    let cells = [pName, pSku, qtyStr, priceStr, totalStr]
                    
                    for i in 0..<cells.count {
                        let rect = CGRect(x: currentX + 5, y: currentY + 6, width: columnWidths[i] - 10, height: rowHeight)
                        cells[i].draw(in: rect, withAttributes: bodyAttributes)
                        currentX += columnWidths[i]
                    }
                    
                    currentY += rowHeight
                }
                
                currentY += 20
                
                // 5. Total calculations box
                let summaryX = CGFloat(pageWidth) - margin - 200
                
                let subtotal = items.reduce(0.0) { $0 + ($1.priceAtPurchase * Double($1.quantity)) }
                let discount = order.discount
                let total = max(0.0, subtotal - discount)
                
                let subtotalText = String(format: "Ara Toplam: ₺%.2f", subtotal)
                let discountText = String(format: "İndirim: ₺%.2f", discount)
                let grandTotalText = String(format: "Genel Toplam: ₺%.2f", total)
                
                let subtotalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                
                let grandTotalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: accentColor
                ]
                
                subtotalText.draw(at: CGPoint(x: summaryX, y: currentY), withAttributes: subtotalAttributes)
                currentY += 15
                
                discountText.draw(at: CGPoint(x: summaryX, y: currentY), withAttributes: subtotalAttributes)
                currentY += 15
                
                // Line above total
                contextRef.setStrokeColor(accentColor.cgColor)
                contextRef.setLineWidth(1.5)
                contextRef.move(to: CGPoint(x: summaryX, y: currentY + 3))
                contextRef.addLine(to: CGPoint(x: CGFloat(pageWidth) - margin, y: currentY + 3))
                contextRef.strokePath()
                currentY += 8
                
                grandTotalText.draw(at: CGPoint(x: summaryX, y: currentY), withAttributes: grandTotalAttributes)
                
                currentY += 60
                
                // Footer
                let footerText = "Bizi tercih ettiğiniz için teşekkür ederiz."
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 9),
                    .foregroundColor: UIColor.lightGray
                ]
                let footerSize = footerText.size(withAttributes: footerAttributes)
                footerText.draw(at: CGPoint(x: (CGFloat(pageWidth) - footerSize.width) / 2, y: CGFloat(pageHeight) - 40), withAttributes: footerAttributes)
            }
            return outputURL
        } catch {
            print("Failed to render PDF: \(error)")
            return nil
        }
    }
}
#elseif canImport(AppKit)
import Foundation
import PDFKit
import AppKit
import SwiftData

class PDFService {
    static func generateInvoice(for order: Order) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "Fatura_\(order.orderNumber.replacingOccurrences(of: "#", with: "")).pdf"
        let outputURL = tempDirectory.appendingPathComponent(fileName)
        
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        guard let gc = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        gc.beginPDFPage(nil)
        
        // Setup simple PDF drawing context for macOS
        let titleText = "SİPARİŞ FATURASI - \(order.orderNumber)\n"
        let dateText = "Tarih: \(order.date.description)\n"
        let totalText = "Genel Toplam: ₺\(String(format: "%.2f", order.totalAmount))\n\n"
        var itemsText = "Ürünler:\n"
        
        for item in order.items ?? [] {
            itemsText += "- \(item.product?.name ?? "Silinmiş Ürün") x\(item.quantity) (Birim: ₺\(String(format: "%.2f", item.priceAtPurchase)))\n"
        }
        
        let fullText = titleText + dateText + totalText + itemsText
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        
        let attributedString = NSAttributedString(string: fullText, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
        let path = CGPath(rect: CGRect(x: 50, y: 50, width: pageWidth - 100, height: pageHeight - 100), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        CTFrameDraw(frame, gc)
        
        gc.endPDFPage()
        gc.closePDF()
        
        return outputURL
    }
}
#endif
