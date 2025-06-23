import Foundation

enum Constants {
    static let accessKey = "L4dtaPMb7dhPhdWkPyLpM-xi8Av5HhRzHqoTXJMw--s"
    static let secretKey = "gwtWzsW5XdQnOROU-HCRixyaF2gjXKRDbd5_FTzAzmA"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseUR = {
        guard let baseURL = URL(string: "https://api.unsplash.com") else {
            assertionFailure("Invalid base URL")
            return
        }
    }
}
