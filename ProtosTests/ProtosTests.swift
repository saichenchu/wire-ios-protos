// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest
import ZMProtos

class ProtosTests: XCTestCase {
    
    func testTextMessageEncodingPerformance() {
        measureBlock { () -> Void in
            for _ in 0..<1000 {
                let messageBuilder = ZMGenericMessage.builder()
                messageBuilder.setMessageId(NSUUID().UUIDString)
                let textBuilder = ZMText.builder()
                textBuilder.setContent("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                messageBuilder.setText(textBuilder.build())
                _ = messageBuilder.build().data()
            }
        }
    }
    
    func testTextMessageDecodingPerformance() {
        let messageBuilder = ZMGenericMessage.builder()
        messageBuilder.setMessageId(NSUUID().UUIDString)
        let textBuilder = ZMText.builder()
        textBuilder.setContent("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
        messageBuilder.setText(textBuilder.build())
        let data = messageBuilder.build().data()
        messageBuilder.clear()
        
        measureBlock { () -> Void in
            for _ in 0..<1000 {
                let _ = messageBuilder.mergeFromData(data).build()
            }
        }
    }
    
    func testThatItCreatesGenericMessageForUnencryptedImage() {
        //given
        let nonce = NSUUID();
        let format = ZMImageFormat.Preview
        
        let mediumProperties = ZMIImageProperties(size: CGSizeMake(10000, 20000), length: 200000, mimeType: "fancy image")
        let processedProperties = ZMIImageProperties(size: CGSizeMake(640, 480), length: 200, mimeType: "downsized image")
        
        // when
        let message = ZMGenericMessage(mediumImageProperties: mediumProperties, processedImageProperties: processedProperties, encryptionKeys: nil, nonce: nonce.description, format: format)
        
        //then
        XCTAssertEqual(message.image.width, Int32(processedProperties.size.width))
        XCTAssertEqual(message.image.height, Int32(processedProperties.size.height))
        XCTAssertEqual(message.image.originalWidth, Int32(mediumProperties.size.width))
        XCTAssertEqual(message.image.originalHeight, Int32(mediumProperties.size.height))
        XCTAssertEqual(message.image.size, Int32(processedProperties.length))
        XCTAssertEqual(message.image.mimeType, processedProperties.mimeType)
        XCTAssertEqual(message.image.tag, StringFromImageFormat(format))
        XCTAssertNil(message.image.otrKey)
        XCTAssertNil(message.image.sha256)
        XCTAssertEqual(message.image.mac, NSData())
        XCTAssertEqual(message.image.macKey, NSData())
    }

    func testThatItCreatesGenericMessageForEncryptedImage() {
        //given
        let nonce = NSUUID();
        let otrKey = "OTR KEY".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        let macKey = "MAC KEY".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        let mac = "MAC".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!

        let mediumProperties = ZMIImageProperties(size: CGSizeMake(10000, 20000), length: 200000, mimeType: "fancy image")
        let processedProperties = ZMIImageProperties(size: CGSizeMake(640, 480), length: 200, mimeType: "downsized image")
        _ = ZMImageAssetEncryptionKeys(otrKey: otrKey, macKey: macKey, mac: mac)
        let format = ZMImageFormat.Preview
        let keys = ZMImageAssetEncryptionKeys(otrKey: otrKey, macKey: macKey, mac: mac)
        
        // when
        let message = ZMGenericMessage(mediumImageProperties: mediumProperties, processedImageProperties: processedProperties, encryptionKeys: keys, nonce: nonce.description, format: format)
        
        //then
        XCTAssertEqual(message.image.width, Int32(processedProperties.size.width))
        XCTAssertEqual(message.image.height, Int32(processedProperties.size.height))
        XCTAssertEqual(message.image.originalWidth, Int32(mediumProperties.size.width))
        XCTAssertEqual(message.image.originalHeight, Int32(mediumProperties.size.height))
        XCTAssertEqual(message.image.size, Int32(processedProperties.length))
        XCTAssertEqual(message.image.mimeType, processedProperties.mimeType)
        XCTAssertEqual(message.image.tag, StringFromImageFormat(format))
        XCTAssertEqual(message.image.otrKey, otrKey)
        XCTAssertNil(message.image.sha256)
        XCTAssertEqual(message.image.mac, NSData())
        XCTAssertEqual(message.image.macKey, NSData())
    }
    
    func testThatItCreatesGenericMessageFromImageData() {
        
        // given
        let bundle = NSBundle(forClass: self.dynamicType)
        let url = bundle.URLForResource("medium", withExtension: "jpg")!
        let data = NSData(contentsOfURL: url)!
        let nonce = "nonceeeee";
        
        // when
        let message = ZMGenericMessage(imageData: data, format: .Medium, nonce: nonce)
        
        // then
        XCTAssertEqual(message.image.width, 0)
        XCTAssertEqual(message.image.height, 0)
        XCTAssertGreaterThan(message.image.originalWidth, 0)
        XCTAssertGreaterThan(message.image.originalHeight, 0)
        XCTAssertEqual(message.image.size, 0)
        XCTAssertEqual(message.image.mimeType, "image/jpeg")
        XCTAssertEqual(message.image.tag, StringFromImageFormat(.Medium))
        XCTAssertEqual(message.image.otrKey.length, 0)
        XCTAssertEqual(message.image.mac.length, 0)
        XCTAssertEqual(message.image.macKey.length, 0)
    }
    
    func testThatItCanCreateKnock() {
        let nonce = NSUUID()
        let message = ZMGenericMessage.knockWithNonce(nonce.UUIDString.lowercaseString)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasKnock())
        XCTAssertFalse(message.knock.hotKnock())
        XCTAssertEqual(message.messageId, nonce.UUIDString.lowercaseString)
    }
    
    
    func testThatItCanCreateLastRead() {
        let conversationID = "someID"
        let timeStamp = NSDate(timeIntervalSince1970: 5000)
        let nonce = "nonce"
        let message =  ZMGenericMessage(lastRead: timeStamp, ofConversationWithID: conversationID, nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasLastRead())
        XCTAssertEqual(message.messageId, nonce)
        XCTAssertEqual(message.lastRead.conversationId, conversationID)
        XCTAssertEqual(message.lastRead.lastReadTimestamp, Int64(timeStamp.timeIntervalSince1970 * 1000))
        let storedDate = NSDate(timeIntervalSince1970: Double(message.lastRead.lastReadTimestamp/1000))
        XCTAssertEqual(storedDate, timeStamp)
    }
    
    
    func testThatItCanCreateCleared() {
        let conversationID = "someID"
        let timeStamp = NSDate(timeIntervalSince1970: 5000)
        let nonce = "nonce"
        let message =  ZMGenericMessage(clearedTimestamp: timeStamp, ofConversationWithID: conversationID, nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasCleared())
        XCTAssertEqual(message.messageId, nonce)
        XCTAssertEqual(message.cleared.conversationId, conversationID)
        XCTAssertEqual(message.cleared.clearedTimestamp, Int64(timeStamp.timeIntervalSince1970 * 1000))
        let storedDate = NSDate(timeIntervalSince1970: Double(message.cleared.clearedTimestamp/1000))
        XCTAssertEqual(storedDate, timeStamp)
    }
    
    func testThatItCanCreateSessionReset() {
        let nonce = NSUUID()
        let message = ZMGenericMessage.sessionResetWithNonce(nonce.UUIDString.lowercaseString)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasClientAction())
        XCTAssertEqual(message.clientAction, ZMClientAction.RESETSESSION)
        XCTAssertEqual(message.messageId, nonce.UUIDString.lowercaseString)
    }
    
    
}
