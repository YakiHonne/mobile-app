import share_handler_ios_models
import UniformTypeIdentifiers

class ShareViewController: ShareHandlerIosViewController {
    private let highlightPrefix = "YAKI_NIP84_HIGHLIGHT:"

    override func customSharedContent(for items: [NSExtensionItem]) async -> String? {
        let itemProviders = items.flatMap { $0.attachments ?? [] }

        for itemProvider in itemProviders where itemProvider.hasItemConformingToTypeIdentifier(
            UTType.propertyList.identifier
        ) {
            do {
                let item = try await itemProvider.loadItem(
                    forTypeIdentifier: UTType.propertyList.identifier,
                    options: nil
                )
                guard
                    let propertyList = item as? [String: Any],
                    let results = propertyList[
                        NSExtensionJavaScriptPreprocessingResultsKey
                    ] as? [String: Any],
                    let selectedText = results["selectedText"] as? String,
                    !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    let sourceUrl = results["sourceUrl"] as? String,
                    let url = URL(string: sourceUrl),
                    let scheme = url.scheme?.lowercased(),
                    ["http", "https"].contains(scheme),
                    url.host != nil
                else {
                    continue
                }

                let payload = [
                    "selectedText": selectedText.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                    "sourceUrl": sourceUrl,
                    "pageTitle": results["pageTitle"] as? String ?? "",
                    "context": results["context"] as? String ?? "",
                ]
                let data = try JSONSerialization.data(withJSONObject: payload)
                guard let json = String(data: data, encoding: .utf8) else {
                    continue
                }

                return highlightPrefix + json
            } catch {
                continue
            }
        }

        return nil
    }
}
