var ExtensionPreprocessingJS = function () {};

ExtensionPreprocessingJS.prototype = {
  run: function (arguments) {
    var selection = window.getSelection();
    var selectedText = selection ? selection.toString().trim() : "";
    var paragraph = "";

    if (selection && selection.rangeCount > 0) {
      var range = selection.getRangeAt(0);
      var paragraphFor = function (node) {
        var element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
        return element ? element.closest("p, blockquote, li") : null;
      };
      var startBlock = paragraphFor(range.startContainer);
      var endBlock = paragraphFor(range.endContainer);
      var block = startBlock && startBlock === endBlock &&
        !startBlock.querySelector("p, blockquote, li") ? startBlock : null;

      if (block) {
        paragraph = block.innerText || block.textContent || "";
      }
    }

    arguments.completionFunction({
      selectedText: selectedText,
      sourceUrl: window.location.href,
      pageTitle: document.title || "",
      context: paragraph.trim(),
    });
  },
};

var ExtensionPreprocessingJS = new ExtensionPreprocessingJS();
