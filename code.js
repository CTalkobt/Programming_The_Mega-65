// Adds a Copy button to every listing, and download links to listings
// whose <pre> has data-download="file1 file2 ...".
document.querySelectorAll("pre > code").forEach(function (code) {
  var pre = code.parentElement;
  var bar = document.createElement("div");
  bar.className = "codebar";

  var copy = document.createElement("button");
  copy.type = "button";
  copy.textContent = "Copy";
  copy.addEventListener("click", function () {
    var text = code.textContent;
    var done = function (label) {
      copy.textContent = label;
      setTimeout(function () { copy.textContent = "Copy"; }, 1500);
    };
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(
        function () { done("Copied"); },
        function () { done("Copy failed"); });
    } else {
      // file:// pages have no clipboard API: copy through a selection
      var area = document.createElement("textarea");
      area.value = text;
      area.style.position = "fixed";
      area.style.opacity = "0";
      document.body.appendChild(area);
      area.select();
      done(document.execCommand("copy") ? "Copied" : "Copy failed");
      document.body.removeChild(area);
    }
  });
  bar.appendChild(copy);

  (pre.dataset.download || "").split(/\s+/).filter(Boolean).forEach(function (path) {
    var link = document.createElement("a");
    link.href = path;
    link.setAttribute("download", "");
    link.textContent = path.split("/").pop();
    bar.appendChild(link);
  });

  pre.parentNode.insertBefore(bar, pre);
});
