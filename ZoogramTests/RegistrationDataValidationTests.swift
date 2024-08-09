//
//  UserDataValidationTests.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 05.07.2024.
//

import Testing
@testable import Zoogram

struct RegistrationDataValidationTests {

    let userValidationSerivce = UserDataValidationService(
        authenticationService: AuthenticationServiceMock(),
        userDataService: UserDataServiceMock())

    @Test("Check if email is invalid", arguments: [
        "",
        "emailwithoutDots@domaincom",
        "emailWithoutAtSignDomain.com",
        "@domain.com",
        "sdf34sd@gm__ail.com",
        "*@&*!(@_)@gmail.com",
        "user@invalid-tld.123",
        "user#domain.com",
        "user&name@email-provider.net",
        "spaced user@domain.info",
        "double..dots@email.org",
        "@.com",
        "user@domain with space.com",
        "user@domain..com"
    ]) func invalidEmail(emailToTest: String) {
        let isValid = userValidationSerivce.checkIfEmailIsValid(email: emailToTest)
        #expect(isValid == false)
    }

    @Test("Check if email is valid", arguments: [
        "user@example.com",
        "user123@email.co.uk",
        "john.doe@company.org",
        "user_name1234@email-provider.net",
        "info@sub.domain.com",
        "name@my-email-provider.xyz",
        "john.doe@email.travel",
        "_______@domain.com"
    ]) func validEmail(emailToTest: String) {
        let isValid = userValidationSerivce.checkIfEmailIsValid(email: emailToTest)
        #expect(isValid == true)
    }

    @Test("Check if name is valid", arguments: [
        "Name",
        "Name Surname",
        "Name MiddleName Surname"
    ]) func validName(name: String) {
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfNameIsValid(name: name)
        } catch {
            caughtError = error
        }
        #expect(caughtError == nil)
    }

    @Test("Check if name is invalid") func invalidName() {
        let name  = " " // empty or whitespaces only
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfNameIsValid(name: name)
        } catch {
            caughtError = error
        }
        #expect(caughtError != nil)
    }

    @Test("Check if username is invalid", arguments: [
        "", // empty
        "user name", // with whitespaces
        "usr", // shorter than 4 characters
        "236542275643" // no letters
    ]) func invalidUsername(username: String) {
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfUsernameIsValid(username: username)
        } catch {
            caughtError = error
        }
        #expect(caughtError != nil)
    }

    @Test("Check if username is valid", arguments: [
        "validUsername",
        "val1d234",
        "user"
    ]) func validUsername(username: String) {
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfUsernameIsValid(username: username)
        } catch {
            caughtError = error
        }
        #expect(caughtError == nil)
    }

    @Test("Check if password is invalid", arguments: [
        "passw0r", // shorter than 8 characters
        "justLetters", // no digits
        "1234567890", // no letters
        "sdf 34 sda1 3" // with whitespaces
    ]) func invalidPassword(password: String) {
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfPasswordIsValid(password: password)
        } catch {
            caughtError = error
        }
        #expect(caughtError != nil)
    }

    @Test("Check if password is valid", arguments: [
        "passw0rd"
    ]) func validPassword(password: String) {
        var caughtError: Error?
        do {
            try userValidationSerivce.checkIfPasswordIsValid(password: password)
        } catch {
            caughtError = error
        }
        #expect(caughtError == nil)
    }
}
