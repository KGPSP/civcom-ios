// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

@main struct PolicyChecks {
    static func main() {
        for value in ["soia.info", "https://matrix.soia.info", "https://matrix.soia.info/"] {
            precondition(CIVCOMPolicy.allowsAccountProvider(value), "Rejected official provider")
        }
        for value in ["matrix.org", "http://matrix.soia.info", "https://matrix.soia.info.evil", "https://matrix.soia.info:444", "https://user@matrix.soia.info", "https://matrix.soia.info/path", "soia.info.evil", "https://matrix.soia.info/?server=evil"] {
            precondition(!CIVCOMPolicy.allowsAccountProvider(value), "Accepted unapproved provider")
        }
        let callback = URL(string: "https://civcom.soia.info/oauth/ios/pl.gov.psp.civcom")!
        precondition(CIVCOMPolicy.isCallback(URL(string: callback.absoluteString + "?code=x&state=y")!, for: callback))
        for value in [callback.absoluteString + ".evil", "http://civcom.soia.info/oauth/ios/pl.gov.psp.civcom", "https://civcom.soia.info.evil/oauth/ios/pl.gov.psp.civcom", callback.absoluteString + "/extra"] {
            precondition(!CIVCOMPolicy.isCallback(URL(string: value)!, for: callback))
        }
        precondition(!CIVCOMPolicy.callsEnabled && !CIVCOMPolicy.mapsEnabled)
        print("CIVCOM policy behavioral checks passed")
    }
}
