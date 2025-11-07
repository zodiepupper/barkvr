echo "building project"

godot --headless --export-debug "Windows x86_64" ../project.godot
godot --headless --export-debug "Windows arm64" ../project.godot
godot --headless --export-debug "Linux/X11 x86_64" ../project.godot
godot --headless --export-debug "Linux/X11 arm64" ../project.godot
godot --headless --export-debug "macOS arm64" ../project.godot
godot --headless --export-debug "Khronos" ../project.godot
godot --headless --export-debug "Lynx" ../project.godot
godot --headless --export-debug "Meta" ../project.godot
godot --headless --export-debug "Meta no boundary" ../project.godot
godot --headless --export-debug "Pico" ../project.godot
godot --headless --export-debug "Magicleap" ../project.godot
godot --headless --export-debug "Android" ../project.godot

echo "compressing builds into zip files"

zip ./linux/linux_arm ./linux/linux_arm -r
zip ./linux/linux_x86_64 ./linux/linux_x86_64 -r
zip ./win/win_arm ./win/win_arm -r
zip ./win/win_x86_64 ./win/win_x86_64 -r
zip ./macos/macos_arm ./macos/macos_arm -r
zip ./macos/macos_x86_64 ./macos/macos_x86_64 -r

echo "removing existing exported directory so it will be cleared"

rm -rfv ./exported/

echo "creating new, clean, exported directory"

mkdir ./exported/

echo "moving all zip and apk files to the exported directory"

mv -t exported ./*/*.zip ./*/*.apk

