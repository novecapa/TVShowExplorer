//
//  Log.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

enum Log {

    static func thisRequest(_ response: HTTPURLResponse, data: Data, request: URLRequest) {
        #if DEBUG
        let code = response.statusCode
        let url  = response.url?.absoluteString ?? ""
        let icon = (200..<300).contains(code) ? "✅" : "❌"
        print("------------------------------------------")
        print("\(icon) 🔽 [\(code)] \(url)")
        print("\(data.prettyPrintedJSONString ?? "")")
        print("\(icon) 🔼 [\(code)] \(url)")
        if let curl = convertToCurl(request: request) {
            print("🔽🔽 cURL 🔽🔽")
            print(curl)
            print("🔼🔼 cURL 🔼🔼")
        }
        print("------------------------------------------")
        #endif
    }

    static func convertToCurl(request: URLRequest) -> String? {
        guard let url = request.url else { return nil }
        var curlCommand = "curl"
        if let httpMethod = request.httpMethod {
            curlCommand += " -X \(httpMethod)"
        }
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                curlCommand += " -H \"\(key): \(value)\""
            }
        }
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            curlCommand += " -d '\(bodyString)'"
        }
        curlCommand += " \"\(url.absoluteString)\""

        return curlCommand
    }
}

// MARK: - Data extension

private extension Data {
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self,
                                                             options: []),
              let data = try? JSONSerialization.data(withJSONObject: object,
                                                     options: [.prettyPrinted, .withoutEscapingSlashes]),
              let prettyPrintedString = String(data: data,
                                               encoding: String.Encoding.utf8) else { return nil }
        return prettyPrintedString
    }
}
