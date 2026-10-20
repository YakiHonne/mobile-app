import SafariServices

// This prototype hands drafts to the app through a user-tapped URL, not
// native messaging. Keep the extension's required entry point minimal.
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        context.completeRequest(returningItems: [], completionHandler: nil)
    }
}
