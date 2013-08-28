i = 0
dl = (err, stdout, stderr) ->
  console.log err, stdout, stderr
  ++i
  return if i > 36
  cmd = "wget --no-check-certificate https://cdn.360produkt.dk/360products/c31/Cap_custom/4860_4734/#{i}.jpg"
  console.log cmd
  (require "child_process").exec cmd, dl
dl()
