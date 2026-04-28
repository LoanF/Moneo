module.exports.readVersion = function (contents) {
  const match = contents.match(/^version:\s*(\d+\.\d+\.\d+)/m);
  return match ? match[1] : '0.0.0';
};

module.exports.writeVersion = function (contents, version) {
  const buildNumber = process.env.GITHUB_RUN_NUMBER || '0';
  return contents.replace(
    /^version:\s*[\d.]+\+\d+/m,
    `version: ${version}+${buildNumber}`
  );
};
