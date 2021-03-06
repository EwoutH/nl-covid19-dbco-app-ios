/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

enum CaseManagingError: Error {
    case noCaseData
    case questionnaireNotFound
    case couldNotLoadTasks(NetworkError)
    case couldNotLoadQuestionnaires(NetworkError)
}

/// Loads tasks and questionnaires.
/// Facilitates storing and uploading results to the backend.
/// Publishes updates to the internal store via [CaseManagerListener](x-source-tag://CaseManagerListener)
///
/// # See also:
/// [Task](x-source-tag://Task),
/// [Questionnaire](x-source-tag://Questionnaire)
///
/// - Tag: CaseManaging
protocol CaseManaging {
    
    init()
    
    var hasCaseData: Bool { get }
    
    /// Indicates that alls the tasks are uploaded to the backend in their current state
    var isSynced: Bool { get }
    
    var dateOfSymptomOnset: Date { get }
    var tasks: [Task] { get }
    
    /// Returns the [Questionnaire](x-source-tag://Questionnaire) associated with a task.
    /// Throws an `notPaired` error when called befored paired.
    /// Throws an `questionnaireNotFound` error when there's no suitable questionnaire  for the supplied task
    func questionnaire(for task: Task) throws -> Questionnaire
    
    func loadCaseData(completion: @escaping (_ success: Bool, _ error: CaseManagingError?) -> Void)
    
    /// Clears all stored data. Using any method or property except for `hasCaseData` on CaseManager before pairing and loading the data again is an invalid operation.
    /// Throws an `notPaired` error when called befored paired.
    func removeCaseData() throws
    
    /// Adds a listener
    /// - parameter listener: The object conforming to [CaseManagerListener](x-source-tag://CaseManagerListener) that will receive updates. Will be stored with a weak reference
    func addListener(_ listener: CaseManagerListener)
    
    /// Saves updates to a task if a task with the same uuid is already managed, or stores a new task.
    /// Throws an `notPaired` error when called befored paired.
    func save(_ task: Task) throws
    
    /// Uploads all the tasks to the backend.
    /// Throws an `notPaired` error when called befored paired.
    ///
    /// - parameter completionHandler: The closure to be called after the upload was finished.
    func sync(completionHandler: ((_ success: Bool) -> Void)?) throws
}

/// - Tag: CaseManagerListener
protocol CaseManagerListener: class {
    /// Called after updates are made to the managed tasks
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging)
    
    /// Called after tasks were uploaded to the backend
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging)
}

/// - Tag: CaseManager
final class CaseManager: CaseManaging, Logging {
    
    private struct Constants {
        static let keychainService = "UserTest-Mocks"
    }
    
    private struct ListenerWrapper {
        weak var listener: CaseManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    @Keychain(name: "appData", service: Constants.keychainService, clearOnReinstall: true)
    private var appData: AppData = .empty
    
    @UserDefaults(key: "isSynced")
    private(set) var isSynced: Bool = true {
        didSet {
            listeners.forEach { $0.listener?.caseManagerDidUpdateSyncState(self) }
        }
    }
    
    private(set) var tasks: [Task] {
        get { appData.tasks }
        set { appData.tasks = newValue }
    }
    
    private var questionnaires: [Questionnaire] {
        get { appData.questionnaires }
        set { appData.questionnaires = newValue }
    }
    
    private(set) var dateOfSymptomOnset: Date {
        get { appData.dateOfSymptomOnset }
        set { appData.dateOfSymptomOnset = newValue }
    }
    
    var hasCaseData: Bool {
        $appData.exists && !questionnaires.isEmpty
    }
    
    func loadCaseData(completion: @escaping (Bool, CaseManagingError?) -> Void) {
        func loadTasksIfNeeded() {
            guard appData.tasks.isEmpty else { return loadQuestionnairesIfNeeded() }
            
            do {
                let identifier = try Services.pairingManager.caseToken()
                Services.networkManager.getCase(identifier: identifier) {
                    switch $0 {
                    case .success(let result):
                        self.tasks = result.tasks
                        self.dateOfSymptomOnset = result.dateOfSymptomOnset
                        
                        loadQuestionnairesIfNeeded()
                    case .failure(let error):
                        completion(false, .couldNotLoadTasks(error))
                    }
                }
            } catch {
                return completion(false, .noCaseData)
            }
        }
        
        func loadQuestionnairesIfNeeded() {
            guard appData.questionnaires.isEmpty else { return finish() }
            
            Services.networkManager.getQuestionnaires {
                switch $0 {
                case .success(let questionnaires):
                    self.setQuestionnaires(questionnaires)
                    
                    finish()
                case .failure(let error):
                    completion(false, .couldNotLoadQuestionnaires(error))
                }
            }
        }
        
        func finish() {
            completion(true, nil)
            self.listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
        }
        
        loadTasksIfNeeded()
    }
    
