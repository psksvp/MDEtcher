commit:
	git add  .
	git add -u
	git commit -m "$(MSG)"

push:	
	git push origin
	git push gitlab
	

copyApp:
	rm -rf ~/Applications/MDEtcher.app
	mv -f ./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app  ~/Applications/.
	