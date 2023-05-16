## Installation

### Swift Package Manager (Package.swift file)

If your project utilizes its own Package.swift file, you have the option to include BMXSDK as a dependency within that file. Follow the steps below to add the BMXSDK package to your dependencies list.
1. Include the BMXSDK package in your list of dependencies:
```
dependencies: [
    .package(name: "BMXSDK", url: "https://github.com/runslikebutter/ios-sdk.git", .upToNextMajor(from: "2.3.1"))
],
```
2. Add a dependency on the BmxCore and BmxCall products to the targets that will use BMXSDK within your application:
```
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "BmxCore", package: "BMXSDK"),
        .product(name: "BmxCall", package: "BMXSDK")
    ]
)
```
### Swift Package Manager (Xcode project)
1. In Xcode, navigate to File > Add Packages....
2. In the dialog box that appears, paste the URL of the BMXSDK repository (https://github.com/runslikebutter/ios-sdk.git) into the search bar. Wait for the ios-sdk package to appear in the search results.
3. Choose the desired version of the BMXSDK package, then click Add Package.
4. In the list of available packages, select both the BmxCore and BmxCall packages.
5. Finally, click Add Package to add the selected packages to your project.
