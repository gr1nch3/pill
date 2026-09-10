// ponytail: the one shell-quoting helper. Config/Theme/Wallpaper embed paths
// in bash -c strings; quote here, never inline .replace() at use sites.
function q(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}
