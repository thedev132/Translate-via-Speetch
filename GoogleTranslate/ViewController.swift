import UIKit
import Speech
import AVFoundation
import Firebase
import MLKitTranslate

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UINavigationBar.appearance().isHidden = true
        view.backgroundColor = .init(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
        recordButton.frame = view.bounds
        blueView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 75)
        view.addSubview(blueView)
        view.addSubview(recordButton)
        
        requestTranscribePermissions()
        recordingSession = AVAudioSession.sharedInstance()

        do {
              try recordingSession.setCategory(.playAndRecord)
              try recordingSession.setMode(.default)
              try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
              try recordingSession.overrideOutputAudioPort(.speaker)

        } catch {
            // failed to record!
        }
    }
    
    private var recordButton: UIButton = {
        var recordButton = UIButton()
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(.black, for: .normal)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        return recordButton
    }()
    
    private var blueView: UIView = {
       var views = UIView()
        views.backgroundColor = .init(red: 52/255, green: 116/255, blue: 226/255, alpha: 1)
        return views
    }()
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
            let url =  getDocumentsDirectory().appendingPathComponent("recording.m4a").absoluteString
            transcribeAudio(url: URL(string: url)!)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
        }
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func transcribeAudio(url: URL) {
        //ANything
        var apple = 1
        apple = 2
        let orange = 3
        
        
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ar"))
        let request = SFSpeechURLRecognitionRequest(url: url)
    
        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }
            

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                print(result.bestTranscription.formattedString)
                let options = TranslatorOptions(sourceLanguage: .arabic, targetLanguage: .english)
                let translator = Translator.translator(options: options)
                let conditions = ModelDownloadConditions(
                    allowsCellularAccess: false,
                    allowsBackgroundDownloading: true
                )
                translator.downloadModelIfNeeded(with: conditions) { error in
                    guard error == nil else { return }

                    // Model downloaded successfully. Okay to start translating.
                    translator.translate(result.bestTranscription.formattedString) { translatedText, error in
                        guard error == nil, let translatedText = translatedText else { return }
                        print(translatedText)
                        let utterance = AVSpeechUtterance(string: translatedText)
                        utterance.voice = AVSpeechSynthesisVoice(language: "en")
                        utterance.rate = 0.5
                        utterance.volume = 1
                        let synthesizer = AVSpeechSynthesizer()
                        synthesizer.speak(utterance)
                        // Translation succeeded.
                    }
                }
            }
        }
    }
    
}

