//
//  main.swift
//  CwlPackageFetch
//
//  Created by Matt Gallagher on 2018/06/14.
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
struct PackageFetch {
	enum Failure: Swift.Error {
		case disablingInFavorOfCarthage
		case fetchAlreadyProcessed
		case missingEnvironment(String)
		case cantCreateOutputFile(String)
	}
	struct DependencyParseFailure: Error {
		let srcRoot: URL
		let description: Dictionary<String, Any>
		let topLevelPath: String
	}
	
	let toolchainDir: String
	let projectName: String
	let srcRoot: URL
	let packageDir: URL
	let symlinksURL: URL
	
	static func requireEnv(_ key: String) throws -> String {
		guard let value = env(key) else { throw Failure.missingEnvironment(key) }
		return value
	}
	
	init() throws {
		self.toolchainDir = try PackageFetch.requireEnv("TOOLCHAIN_DIR")
		self.srcRoot = URL(fileURLWithPath: try PackageFetch.requireEnv("SRCROOT"))
		self.projectName = try PackageFetch.requireEnv("PROJECT_NAME")
		self.packageDir = srcRoot.appendingPathComponent(".build")
		self.symlinksURL = packageDir.appendingPathComponent("symlinks")
	}
	
	func resolve() throws {
		print("### Starting package resolve into \(packageDir.path)", to: &FileHandle.err)
		
		let resolveOutput = try Process(
			path: toolchainDir + "/usr/bin/swift",
			directory: srcRoot,
			arguments: "package", "--build-path", "\(packageDir.path)", "resolve"
		).printInvocation().runToString()
		
		if resolveOutput == "" {
			print("### All dependencies up-to-date.", to: &FileHandle.err)
		} else {
			print(resolveOutput, terminator: "")
		}
	}
	
	func showDependencies() throws -> String {
		print("### Runing swift package show-dependencies to get package locations", to: &FileHandle.err)
		return try Process(
			path: toolchainDir + "/usr/bin/swift",
			directory: srcRoot,
			arguments: "package", "--build-path", "\(packageDir.path)", "show-dependencies", "--format", "json"
		).printInvocation().runToString()
	}
	
	static func createSymlink(link: URL, destination: URL) throws {
		let current = try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)
		if current == nil || current != destination.relativePath {
			_ = try? FileManager.default.removeItem(at: link)
			try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: destination.relativePath)
			print("Created symbolic link: \(link.path) -> \(destination.relativePath)", to: &FileHandle.err)
		}
	}
	
	func createSymlink(srcRoot: URL, name: String, destination: String) throws {
		let linkLocation = symlinksURL.appendingPathComponent(name)
		let linkDestination = URL(fileURLWithPath: "../\(destination)", relativeTo: linkLocation)
		try PackageFetch.createSymlink(link: linkLocation, destination: linkDestination)
	}
	
	func traverse(srcRoot: URL, description: Dictionary<String, Any>, topLevelPath: String) throws {
		guard let dependencies = description["dependencies"] as? [Dictionary<String, Any>] else { return }
		for dependency in dependencies {
			guard
				let path = dependency["path"] as? String,
				let relativePath = (path.range(of: topLevelPath)?.upperBound).map({ String(path[$0...]) }),
				let name = dependency["name"] as? String
				else {
					throw DependencyParseFailure(srcRoot: srcRoot, description: description, topLevelPath: topLevelPath)
			}
			
			let dependencyBuildDir = URL(fileURLWithPath: path).appendingPathComponent(".build")
			try FileManager.default.createDirectory(at: dependencyBuildDir, withIntermediateDirectories: true, attributes: nil)
			try PackageFetch.createSymlink(link: dependencyBuildDir.appendingPathComponent("symlinks"), destination: symlinksURL)
			
			let dependencies = dependencyBuildDir.appendingPathComponent("dependencies-state.json")
			guard FileManager.default.createFile(atPath: dependencies.path, contents: nil) else {
				throw PackageFetch.Failure.cantCreateOutputFile(dependencies.path)
			}
			
			try createSymlink(srcRoot: srcRoot, name: name, destination: relativePath)
			try traverse(srcRoot: srcRoot, description: dependency, topLevelPath: topLevelPath)
		}
	}
	
	func parseAndCreateSymlinks(dependencies: String) throws {
		// Note: despite asking for JSON formatting, in Swift 4.0 there may be other info on STDOUT before the JSON starts.
		guard
			let jsonStartIndex = dependencies.index(of: "{"),
			let descriptionData = String(dependencies[jsonStartIndex...]).data(using: .utf8),
			let description = try JSONSerialization.jsonObject(with: descriptionData, options: []) as? Dictionary<String, Any>
			else {
				throw DependencyParseFailure(srcRoot: srcRoot, description: [:], topLevelPath: packageDir.path + "/")
		}
		try FileManager.default.createDirectory(at: symlinksURL, withIntermediateDirectories: true, attributes: nil)
		try traverse(srcRoot: srcRoot, description: description, topLevelPath: packageDir.path + "/")
	}
	
	static func fetch() throws {
		guard env("CARTHAGE") != "YES" else { throw Failure.disablingInFavorOfCarthage }
		guard env("CWL_PACKAGE_DIR") == nil else { throw Failure.fetchAlreadyProcessed }
		
		let fetch = try PackageFetch()
		try fetch.resolve()
		let dependencies = try fetch.showDependencies()
		try fetch.parseAndCreateSymlinks(dependencies: dependencies)
		print("### Complete.", to: &FileHandle.err)
	}
}

if #available(OSX 10.13, *) {
	do {
		try PackageFetch.fetch()
	} catch PackageFetch.Failure.disablingInFavorOfCarthage {
		print("Fetching using swift package manager disabled in favor of Carthage", to: &FileHandle.err)
	} catch PackageFetch.Failure.fetchAlreadyProcessed {
		print("Package fetching disabled in child build", to: &FileHandle.err)
	} catch {
		print("Failed: \(error)", to: &FileHandle.err)
		exit(1)
	}
} else {
	print("Failed: script must run on mac OS X 10.13 or newer", to: &FileHandle.err)
	exit(1)
}
