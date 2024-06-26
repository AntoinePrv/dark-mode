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
    static func listen_with_shell(_ args: [String], light: String, dark: String) {
        DarkMode.listen_with({ () -> () in
            let code = run_shell(args + [DarkMode.is_dark() ? dark : light])
            if code != 0 {
                fail_with_message("Error running script: \(args.joined(separator: " "))")
            }
        })
    }

    /* Listen for theme change event and change the Base16 theme. */
    static func listen_with_base16(root: String, light: String, dark:String) {
        DarkMode.listen_with({ () -> () in
            if DarkMode.is_dark() {
                run_shell(["bash", "\(root)/scripts/base16-\(dark).sh"])
            } else {
                run_shell(["bash", "\(root)/scripts/base16-\(light).sh"])
            }
        })
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

    \(program_name) listen --light "str-light" --dark "str-dark "<script> [<args>...]
    Listen for theme changes and run the given script.
    The new theme, either "str-dark" or "str-light" is passed as the last argument to the script.

    \(program_name) base16 --root <base16-root> --light <light-theme> --dark <dark-theme>
    Listen for theme changes and change to the base16 theme accordingly
    """
}

func fail_with_help(_ message: String) {
    let argument_error: Int32 = 1
    print_error("\(message)\n\n\(help())")
    exit(argument_error)
}

/* Find an option in the program arguments or exit with error. */
func find_option(_ name: String) -> String {
    let args = CommandLine.arguments
    if let idx = args.firstIndex(of: name) {
        if args.count >= idx {
            return args[idx+1]
        }
    }
    fail_with_help("Please provide argument: \(name).")
    return ""
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
                if args.count >= 5 {
                    DarkMode.listen_with_shell(
                        Array(args.suffix(from: 6)),
                        light: find_option("--light"),
                        dark: find_option("--dark")
                    )
                } else {
                    fail_with_help("Provide a hook and theme strings to run on theme changes.")
                }
            case "base16":
                DarkMode.listen_with_base16(
                    root: find_option("--root"),
                    light: find_option("--light"),
                    dark: find_option("--dark")
                )
            default:
                fail_with_help("Invalid command: \(command).")
        }
    } else {
        fail_with_help("Provide a command.")
    }
}

main()
