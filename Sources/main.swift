import Foundation
import Subprocess
import System

let prev = FileManager.default.currentDirectoryPath
print(prev)
let home = FileManager.default.homeDirectoryForCurrentUser.path()
FileManager.default.changeCurrentDirectoryPath(home)
let cwd = FileManager.default.currentDirectoryPath
print(cwd)
defer {
    FileManager.default.changeCurrentDirectoryPath(prev)
}

await ohmyzsh()
await homebrew()
await neovim()

func ohmyzsh() async {
    var s = stat()
    let r = stat("\(home).oh-my-zsh", &s)
    if r != 0 {
        print("Install ohmyzsh?")
        if let respose = readLine() {
            if respose.lowercased() == "y" {
                do {
                    let (read, write) = try FileDescriptor.pipe()
                    _ = try await run(
                        .name("curl"),
                        arguments: [
                            "-fsSL", "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh",
                        ],
                        input: .fileDescriptor(.standardInput, closeAfterSpawningProcess: false),
                        output: .fileDescriptor(write, closeAfterSpawningProcess: false),
                        error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
                    )
                    _ = try await run(
                        .name("sh"),
                        arguments: [],
                        input: .fileDescriptor(read, closeAfterSpawningProcess: false),
                        output: .fileDescriptor(.standardOutput, closeAfterSpawningProcess: false),
                        error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
                    )
                    try read.close()
                    try write.close()
                } catch {
                    print(error)
                }
            }
        }
    }
}

func homebrew() async {
    do {
        let brew: CollectedResult<StringOutput<Unicode.UTF8>, DiscardedOutput> = try await run(
            .name("brew"), arguments: ["--version"])
        if !brew.terminationStatus.isSuccess {
            print("Install homebrew?")
            if let respose = readLine() {
                if respose.lowercased() == "y" {
                    let (read, write) = try FileDescriptor.pipe()
                    _ = try await run(
                        .name("curl"),
                        arguments: [
                            "-fsSL", "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh",
                        ],
                        input: .fileDescriptor(.standardInput, closeAfterSpawningProcess: false),
                        output: .fileDescriptor(write, closeAfterSpawningProcess: false),
                        error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
                    )
                    try read.close()
                    try write.close()
                    // TODO run bash code as sudo.
                    // _ = try await run(
                    //     .name("sudo"),
                    //     arguments: [],
                    //     input: .fileDescriptor(read, closeAfterSpawningProcess: false),
                    //     output: .fileDescriptor(.standardOutput, closeAfterSpawningProcess: false),
                    //     error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
                    // )
                    // print("Run homebrew command")
                }
            }
        } else {
            print("homebrew installed")
        }
    } catch {
        print(error)
    }
}

func neovim() async {
    do {
        let brew: CollectedResult<StringOutput<Unicode.UTF8>, DiscardedOutput> = try await run(
            .name("brew"), arguments: ["--version"])
        if brew.terminationStatus.isSuccess {
            let nvim: CollectedResult<StringOutput<Unicode.UTF8>, DiscardedOutput> = try await run(
                .name("nvim"), arguments: ["--version"])
            if !nvim.terminationStatus.isSuccess {
                print("installing neovim")
                _ = try await run(
                    .name("brew"),
                    arguments: [
                        "install", "neovim",
                    ],
                    input: .fileDescriptor(.standardInput, closeAfterSpawningProcess: false),
                    output: .fileDescriptor(.standardOutput, closeAfterSpawningProcess: false),
                    error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
                )
            }
        } else {
            print("neovim install requires homebrew")
        }
        let r = mkdir(".config/nvim", 0o755)

        if r != 0 {
            print("mkdir error:", r)
            print(".config/nvim already exisit")
        } else {
            _ = try await run(
                .name("git"),
                arguments: [
                    "clone", "-b", "lazy-vim",
                    "git@github.com:zaneenders/nvim.git",
                    "\(home).config/nvim",
                ],
                input: .fileDescriptor(.standardInput, closeAfterSpawningProcess: false),
                output: .fileDescriptor(.standardOutput, closeAfterSpawningProcess: false),
                error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false)
            )
        }
    } catch {
        print(error)
    }
}
