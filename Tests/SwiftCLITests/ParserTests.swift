//
//  ParserTests.swift
//  SwiftCLI
//
//  Created by Jake Heiser on 1/7/15.
//  Copyright (c) 2015 jakeheis. All rights reserved.
//

import XCTest
@testable import SwiftCLI

class ParserTests: XCTestCase {
    
    // MARK: - Option parsing tests
    
    func testSimpleFlagParsing() throws {
        let cmd = DoubleFlagCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "-b"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        XCTAssertTrue(cmd.alpha)
        XCTAssertTrue(cmd.beta)
    }
    
    func testSimpleKeyParsing() throws {
        let cmd = DoubleKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "apple", "-b", "banana"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        
        XCTAssertEqual(cmd.alpha, "apple", "Options should update the values of passed keys")
        XCTAssertEqual(cmd.beta, "banana", "Options should update the values of passed keys")
    }
    
    func testKeyValueParsing() throws {
        let cmd = IntKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "7"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        
        XCTAssertEqual(cmd.alpha, 7, "Options should parse int")
    }
    
    func testCombinedFlagsAndKeysParsing() throws {
        let cmd = FlagKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "-b", "banana"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        
        XCTAssertTrue(cmd.alpha, "Options should execute the closures of passed flags")
        XCTAssertEqual(cmd.beta, "banana", "Options should execute the closures of passed keys")
        
        let cmd2 = FlagKeyCmd()
        let arguments2 = ArgumentList(arguments: ["cmd", "-ab", "banana"])
        let cli2 = CLI.createTester(commands: [cmd2])
        
        _ = try Parser().parse(cli: cli2, arguments: arguments2)
        
        XCTAssertTrue(cmd2.alpha)
        XCTAssertEqual(cmd2.beta, "banana")
    }
    
    func testCombinedFlagsAndKeysAndArgumentsParsing() throws {
        let cmd = FlagKeyParamCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "argument", "-b", "banana"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        
        XCTAssert(cmd.alpha, "Options should execute the closures of passed flags")
        XCTAssertEqual(cmd.beta, "banana", "Options should execute the closures of passed keys")
        XCTAssertEqual(cmd.param, "argument")
    }
    
