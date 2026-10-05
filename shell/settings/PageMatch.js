.pragma library
// Registry search matching, shared by the sidebar and the search-jump so both
// agree on what a query hits.

function matches(page, query) {
    if (query === "") return true
    var q = query.toLowerCase()
    return (page.id + " " + page.label + " " + (page.keywords || "")).toLowerCase().indexOf(q) !== -1
}

function sectionMatches(section, query) {
    for (var i = 0; i < section.pages.length; i++)
        if (matches(section.pages[i], query)) return true
    return false
}

function anyMatches(sections, query) {
    for (var i = 0; i < sections.length; i++)
        if (sectionMatches(sections[i], query)) return true
    return false
}
