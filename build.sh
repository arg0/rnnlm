#!/bin/sh
CUR_PATH=`pwd`
PROJECT_PATH=`dirname $CUR_PATH`
SVN_ADDR=""
PARALLEL_NUM=5
SSHPASS="$CUR_PATH/sshpass"
ERROR_INFO="$CUR_PATH/.ERROR_INFO"
BACKUP_NUM=5
rm -f $ERROR_INFO
CURRENT_TIME=`date +%Y%m%d%H%M%S`
function abnormal_exit()
{
    echo $@
    echo "[FATAL]$@" >> $ERROR_INFO
    exit 1
}
function record_error_info()
{
    echo "[FATAL]$@" >> $ERROR_INFO
}
function random_p()
{
    echo $RANDOM$RANDOM$RANDOM$$
}
function execshell()
{
    echo "[execshell]$@ begin."
    eval $@
    [[ $? != 0 ]] && {
        echo "[execshell]$@ failed."
        exit 1
    }
    echo "[execshell]$@ success."
    return 0
}
function trap_exit()
{   
    trap "exit_procprocess $@" 0
}
trap_exit
function exit_procprocess()
{   
    local ret=$?
    kill -9 `pstree $$ -p|awk -F"[()]" '{for(i=1;i<=NF;i++)if($i~/[0-9]+/)print $i}'|grep -v $$` 2>/dev/null
    [[ -f $ERROR_INFO ]] && ret=1
    cat $ERROR_INFO 2>/dev/null
    exit $ret
}

function install_tools()
{   
    mkdir -p /$HOME/bin
    if [[ ! -d "thirdparty" ]]
    then
        tar Jxf thirdparty.tar.xz
    fi
    if [[ ! -d "/$HOME/.blade" ]]
    then
        cp -rf ./thirdparty/blade /$HOME/.blade
        sh /$HOME/.blade/install
    fi
    chmod -R 755 /$HOME/bin
    sed -i '/LOCAL_BUILD_PATH/d' $HOME/.bash_profile
    echo "LOCAL_BUILD_PATH=\$HOME/bin" >> $HOME/.bash_profile
    echo "export PATH=\$LOCAL_BUILD_PATH:\$LOCAL_BUILD_PATH/blade:\$PATH" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    cd $CUR_PATH
}

function build_common()
{
    mode=${1:-"release"}
    common_dir="app"
    for component in ${common_dir} 
    do
        execshell "cd ./$component"
        execshell "blade test ... -j8 -p ${mode}"
        execshell "cd -"
    done
    #python_dir="wrapper"
    #for component in ${python_dir}
    #do
    #    execshell "cp -rf ./app/${component} ./build64_release/app/."
    #    execshell "cd ./app/${component}"
    #    execshell "sh ./build.sh"
    #    execshell "cd -"
    #done
    bin="./output/bin"
    if [[ ! -d ${bin} ]]
    then
        execshell "mkdir -p ${bin}"
    fi
    src_path="./build64_release"
    for src_com in \
        "app/rnnlm/rnnlm"
    do
        execshell "cp $src_path/$src_com ${bin}"
    done
    return 0
}

function build_cov()
{
    mode=${1:-"release"}
    common_dir="app"
    for component in ${common_dir} 
    do
        execshell "cd ./$component"
        execshell "blade test --gcov ... -j8 -p ${mode}"
        execshell "cd -"
    done
    #python_dir="wrapper"
    #for component in ${python_dir}
    #do
    #    execshell "cp -rf ./app/${component} ./build64_release/app/."
    #    execshell "cd ./app/${component}"
    #    execshell "sh ./build.sh"
    #    execshell "cd -"
    #done
    bin="./output/bin"
    if [[ ! -d ${bin} ]]
    then
        execshell "mkdir -p ${bin}"
    fi
    src_path="./build64_release"
    for src_com in \
        "app/rnnlm/rnnlm"
    do
        execshell "cp $src_path/$src_com ${bin}"
    done
    return 0
}

function build_release()
{
    build_common "release"
}

function build_debug()
{
    build_common "debug"
}

function build_gprof()
{
    build_common "gprof"
}

function clean_libs()
{
    rm -rf $PROJECT_PATH/libs 
}
function build_clean()
{
    rm -rf CMakeFiles cmake_install.cmake CMakeCache.txt Makefile
    rm -rf output* lib release ftp_url.txt
}
function gen_ftp_url_file()
{
    rm -f ./ftp_url.txt
    echo "" > ./ftp_url.txt
    return 0
}

function usage()
{
    cat <<HELP_END
用法：sh build.sh [参数]
        clean       			        清理当前编译环境和xts运行环境
        debug          				编译debug版本
        release或缺省  				编译release版本
        gprof          				编译gprof版本
        xts            				运行xts功能测试用例
        ci_quick    	   			用于jenkins的QUICK构建
        --help         				显示帮助信息
HELP_END
}
case $1 in
    clean)
        execshell "install_tools"
        execshell "clean_libs"
        execshell "build_clean"
    ;;
    release|'')
        execshell "install_tools"
        execshell "build_clean"
        execshell "build_release"
    ;;
    debug)
        execshell "install_tools"
        execshell "build_clean"
        execshell "build_debug"
    ;;
    gprof)
        execshell "install_tools"
        execshell "build_clean"
        execshell "build_gprof"
    ;;
    utcov)
        execshell "install_tools"
        execshell "clean_libs"
        execshell "build_clean"
        execshell "build_cov"
    ;;
    ci_quick)
        execshell "install_tools"
        execshell "clean_libs"
        execshell "build_clean"
        execshell "build_release"
        execshell "gen_ftp_url_file"
    ;;
    --help|-h|-help|help|*)
        usage
    ;;
esac
exit 0