    func testUnrecognizedOptions() throws {
        let cmd = FlagCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "-b"])
        let cli = CLI.createTester(commands: [cmd])
        
        do {
            _ = try Parser().parse(cli: cli, arguments: arguments)
            XCTFail()
        } catch let error as OptionError {
            guard case let .unrecognizedOption(key) = error.kind, key == "-b" else {
                XCTFail()
                return
            }
        }
    }
    
    func testKeysNotGivenValues() throws {
        let cmd = FlagKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-b", "-a"])
        let cli = CLI.createTester(commands: [cmd])
        
        do {
            _ = try Parser().parse(cli: cli, arguments: arguments)
            XCTFail()
        } catch let error as OptionError {
            guard case let .expectedValueAfterKey(key) = error.kind else {
                XCTFail()
                return
            }
            XCTAssertEqual(key, "-b")
        }
        
        let cmd2 = FlagKeyCmd()
        let arguments2 = ArgumentList(arguments: ["cmd", "-ba"])
        let cli2 = CLI.createTester(commands: [cmd2])
        
        do {
            _ = try Parser().parse(cli: cli2, arguments: arguments2)
            XCTFail()
        } catch let error as OptionError {
            guard case let .expectedValueAfterKey(key) = error.kind else {
                XCTFail()
                return
            }
            XCTAssertEqual(key, "-b")
        }
    }
    
    func testFlagGivenValue() throws {
        let cmd = FlagKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "--alpha=value"])
        let cli = CLI.createTester(commands: [cmd])
        
        do {
            _ = try Parser().parse(cli: cli, arguments: arguments)
            XCTFail()
        } catch let error as OptionError {
            guard case let .unexpectedValueAfterFlag(flag) = error.kind else {
                XCTFail()
                return
            }
            XCTAssertEqual(flag, "--alpha")
        }
    }
    
    func testIllegalOptionFormat() throws {
        let cmd = IntKeyCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-a", "val"])
        let cli = CLI.createTester(commands: [cmd])
        
        do {
            _ = try Parser().parse(cli: cli, arguments: arguments)
            XCTFail()
        } catch let error as OptionError {
            guard case .invalidKeyValue(let key, "-a", .conversionError) = error.kind, ObjectIdentifier(key) == ObjectIdentifier(cmd.$alpha) else {
                XCTFail()
                return
            }
        }
    }
    
    func testFlagSplitting() throws {
        let cmd = DoubleFlagCmd()
        let arguments = ArgumentList(arguments: ["cmd", "-ab"])
        let cli = CLI.createTester(commands: [cmd])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        
        XCTAssertTrue(cmd.alpha)
        XCTAssertTrue(cmd.beta)
    }
    
    func testGroupRestriction() throws {
        let cmd1 = ExactlyOneCmd()
        let arguments1 = ArgumentList(arguments: ["cmd", "-a", "-b"])
        
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd1]), arguments: arguments1)
            XCTFail()
            return
        } catch let error as OptionError {
            guard case let .optionGroupMisuse(group) = error.kind else {
                XCTFail()
                return
            }
            XCTAssert(group === cmd1.optionGroups[0])
        }
        
        let cmd2 = ExactlyOneCmd()
        let arguments2 = ArgumentList(arguments: ["cmd", "-a"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd2]), arguments: arguments2)
        XCTAssertTrue(cmd2.alpha)
        XCTAssertFalse(cmd2.beta)
        
        let cmd3 = ExactlyOneCmd()
        let arguments3 = ArgumentList(arguments: ["cmd", "-b"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd3]), arguments: arguments3)
        XCTAssertTrue(cmd3.beta)
        XCTAssertFalse(cmd3.alpha)
        
        let cmd4 = ExactlyOneCmd()
        let arguments4 = ArgumentList(arguments: ["cmd"])
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd4]), arguments: arguments4)
            XCTFail()
        } catch let error as OptionError {
            guard case let .optionGroupMisuse(group) = error.kind else {
                XCTFail()
                return
            }
            XCTAssert(group === cmd4.optionGroups[0])
        }
    }
    
    func testVaridadicParse() throws {
        let cmd = VariadicKeyCmd()
        let cli = CLI.createTester(commands: [cmd])
        let arguments = ArgumentList(arguments: ["cmd", "-f", "firstFile", "--file", "secondFile"])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        XCTAssertEqual(cmd.files, ["firstFile", "secondFile"])
    }
    
    func testCounterParse() throws {
        let counterCmd = CounterFlagCmd()
        let counterCli = CLI.createTester(commands: [counterCmd])
        _ = try Parser().parse(cli: counterCli, arguments: ArgumentList(arguments: ["cmd", "-v", "-v"]))
        XCTAssertEqual(counterCmd.verbosity, 2)
        
        let flagCmd = FlagCmd()
        let flagCli = CLI.createTester(commands: [flagCmd])
        _ = try Parser().parse(cli: flagCli, arguments: ArgumentList(arguments: ["cmd", "-a", "-a"]))
        XCTAssertTrue(flagCmd.flag)
    }
    
    func testBeforeCommand() throws {
        let cmd = EmptyCmd()
        let yes = Flag("-y")
        
        let cli = CLI.createTester(commands: [cmd])
        cli.globalOptions = [yes]
        let arguments = ArgumentList(arguments: ["-y", "cmd"])
        
        _ = try Parser().parse(cli: cli, arguments: arguments)
        XCTAssertTrue(yes.wrappedValue)
    }
    
    func testValidation() throws {
        let cmd1 = ValidatedKeyCmd()
        let arguments1 = ArgumentList(arguments: ["cmd", "-n", "jake"])
        
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd1]), arguments: arguments1)
            XCTFail()
        } catch let error as OptionError {
            guard case .invalidKeyValue(let key, "-n", .validationError(let validator)) = error.kind else {
                XCTFail()
                return
            }
            XCTAssert(ObjectIdentifier(key) == ObjectIdentifier(cmd1.$firstName))
            XCTAssertEqual(validator.message, "Must be a capitalized first name")
        }
        
        let cmd2 = ValidatedKeyCmd()
        let arguments2 = ArgumentList(arguments: ["cmd", "-n", "Jake"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd2]), arguments: arguments2)
        XCTAssertEqual(cmd2.firstName, "Jake")
        
        let cmd3 = ValidatedKeyCmd()
        let arguments3 = ArgumentList(arguments: ["cmd", "-a", "15"])
        
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd3]), arguments: arguments3)
            XCTFail()
        } catch let error as OptionError {
            guard case .invalidKeyValue(let key, "-a", .validationError(let validator)) = error.kind else {
                XCTFail(String(describing: error))
                return
            }
            XCTAssert(ObjectIdentifier(key) == ObjectIdentifier(cmd3.$age))
            XCTAssertEqual(validator.message, "must be greater than 18")
        }
        
        let cmd4 = ValidatedKeyCmd()
        let arguments4 = ArgumentList(arguments: ["cmd", "-a", "19"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd4]), arguments: arguments4)
        XCTAssertEqual(cmd4.age, 19)
        
        let cmd5 = ValidatedKeyCmd()
        let arguments5 = ArgumentList(arguments: ["cmd", "-l", "Chicago"])
        
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd5]), arguments: arguments5)
            XCTFail()
        } catch let error as OptionError {
            guard case .invalidKeyValue(let key, "-l", .validationError(let validator)) = error.kind else {
                XCTFail()
                return
            }
            
            XCTAssert(ObjectIdentifier(key) == ObjectIdentifier(cmd5.$location))
            XCTAssertEqual(validator.message, "must not be: Chicago, Boston")
        }
        
        let cmd6 = ValidatedKeyCmd()
        let arguments6 = ArgumentList(arguments: ["cmd", "-l", "Denver"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd6]), arguments: arguments6)
        XCTAssertEqual(cmd6.location, "Denver")
        
        let cmd7 = ValidatedKeyCmd()
        let arguments7 = ArgumentList(arguments: ["cmd", "--holiday", "4th"])
        
        do {
            _ = try Parser().parse(cli: CLI.createTester(commands: [cmd7]), arguments: arguments7)
            XCTFail()
        } catch let error as OptionError {
            guard case .invalidKeyValue(let key, "--holiday", .validationError(let validator)) = error.kind else {
                XCTFail(String(describing: error))
                return
            }
            XCTAssert(ObjectIdentifier(key) == ObjectIdentifier(cmd7.$holiday))
            XCTAssertEqual(validator.message, "must be one of: Thanksgiving, Halloween")
        }
        
        let cmd8 = ValidatedKeyCmd()
        let arguments8 = ArgumentList(arguments: ["cmd", "--holiday", "Thanksgiving"])
        _ = try Parser().parse(cli: CLI.createTester(commands: [cmd8]), arguments: arguments8)
        XCTAssertEqual(cmd8.holiday, "Thanksgiving")
    }
    
    // MARK: - Combined test
    
    func testFullParse() throws {
        let cmd = TestCommand()
        let cli = CLI.createTester(commands: [cmd])
        
        let args = ArgumentList(arguments: ["test", "-s", "favTest", "-t", "3", "SwiftCLI"])
        let result = try Parser().parse(cli: cli, arguments: args)
        
        XCTAssertTrue(result.command === cmd)
        
        XCTAssertEqual(cmd.testName, "favTest")
        XCTAssertEqual(cmd.testerName, "SwiftCLI")
        XCTAssertTrue(cmd.silent)
        XCTAssertEqual(cmd.times, 3)
    }
    
    func testCollectedOptions() throws {
        class RunCmd: Command {
            let name = "run"
            @Param var executable: String
            @CollectedParam var args: [String]
            @Flag("-v") var verbose: Bool
            func execute() throws {}
        }
        
        let cmd = RunCmd()
        let cli = CLI.createTester(commands: [cmd])
        let args = ArgumentList(arguments: ["run", "cli", "-v", "arg"])
        
        let result = try Parser().parse(cli: cli, arguments: args)
        XCTAssertTrue(result.command === cmd)
        
        XCTAssertEqual(cmd.executable, "cli")
        XCTAssertEqual(cmd.args, ["-v", "arg"])
        XCTAssertFalse(cmd.verbose)
        
        let cmd2 = RunCmd()
        let cli2 = CLI.createTester(commands: [cmd2])
        let args2 = ArgumentList(arguments: ["run", "-v", "cli", "arg"])
        
        let result2 = try Parser().parse(cli: cli2, arguments: args2)
        XCTAssertTrue(result2.command === cmd2)
        
        XCTAssertEqual(cmd2.executable, "cli")
        XCTAssertEqual(cmd2.args, ["arg"])
        XCTAssertTrue(cmd2.verbose)
        
        let cmd3 = RunCmd()
        let cli3 = CLI.createTester(commands: [cmd3])
        let args3 = ArgumentList(arguments: ["run", "cli", "-v", "arg"])
        
        var parser = Parser()
        parser.parseOptionsAfterCollectedParameter = true
        let result3 = try parser.parse(cli: cli3, arguments: args3)
        XCTAssertTrue(result3.command === cmd3)
        
        XCTAssertEqual(cmd3.executable, "cli")
        XCTAssertEqual(cmd3.args, ["arg"])
        XCTAssertTrue(cmd3.verbose)
    }
    
}
