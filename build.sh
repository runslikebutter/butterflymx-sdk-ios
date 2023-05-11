
# Release dir path
OUTPUT_DIR_PATH=$1
SDK_NAME=$2

if [[ -z $1 ]]; then
    echo "Output dir was not set. try to run ./build.sh folder_name"
    exit 1;
fi

if [[ -z $2 ]]; then
    echo "SDK name was not set. try to run ./build.sh folder_name sdk_name"
    exit 1;
fi

function archivePathSimulator {
  local DIR=${OUTPUT_DIR_PATH}/archives/"${1}-SIMULATOR"
  echo "${DIR}"
}

function archivePathDevice {
  local DIR=${OUTPUT_DIR_PATH}/archives/"${1}-DEVICE"
  echo "${DIR}"
}

# Archive takes 3 params
#
# 1st == SCHEME
# 2nd == destination
# 3rd == archivePath
function archive {
    echo "▸ Starts archiving the scheme: ${1} for destination: ${2};\n▸ Archive path: ${3}.xcarchive"
    xcodebuild archive \
    -workspace ButterflyMXSDK.xcworkspace \
    -scheme ${1} \
    -destination "${2}" \
    -archivePath "${3}" \
    -sdk "${4}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty
}

# Builds archive for iOS simulator & device
function buildArchive {
  SCHEME=${1}

  archive $SCHEME "generic/platform=iOS Simulator" $(archivePathSimulator $SCHEME) "iphonesimulator"
  archive $SCHEME "generic/platform=iOS" $(archivePathDevice $SCHEME) "iphoneos"
}

# Creates xc framework
function createXCFramework {
  FRAMEWORK_ARCHIVE_PATH_POSTFIX=".xcarchive/Products/Library/Frameworks"
  FRAMEWORK_SIMULATOR_DIR="$(archivePathSimulator $1)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  FRAMEWORK_DEVICE_DIR="$(archivePathDevice $1)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  xcodebuild -create-xcframework \
            -framework ${FRAMEWORK_SIMULATOR_DIR}/${1}.framework \
            -framework ${FRAMEWORK_DEVICE_DIR}/${1}.framework \
            -output ${OUTPUT_DIR_PATH}/xcframeworks/${1}.xcframework
}

echo "#####################"
echo "▸ Cleaning the dir: ${OUTPUT_DIR_PATH}"
rm -rf $OUTPUT_DIR_PATH

#### Dynamic Framework ####

DYNAMIC_FRAMEWORK=$SDK_NAME

echo "▸ Archive $DYNAMIC_FRAMEWORK"
buildArchive ${DYNAMIC_FRAMEWORK}

echo "▸ Create $DYNAMIC_FRAMEWORK.xcframework"
createXCFramework ${DYNAMIC_FRAMEWORK}