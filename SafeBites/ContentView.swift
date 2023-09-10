import SwiftUI
import VisionKit
import Foundation
import Alamofire

extension Color {
    static let darkRed = Color(red: 0.7, green: 0.0, blue: 0.0)
    static let darkGreen = Color(red: 0.0, green: 0.5, blue: 0.0)
}

struct ContentView: View {
    
    //    @EnvironmentObject var vm: AppViewModel
    
    @State private var newAllergenName = ""
    
    @State private var items: [Item] = [
        Item(name: "Eggs", isChecked: false),
        Item(name: "Milk", isChecked: false),
        Item(name: "Peanuts", isChecked: false),
        Item(name: "Shellfish", isChecked: false),
        Item(name: "Sesame", isChecked: false),
        Item(name: "Soy", isChecked: false),
        Item(name: "Tree nuts", isChecked: false),
        Item(name: "Wheat", isChecked: false),        
    ]
    
    // DON'T NEED
    private let textContentTypes: [(title: String, textContentType: DataScannerViewController.TextContentType?)] = [
        ("All", .none)
    ]
    
    //    List of allergens that the user inputs
    var allergens: [String] {
        items.filter { $0.isChecked }.map { $0.name.lowercased() }
    }
    
    var language: String{
        "German"
    }
    
    var body: some View {
        TabView {
            // HOME TAB
            NavigationView {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            // ALLERGENS TAB
            NavigationView {
                AllergensListView(items: $items, newAllergenName: $newAllergenName)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Allergens")
            }
            
            // SCANNING TAB
            NavigationView {
                ScannerView(items: $items, newAllergenName: $newAllergenName)
            }.tabItem {
                Image(systemName: "camera")
                Text("Scanner")
            }
        }
        .overlay(Divider().background(Color.black).padding(.top, 625))
        
    }
    
}

struct HomeView: View {
    
    let languages = ["English", "Spanish", "Japanese", "Arabic"]
    @State private var selectedLanguage = "English"
    
    var body: some View{
        
        VStack {
            // App logo or icon
            Image("AllerScan_border")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding(.bottom, 30)
            
            // Welcome text
            Text("Welcome to Safe Bites")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 10)
            
            // App description
            Text("Interpret ingredients, avoid allergens, and consume confidently.")
                .font(Font.system(size: 20, weight: .regular, design: .default))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Select Your Preferred Language:")
                .font(.headline)
                .padding(.top, 80)
            
            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
        }
        
    }
    
}

struct AllergensListView: View {
    @Binding var items: [Item]
    @Binding var newAllergenName: String
    
