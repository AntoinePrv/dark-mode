#!/usr/bin/env swift

import Cocoa
import Foundation

/* Run an AppleScript command. */
@discardableResult
func run_apple_script(_ source: String) -> String? {
    NSAppleScript(source: source)?.executeAndReturnError(nil).stringValue
}

/* Run a shell command. */
@discardableResult
func run_shell(_ args: [String]) -> Int32 {
    let task = Process()
    task.environment = ProcessInfo.processInfo.environment
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.standardError = FileHandle.standardError
    task.standardOutput = FileHandle.standardOutput
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}


/* Print a message to stderr. */
func print_error(_ message: String) {
    FileHandle.standardError.write((message + "\n").data(using: String.Encoding.utf8)!)
}

/* Print message to stderr and exit with error. */
func fail_with_message(_ message: String) {
    let program_error: Int32 = 2
    print_error(message)
    exit(program_error)
}

struct DarkMode {

    /* Check if the computer is in dark theme. */
    static func is_dark() -> Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }

    /* Set computer to dark theme. */
    static func set_dark() { run_apple_script("\(set_prefix) true") }

    /* Set computer to light theme. */
    static func set_light() { run_apple_script("\(set_prefix) false") }

    /* Toogle computer theme. */
    static func toogle() { run_apple_script("\(set_prefix) not dark mode") }

    /* Listen for theme change and run callback. */
    static func listen_with(_ callback:@escaping () -> ()) {
        callback()
        DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil
        ) { (notification) -> () in
            callback()
        }

        NSApplication.shared.run()
    }

    /* Listen for theme change event and run a shell script. */
    static func listen_with_shell(_ args: [String]) {
        DarkMode.listen_with({ () -> () in
            let code = run_shell(args + [DarkMode.is_dark() ? "dark" : "light"])
            if code != 0 {
                fail_with_message("Error running script: \(args.joined(separator: " "))")
            }
        })
    }
    }

    private static let set_prefix = """
        tell application \"System Events\" to tell appearance preferences to set dark mode to
    """
}

/* Show usage. */
func help() -> String {
    let program_name = CommandLine.arguments.first!
    return """
    Usage:
    \(program_name) (help | --help | -h)
    Print this message and exit.

    \(program_name) get
    Print the current mode, either "dark" or "light".

    \(program_name) dark
    Set theme to dark.

    \(program_name) light
    Set theme to ligth.

    \(program_name) toogle
    Toogle the theme to the opposite one.

    \(program_name) listen <script> [<args>...]
    Listen for theme changes and run the given script.
    The new theme, either "dark" or "light" is passed as the last argument to the script.
    """
}

func fail_with_help(_ message: String) {
    let argument_error: Int32 = 1
    print_error("\(message)\n\n\(help())")
    exit(argument_error)
}

func main() {
    let args = CommandLine.arguments
    if args.count >= 2 {
        let command = args[1]
        switch command {
            case "help", "-h", "--help":
                print(help())
            case "get":
                print(DarkMode.is_dark() ? "dark" : "light")
            case "dark":
                DarkMode.set_dark()
            case "light":
                DarkMode.set_light()
            case "toogle":
                DarkMode.toogle()
            case "listen":
                if args.count >= 3 {
                    DarkMode.listen_with_shell(Array(args.suffix(from: 2)))
                } else {
                    fail_with_help("Provide a hook to run on theme changes.")
                }
            default:
                fail_with_help("Invalid command: \(command).")
        }
    } else {
        fail_with_help("Provide a command.")
    }
}

main()
