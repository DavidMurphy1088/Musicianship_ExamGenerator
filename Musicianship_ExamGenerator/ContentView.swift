import SwiftUI
import CoreData

struct RowView: View {
    @ObservedObject var content = Content.shared

    let contentSection: ContentSection

    var body: some View {
        HStack {
            Text("\(contentSection.getPath())").padding()
            Text("\(contentSection.name)").padding()
            Button(action: {
                //print("Button for \(contentSection.name) was tapped!")
                content.generateExam(contentSection: contentSection)
            }) {
                Text("Generate Exam")
                    .padding()
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView: View {
    @ObservedObject var content = Content.shared
    @State var status:String = ""
    
    func test() {
        let url = URL(string: "https://google.com")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error:", error)
                return
            }
            
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack {

            Button(action: {
                self.status = "Loading ..."
                content.readContent()
                
            }) {
                Text("Load Content").padding()
            }.padding()
            
            if self.content.dataLoaded {
                List(content.templateSections, id: \.self.id) { template in
                    RowView(contentSection: template)
                }
                .padding()
            }
            else {
                Text("\(self.status)")
            }
        }
    }


}

