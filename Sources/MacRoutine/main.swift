import AppKit

NSApplication.shared.setActivationPolicy(.accessory)

let args = CommandLine.arguments.dropFirst()

if args.first == "setup" {
    SetupFlow().run()
    exit(0)
} else {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}
