commit:
	git add  .
	git add -u
	git commit -m "$(MSG)"

push:	
	git push origin
	git push gitlab
	
buildDebug:
	 xcodebuild -scheme MDEtcher build
	
buildRelease:
	 xcodebuild -scheme MDEtcher -configuration Release build 	

copyApp: buildRelease
	rm -rf ~/Applications/MDEtcher.app
	mv -f ./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app  ~/Applications/.
	
runRelease:	buildRelease
	./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app/Contents/MacOS/MDEtcher	
	
runDebug:	buildDebug
	./DerivedData/MDEtcher/Build/Products/Debug/MDEtcher.app/Contents/MacOS/MDEtcher