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
                var lines = data.components(separatedBy: .newlines)
                lines[2].insert("\"", at: lines[2].index(lines[2].startIndex, offsetBy: 13))
                lines[2].append("\"")
                let newContents = lines.joined(separator: "\n")
                try? newContents.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
            }
        })
    }
}

print("Over")
