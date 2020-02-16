commit:
	git add  .
	git add -u
	git commit -m "$(MSG)"

push:	
	git push origin
	git push gitlab
	
versioning:
	/bin/sh autoBuildNo.sh 
	swift mkVersion.swift	
	
debug: versioning
	 xcodebuild -scheme MDEtcher build
	
release: versioning
	 xcodebuild -scheme MDEtcher -configuration Release build 	

copyApp: release
	rm -rf ~/Applications/MDEtcher.app
	mv -f ./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app  ~/Applications/.
	
runRelease:	release
	./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app/Contents/MacOS/MDEtcher	
	
runDebug:	debug
	./DerivedData/MDEtcher/Build/Products/Debug/MDEtcher.app/Contents/MacOS/MDEtcher
	
zip: release
	cd ./DerivedData/MDEtcher/Build/Products/Release; zip -r MDEtcher.app.zip ./MDEtcher.app
	mv ./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app.zip .
	
clean:
	rm -rf ./DerivedData/MDEtcher/Build
	rm -f MDEtcher.app.zip
	
run: runDebug
	
	