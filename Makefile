commit:
	git add  .
	git add -u
	git commit -m "$(MSG)"

push:	
	git push origin
	git push gitlab
	

copyApp:
	cp -R ./DerivedData/MDEtcher/Build/Products/Release/MDEtcher.app  ~/Applications/.
	