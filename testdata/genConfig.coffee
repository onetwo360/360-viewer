config =
  width: 1000
  height: 447
  files: []
  baseUrl: "/testdata/"

for i in [1..52]
  config.files.push
    normal: "#{i}.jpg"
    zoom: "#{i}.jpg"

console.log "callback(#{JSON.stringify config, null, 2})"
