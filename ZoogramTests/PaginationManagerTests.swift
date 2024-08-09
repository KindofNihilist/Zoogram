//
//  PaginationManagerTests.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 12.07.2024.
//

import Testing
import Foundation
@testable import Zoogram

struct PaginationManagerTests {

    var paginationManager = PaginationManager(numberOfItemsToGetPerPagination: 4)

    @Test func isPaginationAllowedTest() async {
        await paginationManager.setNumberOfAllItems(12)
        await paginationManager.updateNumberOfRetrievedItems(value: 4)
        #expect(await paginationManager.isPaginationAllowed() == true)
        await paginationManager.updateNumberOfRetrievedItems(value: 4)
        #expect(await paginationManager.isPaginationAllowed() == true)
        await paginationManager.updateNumberOfRetrievedItems(value: 4)
        #expect(await paginationManager.isPaginationAllowed() == false)
    }

    @Test func hasHitTheEndOfItemsTest() async {
        await paginationManager.setNumberOfAllItems(48)
        await paginationManager.updateNumberOfRetrievedItems(value: 48)
        #expect(await paginationManager.checkIfHasHitEndOfItems() == true)
    }

    @Test("Should reload data when all items = 0 & retrieved = 0") func shouldReloadDataTest_One() async {
        await paginationManager.setNumberOfAllItems(0)
        await paginationManager.resetNumberOfRetrievedItems()
        #expect(await paginationManager.shouldReloadData() == true)
    }

    @Test("Should reload when all items != 0 & retrieved = 0") func shouldReloadDataTest_Two() async {
        await paginationManager.setNumberOfAllItems(16)
        await paginationManager.resetNumberOfRetrievedItems()
        #expect(await paginationManager.shouldReloadData() == true)
    }

    @Test("Should reload when all items != 0 & retrieved < all items < items to get per pagination") func shouldReloadDataTest_Three() async {
        await paginationManager.setNumberOfAllItems(5)
        await paginationManager.updateNumberOfRetrievedItems(value: 3)
        #expect(await paginationManager.shouldReloadData() == true)
    }

    @Test("Should reload when all items != 0 & retrieved == items to get per pagination < all items ") func shouldReloadDataTest_Four() async {
        await paginationManager.setNumberOfAllItems(16)
        await paginationManager.updateNumberOfRetrievedItems(value: 4)
        #expect(await paginationManager.shouldReloadData() == false)
    }

    @Test("Should reload when all items != 0 & retrieved == all items < items to get per pagination") func shouldReloadDataTest() async {
        await paginationManager.setNumberOfAllItems(2)
        await paginationManager.updateNumberOfRetrievedItems(value: 2)
        #expect(await paginationManager.shouldReloadData() == false)
    }
}