    func removeCaseData() throws {
        $appData.clearData()
    }
    
    /// Set the questionnaires from the api call result
    ///
    /// The app injects a question of the `lastExposureDate` in the contact [Questionnaire](x-source-tag://Questionnaire) to support the `dateOfLastExposure` property at the [Task](x-source-tag://Task) level.
    /// Answers to a question with this type should not be sent to the backend.
    ///
    /// # See also
    /// [lastExposureDate](x-source-tag://lastExposureDate)
    ///
    /// - Tag: CaseManager.setQuestionnaires
    private func setQuestionnaires(_ questionnaires: [Questionnaire]) {
        func injectingLastExposureDateIfNeeded(_ questionnaire: Questionnaire) -> Questionnaire {
            switch questionnaire.taskType {
            case .contact:
                var questions = questionnaire.questions
                
                let lastExposureQuestion = Question(uuid: UUID(),
                                                    group: .contactDetails,
                                                    questionType: .lastExposureDate,
                                                    label: .contactInformationLastExposure,
                                                    description: nil,
                                                    relevantForCategories: [.category1, .category2a, .category2b, .category3],
                                                    answerOptions: nil)
                
                // Find the index of the question modifying the communication type. (Via triggers)
                let communicationQuestionIndex = questionnaire.questions
                    .firstIndex { $0.answerOptions?.contains { $0.trigger == .setCommunicationToIndex } == true }
                
                if let index = communicationQuestionIndex {
                    questions.insert(lastExposureQuestion, at: index)
                } else {
                    questions.append(lastExposureQuestion)
                }
                
                return Questionnaire(uuid: questionnaire.uuid,
                                     taskType: questionnaire.taskType,
                                     questions: questions)
            }
        }
        
        self.questionnaires = questionnaires.map(injectingLastExposureDateIfNeeded)
    }
    
    /// - Tag: CaseManager.questionnaire
    func questionnaire(for task: Task) throws -> Questionnaire {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        
        guard let questionnaire = questionnaires.first(where: { $0.taskType == task.taskType }) else {
            logError("Could not find applicable questionnaire")
            throw CaseManagingError.questionnaireNotFound
        }
        
        return questionnaire
    }
    
    func save(_ task: Task) throws {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        
        func storeNewTask() -> Int {
            tasks.append(task)
            return tasks.count - 1
        }
        
        let index = tasks.lastIndex { $0.uuid == task.uuid } ?? storeNewTask()
        
        let questionnaire = try self.questionnaire(for: task)
        
        // Update task type content
        switch tasks[index].taskType {
        case .contact:
            tasks[index].contact = task.contact
        }
        
        let currentAnswers = tasks[index].result?.answers ?? []
        let newAnswers = task.result?.answers ?? []
        
        // Ensure we have (empty) answers for all necessary questions
        // Updating existing any answers
        func answerForQuestion(_ question: Question) -> Answer {
            let currentAnswer = currentAnswers.first { $0.questionUuid == question.uuid }
            let newAnswer = newAnswers.first { $0.questionUuid == question.uuid }
            
            switch (currentAnswer, newAnswer) {
            case (.some(let current), .some(let new)):
                let isModified = current.value != new.value
                let modifiedDate = isModified ? Date() : current.lastModified
                return Answer(uuid: current.uuid, questionUuid: question.uuid, lastModified: modifiedDate, value: new.value)
            case (.none, .some(let new)):
                return Answer(uuid: new.uuid, questionUuid: question.uuid, lastModified: Date(), value: new.value)
            case (.some(let current), .none):
                return current
            case (.none, .none):
                return question.emptyAnswer
            }
        }
        
        let answers = questionnaire.questions
            .filter { $0.relevantForCategories.contains(tasks[index].contact.category) }
            .map(answerForQuestion)
        
        tasks[index].result = QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: answers)
        
        isSynced = false
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
    }
    
    func addListener(_ listener: CaseManagerListener) {
        listeners.append(ListenerWrapper(listener: listener))
    }
    
    func sync(completionHandler: ((Bool) -> Void)?) throws {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        
        do {
            let value = Case(dateOfSymptomOnset: dateOfSymptomOnset, tasks: tasks)
            let identifier = try Services.pairingManager.caseToken()
            Services.networkManager.putCase(identifier: identifier, value: value) {
                switch $0 {
                case .success:
                    self.isSynced = true
                    completionHandler?(true)
                case .failure(let error):
                    self.logError("Could not sync case: \(error)")
                    completionHandler?(false)
                }
            }
        } catch {
            completionHandler?(false)
            return
        }
    }
    
}
