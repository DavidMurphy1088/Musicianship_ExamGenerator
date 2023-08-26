
import Foundation

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

class Content : ObservableObject {
    static let shared = Content()
    @Published var dataLoaded = false
    let googleAPI = GoogleAPI.shared
    var contentSections:[ContentSection] = []
    var templateSections:[ContentSection] = []
    var contentSectionUsage:[ContentSectionUsage] = []
    
    private init() {
        contentSections.append(ContentSection(parent: nil, name: "", type: ""))
    }
    func generateExam(templateSection:ContentSection) {
        print("Generate for template:", templateSection.getPath())
        for section in self.contentSections {
            if section.parent == templateSection {
                let examModeParent = templateSection.parent
                let gradeParent = examModeParent!.parent
                print ("===>Grade Parent", gradeParent!.getPath())
                let practiceParent = gradeParent?.subSections[0]
                
                print ("===>Practice Parent", practiceParent!.getPath())
                let practiceExamplesForType = practiceParent?.deepSearch(testCondition: {section in
                    return (["Type_1", "Type_2", "Type_3", "Type_4", "Type_4"]).contains(section.type)
                })
                for example in practiceExamplesForType! {
                    print(example.getPath())
                    self.contentSectionUsage.append(ContentSectionUsage(contentSection: example, type: example.type))
                }
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
