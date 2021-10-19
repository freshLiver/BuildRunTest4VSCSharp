# --------------------------------DEPENDENCY--------------------------------

# 用 Git Bash 執行此 Script (才能用 Bash Commands)
# https://github.com/git-for-windows/git/releases/tag/v2.33.1.windows.1


# Git Bash 預設路徑
LINE_END="CR"				# CR for UNIX/Linux, CRLF for Windows
DOS2UNIX="dos2unix"


# 用 MSBuild 編譯方案
# https://docs.microsoft.com/en-us/visualstudio/msbuild/walkthrough-using-msbuild?view=vs-2019
MSBuild="C:/Windows/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe"
FRAMEWORK_VERSION="v4.6"


# dotnet core sdk
# https://dotnet.microsoft.com/download/dotnet/5.0
DOTNET="dotnet"
DOTNET_CORE_BIN="../fucking"

# --------------------------------作業相關設定--------------------------------

WEEK_NO=3                       # 週次
PRACTICE_NO=1                   # 作業 1 or 2
NUM_OF_TESTS=4                  # 測資數量
DIFF=true                       # 是否使用 diff 比較輸出，注意檔案的換行（UNIX=LF/DOS=CRLF）

# 預設路徑說明
#
# TargetSolutionDir/
# ├──TargetSolutionFile.sln     # 目標方案檔
# └──AnyDir/                    
#     ├── BuildRunTest.sh       # This Script
#     └── W3P1                  # 測資資料夾（W${WEEK_NO}P${PRACTICE_NO}）
#         ├── ans1.txt          # 測資 N 的答案（只有 DIFF = true 時會用到）
#         ├── ans2.txt          
#         ├── out1.txt          # 執行測資 N 的輸出
#         ├── out2.txt          
#         ├── test1.txt         # 測資，從 1 開始編號，副檔名須為 txt
#         └── test2.txt         

# ----------------------------------其他設定----------------------------------

# 分隔線
SPLITLINE="--------------------------------------------"

HighLight () {
    # 第一個參數為訊息
    echo -e "\e[1;41m$1\e[m"

    # 第二個參數為是否暫停
    if [ "$2" = "true" ]; then
        read
    fi
}

# --------------------------------獲取專案資訊--------------------------------

# 方案檔（.sln）＆ 專案檔（.csproj）檔名
csproj="$(ls -1 .. | grep '\.csproj')"          # 專案檔檔名（含副檔名，可能為未定義，用來判斷執行檔路徑）
sln="$(ls -1 .. | grep '\.sln')"

# 從方案檔（.sln）中提取 project 資料夾名稱
project="$(cat "../$sln" | grep -oE "=\ \"[^\"]*\"" | sed -E "s/(=\ |\")//g")"

# 執行檔相對路徑
if [ "$csproj" ]; then
    EXE_PATH="../bin/Debug/${project}.exe"                # 同資料夾，不用進入專案資料夾
else
    EXE_PATH="../${project}/bin/Debug/${project}.exe"     # 不同資料夾，需要進入專案資料夾（$project）
    csproj="${project}/${project}.csproj"                # 正確 .csproj 的路徑
fi

# 從 csproj 獲取 target framework
FuckingDotNetCore="$(cat "../$csproj" | grep -i framework | grep -oE ">.*<" | grep -i "net" )"

if [ $FuckingDotNetCore ]; then 
    EXE_PATH="$DOTNET_CORE_BIN/${project}.exe"
fi

# ----------------------------------輸入模式----------------------------------

echo "所有模式 : "
echo "1) 重建專案、執行、輸入測資"
echo "2) 執行、輸入所有測資"
echo "3) 執行、並輸入特定測資（稍後輸入）"
echo "4) 僅執行、不輸入測資"

echo -n "輸入模式編號 : "
read mode


if [ "$mode" = "3" ]; then
    echo -n "要執行哪個測資 : "
    read TARGET_TEST

    NotNumber=$(echo $TARGET_TEST | grep -E "[^0-9]+")

    if [ $NotNumber ] || [ ! $TARGET_TEST ] ; then
        mode="ERROR_TEST_NO"
    else
        if [ 1 -le $TARGET_TEST ] && [ $TARGET_TEST -le $NUM_OF_TESTS ]; then
            FIRST_TEST_NO=$TARGET_TEST
            LAST_TEST_NO=$TARGET_TEST
        else 
            mode="ERROR_TEST_NO"
        fi
    fi  

else
    FIRST_TEST_NO=1
    LAST_TEST_NO=$NUM_OF_TESTS
fi

echo $SPLITLINE


# ------------------------------執行對應模式的工作------------------------------

if [ "$mode" = "1" ]; then

    HighLight "按 ENTER 繼續建制專案：'$project' ..." true

    # 根據 framework 使用 dotnet or msbuild 建制專案
    if [ ! $FuckingDotNetCore ]; then
        # clean and build
        $MSBuild "../$sln" //t:Clean,Build //p:TargetFrameworkVersion="${FRAMEWORK_VERSION}"
    else
        # publish dotnet core app
        HighLight "${sln} 是該死的 dotnet 專案，按 ENTER 繼續" true
        $DOTNET publish "../${sln}" -c Debug -r win10-x64 -o "$DOTNET_CORE_BIN"
    fi


    HighLight "按 ENTER 繼續 ..." true
fi 

# 模式 1,2,3,4
case "$mode" in 
    "1" | "2" | "3" | "4" )

        # 純執行，不使用測資自動輸入
        if [ "$mode" = "4" ]; then 

            "$EXE_PATH"

        # 執行並使用測資輸入
        else
            # 測資資料夾
            TEST_DIR="./W${WEEK_NO}P${PRACTICE_NO}"

            for i in $(eval echo {$FIRST_TEST_NO..$LAST_TEST_NO}); do

                # 此次測資輸入、輸出、答案路徑
                INPUT="${TEST_DIR}/test${i}.txt"
                OUTPUT="${TEST_DIR}/out${i}.txt"
                ANSWER="${TEST_DIR}/ans${i}.txt"

                HighLight "CASE ${i} 輸出結果 : ${SPLITLINE}"

                # 執行、輸入測資並用 diff 比較結果
                if [ "$DIFF" = true ]; then
                    
                    # 執行、輸入測資並將結果存到對應輸出檔
                    "$EXE_PATH" < "$INPUT" > "$OUTPUT"

                    # 將輸出檔轉換成 UNIX 結尾（CR）
					if [ "$LINE_END" = "CR" ]; then
						"$DOS2UNIX" -k "$OUTPUT"
					fi

                    # 用 diff 比對結果
                    diff --color=always -u "$OUTPUT" "$ANSWER"

                    HighLight "按 ENTER 繼續 ..." true

                # 純執行、輸入測資，結果會直接印出來，不使用 diff 比對結果也不輸出檔案
                else
                    "$EXE_PATH" < "$INPUT"
                fi
            done
        fi
        ;;

    "ERROR_TEST_NO" )
        HighLight "測資編號錯誤 ..."
        ;;

    * )
        HighLight "錯誤模式 ..."
        ;;
esac

# --------------------------------結束 Script--------------------------------
HighLight "按 ENTER 結束 ..." true
