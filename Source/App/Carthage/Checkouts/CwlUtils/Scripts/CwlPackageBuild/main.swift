//
//  main.swift
//  CwlPackageBuild
//
//  Created by Matt Gallagher on 25/6/18.
//  Copyright © 2018 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

func env(_ key: String) -> String? { return ProcessInfo.processInfo.environment[key] }
extension FileHandle: TextOutputStream {
	public func write(_ string: String) { string.data(using: .utf8).map { write($0) } }
	static var err = FileHandle.standardError
}
extension Process {
	struct Failure: Error {
		let code: Int32
		let output: String
	}
	convenience init(path: String, directory: URL? = nil, environment: [String: String]? = nil, arguments: String...) {
		self.init()
		(self.launchPath, self.arguments) = (path, arguments)
		_ = directory.map { self.currentDirectoryPath = $0.path }
		_ = environment.map { self.environment = $0 }
	}
	func printInvocation() -> Process {
		print("\(self.launchPath ?? "") \(self.arguments?.joined(separator: " ") ?? "")", to: &FileHandle.err)
		return self
	}
	@available(OSX 10.13, *) func runToString() throws -> String {
		let pipe = Pipe()
		self.standardOutput = pipe
		try self.run()
		let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
		self.waitUntilExit()
		if terminationStatus != 0 { throw Failure(code: terminationStatus, output: result) }
		return result
	}
}

@available(OSX 10.13, *)
struct PackageBuild {
	enum Failure: Swift.Error {
		case missingEnvironment(String)
	}
	static func requireEnv(_ key: String) throws -> String {
		guard let value = env(key) else { throw Failure.missingEnvironment(key) }
		return value
	}
	
	let action: String
	let buildDir: URL
	let developerBinDir: URL
	let objRoot: String
	let packageName: String
	let sdk: String
	let srcRoot: URL
	let parent: URL
	let symRoot: String
	let targetName: String
	
	let archs: String
	let bitcodeGenerationMode: String
	let carthage: String?
	let configuration: String
	let moduleCacheDir: String
	let onlyActiveArch: String
	let packagesDir: URL
	let platformName: String?
	let path: String
	let productNames: String?
	
	init() throws {
		action = try PackageBuild.requireEnv("ACTION")
		buildDir = URL(fileURLWithPath: try PackageBuild.requireEnv("BUILT_PRODUCTS_DIR"))
		developerBinDir = URL(fileURLWithPath: try PackageBuild.requireEnv("DEVELOPER_BIN_DIR"))
		objRoot = try PackageBuild.requireEnv("OBJROOT")
		packageName = try PackageBuild.requireEnv("CWL_PACKAGE_NAME")
		sdk = try PackageBuild.requireEnv("CWL_SDK")
		symRoot = try PackageBuild.requireEnv("SYMROOT")
		targetName = try PackageBuild.requireEnv("CWL_TARGET_NAME")
		
		archs = env("ARCHS") ?? ""
		bitcodeGenerationMode = env("BITCODE_GENERATION_MODE") ?? ""
		carthage = env("CARTHAGE")
		configuration = env("CONFIGURATION") ?? ""
		moduleCacheDir = env("MODULE_CACHE_DIR") ?? ""
		onlyActiveArch = env("ONLY_ACTIVE_ARCH") ?? ""
		let cwlPd = env("CWL_PACKAGE_DIR").map { URL(fileURLWithPath: $0) }
		let sr = URL(fileURLWithPath: try PackageBuild.requireEnv("SRCROOT"))
		parent = sr
		let pd = cwlPd ?? sr.appendingPathComponent(".build")
		packagesDir = pd
		path = env("PATH") ?? ""
		platformName = env("PLATFORM_NAME")
		productNames = env("CWL_PRODUCT_NAMES")
		
		srcRoot = packagesDir.appendingPathComponent("symlinks/\(packageName)")
	}
	
	func build() throws {
		print("### Running xcodebuild to build dependency \(targetName)", to: &FileHandle.err)
		
		let buildOutput = try Process(
			path: developerBinDir.appendingPathComponent("xcodebuild").path,
			environment: ["PATH": path],
			arguments:
			"-project", packagesDir.appendingPathComponent("symlinks/\(packageName)/\(packageName).xcodeproj").path,
							"-target", targetName,
							"-sdk", sdk,
							"-configuration", configuration,
							action,
							"SRCROOT=\(srcRoot.path)",
			"SYMROOT=\(symRoot)",
			"OBJROOT=\(objRoot)/\(packageName)",
			"ARCHS=\(archs)",
			"ONLY_ACTIVE_ARCH=\(onlyActiveArch)",
			"BITCODE_GENERATION_MODE=\(bitcodeGenerationMode)",
			"MODULE_CACHE_DIR=\(moduleCacheDir)",
			"CWL_PACKAGE_DIR=\(packagesDir.path)"
			).printInvocation().runToString()
		
		print(buildOutput, to: &FileHandle.err)
	}
	
	func carthageCopy() throws {
		guard let pn = productNames else { return }
		print("### Copying dependencies from Carthage build directory.", to: &FileHandle.err)
		
		let name = platformName == "iphoneos" || platformName == "iphonesimulator" ? "iOS" : "Mac"
		let carthageDir = parent.appendingPathComponent("Carthage/Build/\(name)")
		for productName in pn.components(separatedBy: ",") {
			let copyOutput = try Process(
				path: "/bin/cp", 
				arguments: "-Rf", carthageDir.appendingPathComponent(productName).path, buildDir.path
				).printInvocation().runToString()
			
			print(copyOutput, to: &FileHandle.err)
		}
	}
	
	func run() throws {
		if carthage != "YES" {
			try build()
		} else {
			try carthageCopy()
		}
	}
}

if #available(OSX 10.13, *) {
	do {
		try PackageBuild().run()
	} catch {
		print("Failed: \(error)", to: &FileHandle.err)
		exit(1)
	}
} else {
	print("Failed: script must run on mac OS X 10.13 or newer", to: &FileHandle.err)
	exit(1)
}
