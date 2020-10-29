/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Task {
    /// Searches for a .contactDetails answer in the results and returns the firstName and lastName combined.
    /// Falls back to the value of `label` if no answer could be found
    var contactName: String? {
        result?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(let firstName, let lastName, _, _):
                    return [firstName, lastName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                default:
                    return nil
                }
            }
            .first ?? label
    }
    
    /// Searches for a .contactDetails answer in the results and returns the firstName.
    /// Falls back to the value of `label` if answer could be found
    var contactFirstName: String? {
        result?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(let firstName, _, _, _):
                    return firstName
                default:
                    return nil
                }
            }
            .first ?? label
    }
}