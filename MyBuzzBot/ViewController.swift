import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var chatGPTResponseTextView: UITextView!
    @IBOutlet weak var chatGPTStatusLabel: UILabel!
    @IBOutlet weak var readAloudSwitchStatusLabel: UILabel!
    @IBOutlet weak var SaveStatusLabel: UILabel!
    @IBOutlet weak var HistorySwitchStatusLabel: UILabel!
    @IBOutlet weak var readAloudSwitch: UISwitch!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var burgerButtonTapped: UIButton!
    @IBOutlet weak var HistorySwitch: UISwitch!
    @IBOutlet weak var apiURLTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var ClearButton: UIButton!

    
    
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentDataTask: URLSessionDataTask? // Added to keep track of the current data task
    private let audioEngine = AVAudioEngine()
    let speechSynthesizer = AVSpeechSynthesizer()
    var menuIsHidden = true
    var conversationHistory: [[String: String]] = [] //for future me, once this is deleted then your back to standard before history with broken button
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer.delegate = self
        startStopButton.isEnabled = false
        chatGPTResponseTextView.isEditable = false
        transcriptionTextView.isEditable = false
        transcriptionTextView.text = "Your voice will appear here..."
        chatGPTStatusLabel.text = "Ai Status: Idle"
        speechSynthesizer.delegate = self
        menuCenterXConstraint.constant = menuView.frame.width + 400
        updateBorderColor()
        apiURLTextField.placeholder = "Enter AI API URL"
        apiKeyTextField.placeholder = "Enter AI API Key"
        modelTextField.placeholder = "Enter AI Model"
        apiURLTextField.delegate = self
        apiKeyTextField.delegate = self
        modelTextField.delegate = self
        let (apiURL, apiKey, model) = loadAPIConfig()
        apiURLTextField.text = apiURL
        apiKeyTextField.text = apiKey
        modelTextField.text = model
        ClearButton.tintColor = UIColor.red
        
        modelTextField.autocorrectionType = .no
        apiKeyTextField.autocorrectionType = .no
        apiURLTextField.autocorrectionType = .no
        modelTextField.spellCheckingType = .no
        apiKeyTextField.spellCheckingType = .no
        apiURLTextField.spellCheckingType = .no
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            default:
                isButtonEnabled = false
            }
            OperationQueue.main.addOperation {
                self.startStopButton.isEnabled = isButtonEnabled
            }
        }
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try! audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    
    func speak(text: String, volume: Float = 1.0) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category for playback. Error: \(error)")
        }
        
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.volume = volume
        speechSynthesizer.speak(speechUtterance)
        DispatchQueue.main.async {
            self.chatGPTStatusLabel.text = "Ai Status: Speaking..."
        }
    }
    
    @IBAction func burgerButtonTapped(_ sender: UIButton) {
        print("Burger button tapped")
        
        // Toggle the menu visibility
        menuIsHidden = !menuIsHidden
        updateBorderColor()
        view.endEditing(true)
        
        // Animate the menu sliding in or out
        UIView.animate(withDuration: 0.3, animations: {
            if self.menuIsHidden {
                // Hide the menu by setting the centerX constraint to half the negative width of the menu
                self.menuCenterXConstraint.constant = self.menuView.frame.width + 400
                print("Hiding menu. Constant: \(self.menuCenterXConstraint.constant)")
            } else {
                // Show the menu by setting the centerX constraint to align with the screen's centerX
                self.menuCenterXConstraint.constant = 0
                print("Showing menu. Constant: \(self.menuCenterXConstraint.constant)")
            }
            self.view.layoutIfNeeded() // This animates the constraint change
        }, completion: { _ in
            print("Animation completed. Menu isHidden: \(self.menuIsHidden)")
        })
    }
    
    @IBAction func readAloudSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            readAloudSwitchStatusLabel.text = "Read aloud: Enabled"
        } else {
            readAloudSwitchStatusLabel.text = "Read aloud: Disabled"
        }
    }
    
    @IBAction func HistorySwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            HistorySwitchStatusLabel.text = "History: Enabled"
        } else {
            HistorySwitchStatusLabel.text = "History: Disabled"
        }
    }
    
    @IBAction func startStopButtonTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startStopButton.setTitle("Start Listening", for: .normal)
            statusLabel.text = ""
            stopSpeaking()
            
            if let transcription = transcriptionTextView.text {
                chatGPTStatusLabel.text = "Ai Status: Sending Request..."
                fetchChatGPTResponse(for: transcription)
                self.view.layoutIfNeeded()
            }
        } else {
            startListening()
            startStopButton.setTitle("Stop Listening", for: .normal)
            statusLabel.text = ""
            //resetChatGPTResponse()
            chatGPTStatusLabel.text = "Ai Status: Listening..."
            self.view.layoutIfNeeded()
            
            
            
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech finished")
        chatGPTStatusLabel.text = "Ai Status: Request Shown"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Update the SaveStatusLabel text back to its original state or to any other message
            self.chatGPTStatusLabel.text = "Ai Status: Idle"
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("Speech paused")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("Speech continued")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Speech cancelled")
    }
    
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == apiURLTextField && textField.text == "Enter AI API URL" {
            textField.text = ""
        } else if textField == apiKeyTextField && textField.text == "Enter AI API Key" {
            textField.text = ""
        }
    }
    
    func saveAPIConfig(apiURL: String, apiKey: String, model: String) {
        UserDefaults.standard.set(apiURL, forKey: "APIURL")
        UserDefaults.standard.set(apiKey, forKey: "APIKey")
        UserDefaults.standard.set(model, forKey: "AIModel")
    }
    
    func loadAPIConfig() -> (apiURL: String?, apiKey: String?, model: String?) {
        let apiURL = UserDefaults.standard.string(forKey: "APIURL")
        let apiKey = UserDefaults.standard.string(forKey: "APIKey")
        let model = UserDefaults.standard.string(forKey: "AIModel")
        return (apiURL, apiKey, model)
    }
    
    
    func updateBorderColor() {
        if self.traitCollection.userInterfaceStyle == .dark {
            
            menuView.layer.borderColor = UIColor.white.cgColor
        } else {
            menuView.layer.borderColor = UIColor.black.cgColor
        }
        menuView.layer.borderWidth = 5
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let apiURL = apiURLTextField.text, !apiURL.isEmpty,
              let apiKey = apiKeyTextField.text, !apiKey.isEmpty,
              let model = modelTextField.text, !model.isEmpty else {
            print("API URL, API Key, or Model is empty.")
            return
        }
        self.SaveStatusLabel.text = "Saved!"
        saveAPIConfig(apiURL: apiURL, apiKey: apiKey, model: model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Update the SaveStatusLabel text back to its original state or to any other message
            self.SaveStatusLabel.text = ""
        }
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionTask = nil
            resetAudioSession()
        }
        
        // Reset conversation history
        conversationHistory = []
        
        startStopButton.setTitle("Start Listening", for: .normal)
        statusLabel.text = ""
        transcriptionTextView.text = "Your voice will appear here..."
        chatGPTResponseTextView.text = "Ai Response"
        chatGPTStatusLabel.text = "Ai Status: Idle"
        
        
        stopSpeaking()
        
        currentDataTask?.cancel() // Cancel the current data task
        currentDataTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.playback, mode: .default, options: []) // Or another category that fits your app's state
            try audioSession.setActive(true)
        } catch {
            print("Error resetting audio session: \(error)")
        }
    }
    
    private func resetAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.playback, mode: .default, options: []) // Adjust as needed
            try audioSession.setActive(true)
        } catch {
            print("Error resetting audio session: \(error)")
        }
    }
    
    private func resetChatGPTResponse() {
        chatGPTResponseTextView.text = "Ai Response"
    }
    
    private func startListening() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error setting audio session for recording: \(error)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a recognition request") }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                self?.transcriptionTextView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                self?.startStopButton.setTitle("Start Listening", for: .normal)
                self?.statusLabel.text = ""
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try! audioEngine.start()
    }
    
    func fetchChatGPTResponse(for userInput: String) {
        let (apiURL, apiKey, model) = loadAPIConfig() // Updated to include model
        guard let urlString = apiURL, let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.chatGPTResponseTextView.text = "Error: Invalid API URL."
                self.chatGPTStatusLabel.text = "Ai Status: Error"
            }
            return
        }
        guard let apiKeyValue = apiKey else {
            DispatchQueue.main.async {
                self.chatGPTResponseTextView.text = "Error: API Key is missing."
                self.chatGPTStatusLabel.text = "Ai Status: Error"
            }
            return
        }
        guard let modelValue = model, !modelValue.isEmpty else { // Ensure the model is not empty
            DispatchQueue.main.async {
                self.chatGPTResponseTextView.text = "Error: AI Model is missing."
                self.chatGPTStatusLabel.text = "Ai Status: Error"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKeyValue)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let isHistoryEnabled = HistorySwitch.isOn
        if isHistoryEnabled {
            conversationHistory.append(["role": "user", "content": userInput])
        }
        let messagesBody = isHistoryEnabled ? conversationHistory : [["role": "user", "content": userInput]]
        
        let requestBody: [String: Any] = [
            "model": modelValue, // Use the model value from the text field
            "messages": messagesBody
        ]
        
        do {
            let requestBodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = requestBodyData
        } catch {
            DispatchQueue.main.async {
                self.chatGPTResponseTextView.text = "Error creating request body: \(error)"
                self.chatGPTStatusLabel.text = "Ai Status: Error"
            }
            return
        }
        
        currentDataTask?.cancel() // Cancel any existing task before starting a new one
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.chatGPTStatusLabel.text = "Ai Status: Error"
                    self?.chatGPTResponseTextView.text = "Network request failed: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self?.chatGPTStatusLabel.text = "Ai Status: Error"
                    self?.chatGPTResponseTextView.text = "Error: HTTP request failed."
                }
                return
            }
            

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.chatGPTStatusLabel.text = "Ai Status: Error"
                    self?.chatGPTResponseTextView.text = "Error: No data received."
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responses = jsonResponse["choices"] as? [[String: Any]],
                   let firstResponse = responses.first,
                   let text = firstResponse["message"] as? [String: String],
                   let content = text["content"] {
                    
                    DispatchQueue.main.async {
                        if self?.HistorySwitch.isOn ?? false {
                            self?.conversationHistory.append(["role": "ai", "content": content])
                        }
                        
                        var conversationText = ""
                        if self?.HistorySwitch.isOn ?? false {
                            for message in self!.conversationHistory {
                                if let role = message["role"], let content = message["content"] {
                                    conversationText += (role == "user" ? "You: " : "AI: ") + content + "\r\n\r\n"
                                }
                            }
                        } else {
                            conversationText = "You: \(userInput)\nAI: \(content)"
                        }
                        self?.chatGPTResponseTextView.text = conversationText
                        
                        if !(self?.readAloudSwitch.isOn ?? false) {
                            self?.chatGPTStatusLabel.text = "Ai Status: Idle"
                        } else {
                            self?.speak(text: content, volume: 1.0)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.chatGPTResponseTextView.text = "Error parsing response: \(error)"
                    self?.chatGPTStatusLabel.text = "Ai Status: Error"
                }
            }
        }
        currentDataTask = task
        task.resume()
    }
}
