# WebGUIでエクスポートした古いconfigを連番通りに追加する
echo "WebGUIでエクスポートした古いconfigの場所を入力:"
read sourcedir
if [ "$sourcedir" != "" ]; then
    for file in `\find ${sourcedir} -maxdepth 1 -type f | sort -V`; do
        echo `basename $file`
        cp $file config.txt
        git add config.txt
        git commit -m `basename $file`
    done
else
    echo "configの場所を入力して下さい"
fi
