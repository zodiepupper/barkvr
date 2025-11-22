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

cd linux
zip linux_arm linux_arm -r
zip linux_x86_64 linux_x86_64 -r
cd ../win/
zip win_arm win_arm -r
zip win_x86_64 win_x86_64 -r
cd ../macos/
zip macos_arm macos_arm -r
zip macos_x86_64 macos_x86_64 -r
cd ..

echo "removing existing exported directory so it will be cleared"

rm -rfv ./exported/

echo "creating new, clean, exported directory"

mkdir ./exported/

echo "moving all zip and apk files to the exported directory"

mv -t exported ./*/*.zip ./*/*.apk