    var body: some View {
        
        VStack{
            Text("Allergen Selection")
                .font(.largeTitle)
                .fontWeight(.bold)
            // .foregroundColor(.black)
                .padding(.top, 20)
            
            // Text("Select all foods that you are intolerant of.")
            
            List {
                
                Section(header: Text("Select all ingredients to be detected").padding(.top, 20)) {
                    ForEach(items.indices, id: \.self) { index in
                        Toggle(items[index].name, isOn: $items[index].isChecked).toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                
                Section(header: Text("Add Another Item")) {
                    HStack {
                        TextField("Enter Allergen Name", text: $newAllergenName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 8)
                        
                        Button(action: {
                            // Add a new allergen item with the user-entered name and toggle defaulted to "on"
                            let newItem = Item(name: newAllergenName, isChecked: true)
                            items.append(newItem)
                            
                            // Clear the TextField
                            newAllergenName = ""
                        }) {
                            Image(systemName: "plus.circle.fill") // Use a plus sign icon
                                .imageScale(.large)
                                .padding(.vertical, 5)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle()) // Apply a grouped list style
        }
    }
}

struct ScannerView: View{
    
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var items: [Item]
    @Binding var newAllergenName: String
    
    @State private var isSheetPresented = false
    
    
    var allergens: [String] {
        items.filter { $0.isChecked }.map { $0.name.lowercased() }
    }
    
    var body: some View {
        
        NavigationView {
            
            VStack{
                
                Text("Scan the full ingredients list found on food packaging.")
                    .font(Font.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center).padding(.top, -60)
                //          .padding(.horizontal, 20).padding(.top, 90).ignoresSafeArea()
                
                DataScannerView(
                    recognizedItems: $vm.recognizedItems,
                    recognizedDataType: vm.recognizedDataType,
                    recognizesMultipleItems: vm.recognizesMultipleItems)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { Color.gray.opacity(0.3) }
                .ignoresSafeArea(edges: .top)
                .id(vm.dataScannerViewId)
                //.sheet(isPresented: .constant(true)) {
                bottomContainerView
                
            }
        }
        
    }
    
    func findOverlappingStrings(in text: String, with words: [String]) -> [String] {
        var overlappingStrings: [String] = []
        
        for word in words {
            if text.contains(word) {
                overlappingStrings.append(word)
            }
        }
        
        return overlappingStrings
    }
    
    func detectLangauge(text: String, completion: @escaping (String?) -> Void) {
        let apiKey = "Your API Key Here"  // Replace with your actual API key.
        let apiUrl = "https://translation.googleapis.com/language/translate/v2/detect"
        
        let parameters: Parameters = [
            "q": text,
            "key": apiKey
        ]
        
        AF.request(apiUrl, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let data = json["data"] as? [String: Any], let detections = data["detections"] as? [[Any]], let detection = detections.first, let languageInfo = detection.first as? [String: Any], let languageCode = languageInfo["language"] as? String {
                    completion(languageCode)
                } else {
                    completion(nil)
                }
            case .failure(let error):
                print("Error: \(error)")
                completion(nil)
            }
        }
    }
    
    func translateText(sourceText: String, targetLanguage: String, apiKey: String, completion: @escaping (String?) -> Void) {
        let apiUrl = "https://translation.googleapis.com/language/translate/v2"
        let apiKey = "Your API Key Here" // Replace with your actual API key.
        
        let parameters: Parameters = [
            "q": sourceText,
            "target": targetLanguage,
            "key": apiKey
        ]
        
        AF.request(apiUrl, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let data = json["data"] as? [String: Any], let translations = data["translations"] as? [[String: Any]], let translation = translations.first, let translatedText = translation["translatedText"] as? String {
                    completion(translatedText)
                } else {
                    completion(nil)
                }
            case .failure(let error):
                print("Error: \(error)")
                completion(nil)
            }
        }
    }
    
    func testFunction(text: Any){
        if text is String{
            print("Text is a string")
        }
    }
    
    func printer(text: Any){
        print("test allergen 2")
        print(text)
    }
    
    func translateAllergens(targetLanguage: String, allergens: [String], completion: @escaping ([String]) -> Void) {
        var translatedAllergens: [String] = []
        let apiKey = "Your API Key Here"
        print("the detected language was ")
        print(targetLanguage)
        print("the allergens recieved were")
        print(allergens)
        
        
        // Create a dispatch group to track the completion of translations
        let dispatchGroup = DispatchGroup()
        
        for allergen in allergens {
            dispatchGroup.enter() // Enter the group before starting each translation
            
            translateText(sourceText: allergen, targetLanguage: targetLanguage, apiKey: apiKey) { translatedText in
                if let translatedText = translatedText {
                    translatedAllergens.append(translatedText)
                }
                
                dispatchGroup.leave() // Leave the group when the translation is done
            }
        }
        // Notify when all translations are complete
        dispatchGroup.notify(queue: .main) {
            completion(translatedAllergens)
        }
    }
    
    func printerA(text: [String]){
        for ele in text{
            print("test allergen ")
            print(ele)
        }
    }
    
    @State private var overlappingStrings: [String] = []
    @State private var foundAllergens: [String] = []
    
    private var bottomContainerView: some View {
        GeometryReader { geometry in
            // ScrollView {
            LazyVStack {
                Text("Your detected allergens:").multilineTextAlignment(.center).font(Font.system(size: 20, weight: .bold, design: .default)).padding(.bottom, 50).background(Color.white.opacity(0.7))
                
                ForEach(vm.recognizedItems) { item in
                    if case .text(let text) = item {
                        
                        var targetLanguage = ""
                        var start = detectLangauge(text: text.transcript) { detectedLanguage in
                            if let detectedLanguage = detectedLanguage {
                                targetLanguage = detectedLanguage
                                // Continue with your translation logic here
                                var test = translateAllergens(targetLanguage: targetLanguage, allergens: allergens) { translatedAllergens in
                                    // This block of code will be executed when translations are complete
                                    print("Translated allergens received: \(translatedAllergens)")
                                    overlappingStrings = findOverlappingStrings(in: text.transcript.lowercased(), with: translatedAllergens)
                                    var p = printer(text: text.transcript.lowercased())
                                    print("overlapping strings are ")
                                    print(overlappingStrings)
                                }
                                var translateBackToEng = translateAllergens(targetLanguage: "en", allergens: overlappingStrings) { translatedAllergens in
                                    foundAllergens = translatedAllergens
                                    foundAllergens.sort()
                                    
                                }
                            } else {
                                // Handle the case where language detection fails
                                // You can provide a default language or take some other action here
                            }
                        }
                        
                        VStack {
                            ForEach(foundAllergens, id: \.self) { string in
                                Text(string)
                                    .font(Font.system(size: 20, weight: .regular, design: .default))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.darkRed).background(Color.white.opacity(0.7))
                            }
                        }
                        
                        if overlappingStrings.isEmpty {
                            Text("No relevant allergens detected yet. Make sure all ingredients are in frame.")
                                .font(Font.system(size: 20, weight: .regular, design: .default))
                                .foregroundColor(Color.black)
                                .padding().background(Color.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, geometry.safeAreaInsets.bottom) // Adjust for safe area
            // }
        }
    }
}

struct Item: Identifiable {
    let id = UUID()
    var name: String
    var isChecked: Bool
}

struct ContentView_Previews: PreviewProvider {
    
    @EnvironmentObject var vm: AppViewModel
    
    // 2
    static var previews: some View {
        
        // 3
        ContentView().environmentObject(AppViewModel())
        
    }
}



