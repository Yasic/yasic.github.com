import Cocoa

print("Begin")

let directory = "/Users/yuxuan/Code/YasicBlog/jekyll-theme-next-master/_posts"
let reader = FileManager.default
do {
    let subDirectorys = try reader.contentsOfDirectory(atPath: directory)
    subDirectorys.filter({ $0 != "FileProcessor.playground" }).forEach { dir in
        let dirPath = directory + "/" + dir
        let files = try? reader.contentsOfDirectory(atPath: dirPath)
        files?.forEach({ fileName in
            let filePath = dirPath + "/" + fileName
            if let data = try? String(contentsOf: URL(fileURLWithPath: filePath), encoding: String.Encoding.utf8) {
                let lines = data.components(separatedBy: .newlines)
                let newLines = lines.map { line -> String in
                    if line == "```objectivec" {
                        return "```objective_c"
                    }
                    return line
                }
                let newContents = newLines.joined(separator: "\n")
                print(newContents)
            }
        })
    }
}

print("Over")
