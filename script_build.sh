#!/bin/bash
#nuke out
rm -rf out
mkdir out
cd clang
find . | grep -v 'clang-r370808' | xargs rm -rf
cd ..

export BOT_API_TOKEN=
export chat_id=
export KBUILD_BUILD_USER=Atif Siddiqui
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Release type
if [ $BRANCH == "ten" ]; then
        export TYPE=old-cam
elif [ $BRANCH == "new-cam" ]; then
        export TYPE=new-cam
fi

export ZIPNAME=$TYPE-QuantumKernel.zip

# Set COMPILER
export KBUILD_COMPILER_STRING="Clang Version 10.0.1"
export ARCH=arm64 && export SUBARCH=arm64

# compilation
START=$(date +"%s")
make O=out ARCH=arm64 santoni_treble_defconfig
make -j4 O=out ARCH=arm64 CC="$(pwd)/clang/clang-r370808/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-androideabi-" 
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip
if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]
	then

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code> 
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code> 
<i>Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</i>" -d chat_id=${chat_id} -d parse_mode=HTML

cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel 
        cd anykernel 
        zip -r9 QuantumKernel.zip * -x README.md QuantumKernel.zip

curl -F chat_id="${chat_id}" -F document=@"$(pwd)/kernel.zip" https://api.telegram.org/bot${BOT_API_TOKEN}/sendDocument
        rm -rf QuantumKernel.zip && rm -rf Image.gz-dtb
cd .. 
rm -rf out 

else

        curl -s -X POST         https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage         -d text="${TYPE} build finished with errors..." -d         chat_id=${chat_id} -d parse_mode=HTML
    exit 1
fi
