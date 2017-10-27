
require "json"
require "shell_out"
require "exit_on_error"

PACKGE_FILE = "package.json"
case ARGV[0]?
when "version"
  data = JSON.parse File.read(PACKGE_FILE)
  version = data["version"]? || raise Exception.new("No version in package.json found.")
  puts version

when "info"
  data = JSON.parse File.read(PACKGE_FILE)
  puts data.to_pretty_json

when "bump"
  if !shell_out("git status --porcelain").strip.empty?
    Exit.error("repo is not clean")
  end

  data = JSON.parse File.read(PACKGE_FILE)
  version = data["version"]? || raise Exception.new("No version in #{PACKGE_FILE} found.")

  pieces = version.to_s.split(".")
  major = pieces.shift.to_i
  minor = pieces.shift.to_i
  patch = pieces.shift.to_i

  case ARGV[1]?
  when "major"
    major += 1
    minor = 0
    patch = 0
  when "minor"
    minor += 1
    patch = 0
  when "patch"
    patch += 1
  else
    raise Exception.new("Invalid bump: #{ARGV[1]?.inspect}")
  end

  new_ver = "#{major}.#{minor}.#{patch}"
  data.as_h["version"] = new_ver
  File.write(PACKGE_FILE, data.to_pretty_json)

  puts "OLD: #{version}"
  puts "NEW: #{new_ver}"
  shell_out("git add #{PACKGE_FILE}")
  shell_out("git", ["commit", "-m", "Bump: v#{new_ver}"])
  shell_out("git tag v#{new_ver}")
  shell_out("git push")
  shell_out("git push origin v#{new_ver}")

else
  if ARGV.empty?
    raise Exception.new("Invalid request: [no options specified]")
  else
    raise Exception.new("Invalid request: #{ARGV.map(&.inspect).join(" ")}")
  end
end
