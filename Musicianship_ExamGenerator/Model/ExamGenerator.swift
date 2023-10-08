
import Foundation
import AppKit

class ContentSectionUsage {
    var contentSection:ContentSection
    var type:String
    var usages:Int
    init(contentSection:ContentSection, type:String) {
        self.contentSection = contentSection
        self.type = type
        self.usages = 0
    }
}

class ExamGenerator : ObservableObject {
    static let shared = ExamGenerator()
    @Published var dataLoaded = false
    let googleAPI = GoogleAPI.shared
    var contentSections:[ContentSection] = []
    var templateSections:[ContentSection] = []
    var contentSectionUsage:[ContentSectionUsage] = []
    let fileName = "exam.txt"
    
    private init() {
        contentSections.append(ContentSection(parent: nil, name: "", type: ""))
        deleteFileInContainerIfExists(fileName: fileName)
    }

    func deleteFileInContainerIfExists(fileName: String) {
        let containerDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = containerDocumentsURL.appendingPathComponent(fileName)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("File \(fileName) deleted.")
            } catch {
                print("Error deleting file: \(error)")
            }
        } else {
            print("File \(fileName) does not exist.")
        }
        print("File created at:", containerDocumentsURL)
    }

    func appendToFile(_ line: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not find the documents directory.")
            return
        }

        let filePath = documentsDirectory.appendingPathComponent(fileName)
        var dataLine = ""
        dataLine += line
        let dataToAppend = (dataLine + "\n").data(using: .utf8)!
        
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil, attributes: nil)
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle.seekToEndOfFile()
            fileHandle.write(dataToAppend)
            fileHandle.closeFile()
        } catch {
            print("Error writing to file: \(error)")
        }
    }
    
    func addTabs(_ inStr:String, tabs:Int) -> String {
        var res = inStr
        for _ in 0..<tabs {
           res += "\t"
        }
        return res
    }
    
    func getExampleForType(type:String) -> ContentSection {
        let filteredByType = contentSectionUsage.filter { $0.type == type }
        let sortedByUsage = filteredByType.sorted(by: { $0.usages < $1.usages })
        let minUsage = sortedByUsage[0].usages
        let maxUsage = sortedByUsage[sortedByUsage.count - 1].usages
        let numberOfMinimins = sortedByUsage.filter { $0.usages == minUsage }.count
        let randomChoice = Int.random(in: 0...numberOfMinimins)
        if randomChoice >= sortedByUsage.count {
            print("HERE")
        }
        let selected = sortedByUsage[randomChoice]
        selected.usages += 1
        return selected.contentSection
    }
    
    func generateExam(templateSection:ContentSection, examsToGenerate:Int) {
        print("Generate for template:", templateSection.getPath())
        var practiceExamples:[ContentSection] = []
        var practiceParent:ContentSection?
        let practiceTypes = ["Type_1", "Type_2", "Type_3", "Type_4", "Type_5"]
        
        for section in self.contentSections {
            if section.parent == templateSection {
                
                ///find the template's parent grade
                let examModeParent = templateSection.parent
                let gradeParent = examModeParent!.parent
                //print ("===>Grade Parent", gradeParent!.getPath())
                
                ///find the grade's practice examples
                practiceParent = gradeParent?.subSections[0]
                break
            }
        }
        
        guard let practiceParent = practiceParent else {
            Logger.logger.reportError(self, "No practice parent")
            return
        }
        
        print ("===>Examples coming from practice parent", practiceParent.getPath())
        practiceExamples = (practiceParent.deepSearch(testCondition: {section in
            return (practiceTypes).contains(section.type)
        }))
        
        var errors = false
        for practice in practiceExamples {
            if !["Type_1","Type_2","Type_3","Type_4","Type_5"].contains(practice.type) {
                print ("Bad exam example at type:", practice.type, "\tpath", practice.getPath())
                errors = true
            }
        }
        if errors {
            return
            
        }
        ///place the practice examples into a usage array for allocation to exams
        print("\(practiceExamples.count) examples found under practice mode")
        for practiceExample in practiceExamples {
            self.contentSectionUsage.append(ContentSectionUsage(contentSection: practiceExample, type: practiceExample.type))
        }

        var selectionDescription = "Selected from - "
        for type in practiceTypes {
            let filteredByType = practiceExamples.filter { $0.type == type }
            let msg = "\(filteredByType.count) examples for type:\(type), "
            selectionDescription += msg
            print(msg)
        }
        
        for i in 0..<examsToGenerate {
            var line = addTabs("", tabs: 4) + "Exam "
            if i < 10 {
                line += " " + String(i+1)
            }
            else {
                line += "" + String(i+1)
            }
            line += addTabs("", tabs: 3) + "Exam "
            appendToFile(line)
            let currentDate = Date()
            let dateFormatter = DateFormatter()

            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: currentDate)
            line = addTabs("//", tabs: 7) + "generated:" + formattedDate
            appendToFile(line)
            line = addTabs("//", tabs: 7) + selectionDescription
            appendToFile(line)

            for subSection in templateSection.subSections {
                let example = getExampleForType(type: subSection.type)
                var line = addTabs("", tabs: 5) + subSection.name + "\t\t" + example.type + "\t\t"
                for cells in example.contentSectionData.data {
                    line += cells + "\t"
                }
                appendToFile(line)
            }
        }
    }
    
    func readContent() {
        googleAPI.getExampleSheet(onDone: {status,data in
            print(status)
            if status == .success {
                if let data = data {
                    struct JSONSheet: Codable {
                        let range: String
                        let values:[[String]]
                    }
                    do {
                        let jsonData = try JSONDecoder().decode(JSONSheet.self, from: data)
                        let sheetRows = jsonData.values
                        self.loadSheetData(sheetRows: sheetRows)
                        DispatchQueue.main.async {
                            self.dataLoaded = true
                        }
                    }
                    catch {
                        Logger.logger.log(self, "Cannot parse JSON content")
                    }
                }
                else {
                    //self.setDataReady(way: .failed)
                    Logger.logger.log(self, "No content data")
                }
            }
            else {
                //self.setDataReady(way: status)
            }

        })
    }
    
    func loadSheetData(sheetRows:[[String]]) {
        var rowNum = 0
        let keyStart = 2
        let keyLength = 4
        let typeIndex = 7
        let dataStart = typeIndex + 2
        var contentSectionCount = 0
        var lastContentSectionDepth:Int?
        
        var levelContents:[ContentSection?] = Array(repeating: nil, count: keyLength)
        
        for rowCells in sheetRows {
            rowNum += 1
            if rowNum == 123 {
                print("+++")
            }
            if rowCells.count > 0 {
                if rowCells[0].hasPrefix("//")  {
                    continue
                }
            }
            let contentType = rowCells.count < typeIndex ? "" : rowCells[typeIndex].trimmingCharacters(in: .whitespaces)
            
            var rowHasAKey = false
            for cellIndex in keyStart..<keyStart + keyLength {
                if cellIndex < rowCells.count {
                    let keyData = rowCells[cellIndex].trimmingCharacters(in: .whitespaces)
                    if !keyData.isEmpty {
                        rowHasAKey = true
                        break
                    }
                }
            }
            
            if rowCells.count > 3 {
                let grade = rowCells[3]
//                if grade != "" {
//                    print("====", grade)
//                }
            }
                
            for cellIndex in keyStart..<keyStart + keyLength {
                var keyData:String? = nil
                if cellIndex < rowCells.count {
                    keyData = rowCells[cellIndex].trimmingCharacters(in: .whitespaces)
                }
                //a new section for type with no section name
                if let lastContentSectionDepth = lastContentSectionDepth {
                    if cellIndex > lastContentSectionDepth {
                        if !rowHasAKey {
                            if !contentType.isEmpty {
                                keyData = "_" + contentType + "_"
                            }
                        }
                    }
                }

                if let keyData = keyData {
                    if !keyData.isEmpty {
                        let keyLevel = cellIndex - keyStart
                        let parent = keyLevel == 0 ? contentSections[0] : levelContents[keyLevel-1]
                        let contentData:[String]
                        if rowCells.count > dataStart {
                            contentData = Array(rowCells[dataStart...])
                        }
                        else {
                            contentData = []
                        }
                        if keyLevel == 0 {
                            print("")
                        }

                        let contentSection = ContentSection(
                            parent: parent,
                            name: keyData.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: contentType.trimmingCharacters(in: .whitespacesAndNewlines),
                            data: ContentSectionData(row: rowNum,
                                                     type: contentType.trimmingCharacters(in: .whitespacesAndNewlines),
                                                     data: contentData))
                        contentSectionCount += 1
                        levelContents[keyLevel] = contentSection
                        parent?.subSections.append(contentSection)
                        self.contentSections.append(contentSection)
                        if contentSection.type == "ExamTemplate" {
                            self.templateSections.append(contentSection)
                        }
                        if rowHasAKey {
                            lastContentSectionDepth = cellIndex
                        }
//                        if let parent = contentSection.parent {
//                            if parent.isExamTypeContentSection() {
//                                contentSection.loadAnswer()
//                            }
//                        }
                        //print("\nRow:", rowNum, "Index:", cellIndex, rowCells)
                        //self.contentSections[0].debug()
                    }
                }
            }
        }
        print("Example data loaded \(contentSectionCount) rows")
    }

}
