/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// - Tag: AnswerTrigger
enum AnswerTrigger: String, Codable {
    case setCommunicationToIndex = "communication_index"
    case setCommunicationToStaff = "communication_staff"
}

struct AnswerOption: Codable {
    let label: String
    let value: String
    let trigger: AnswerTrigger?
}

/// - Tag: Question
struct Question: Codable {
    enum Group: String, Codable {
        case classification
        case contactDetails = "contactdetails"
        case other
    }
    
    enum QuestionType: String, Codable {
        case classificationDetails = "classificationdetails"
        case date
        case contactDetails = "contactdetails"
        case contactDetailsFull = "contactdetails_full"
        case open
        case multipleChoice = "multiplechoice"
        
        /// This case is not supported in the API.
        /// The app injects a question of this type in the contact [Questionnaire](x-source-tag://Questionnaire) to support the dateOfLastExposure property at the Task level.
        /// Answers to a question with this type should not be sent to the backend.
        ///
        /// # See also
        /// [setQuestionnaires(_ questionnaires: [Questionnaire])](x-source-tag://CaseManager.setQuestionnaires)
        ///
        /// - Tag: lastExposureDate
        case lastExposureDate
    }

    let uuid: UUID
    let group: Group
    let questionType: QuestionType
    let label: String?
    let description: String?
    let relevantForCategories: [Task.Contact.Category]
    let answerOptions: [AnswerOption]?
    
    init(uuid: UUID, group: Group, questionType: QuestionType, label: String?, description: String?, relevantForCategories: [Task.Contact.Category], answerOptions: [AnswerOption]?) {
        self.uuid = uuid
        self.group = group
        self.questionType = questionType
        self.label = label
        self.description = description
        self.relevantForCategories = relevantForCategories
        self.answerOptions = answerOptions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        group = try container.decode(Group.self, forKey: .group)
        questionType = try container.decode(QuestionType.self, forKey: .questionType)
        label = try container.decode(String?.self, forKey: .label)
        description = try container.decode(String?.self, forKey: .description)
        
        struct CategoryWrapper: Codable {
            let category: Task.Contact.Category
        }
        
        let categories = try container.decode([CategoryWrapper].self, forKey: .relevantForCategories)
        relevantForCategories = categories.map { $0.category }
        
        answerOptions = try? container.decode([AnswerOption]?.self, forKey: .answerOptions)
    }
}

/// Represents the questionnaires needed to complete tasks.
/// Questionnaires are linked to tasks via the taskType property.
/// Currently only the `contact` task is supported.
///
/// # See also:
/// [Task](x-source-tag://Task),
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: Questionnaire
struct Questionnaire: Codable {
    let uuid: UUID
    let taskType: Task.TaskType
    let questions: [Question]
}

/// - Tag: Answer
struct Answer {
    let uuid: UUID
    let questionUuid: UUID
    let lastModified: Date
    
    enum Value: CustomStringConvertible, Equatable {
        case classificationDetails(category1Risk: Bool?,
                                   category2aRisk: Bool?,
                                   category2bRisk: Bool?,
                                   category3Risk: Bool?)
        case contactDetails(firstName: String?,
                            lastName: String?,
                            email: String?,
                            phoneNumber: String?)
        case contactDetailsFull(firstName: String?,
                            lastName: String?,
                            email: String?,
                            phoneNumber: String?)
        case date(Date?)
        case open(String?)
        case multipleChoice(AnswerOption?)
        
        /// See [lastExposureDate](x-source-tag://lastExposureDate)
        case lastExposureDate(Date?)
        
        var description: String {
            switch self {
            case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
                return "classificationDetails(\(String(describing: category1Risk)), \(String(describing: category2aRisk)), \(String(describing: category2bRisk)), \(String(describing: category3Risk)))"
            case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
                return "contactDetails(\(String(describing: firstName)), \(String(describing: lastName)), \(String(describing: email)), \(String(describing: phoneNumber)))"
            case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
                return "contactDetailsFull(\(String(describing: firstName)), \(String(describing: lastName)), \(String(describing: email)), \(String(describing: phoneNumber)))"
            case .date(let date):
                return "date(\(String(describing: date)))"
            case .lastExposureDate(let date):
                return "lastExposureDate(\(String(describing: date)))"
            case .open(let value):
                return "open(\(String(describing: value)))"
            case .multipleChoice(let option):
                return "multipleChoice(\(String(describing: option)))"
            }
        }
        
        static func == (lhs: Answer.Value, rhs: Answer.Value) -> Bool {
            return lhs.description == rhs.description
        }
    }
    
    var value: Value
}

/// Represents a filled out questionnaire
///
/// # See also:
/// [Questionnaire](x-source-tag://Questionnaire),
/// [Task](x-source-tag://Task),
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: QuestionnaireResult
struct QuestionnaireResult {
    /// The identifier of the [Questionnaire](x-source-tag://Questionnaire) this result belongs to
    let questionnaireUuid: UUID
    var answers: [Answer]
}