download_path='/mnt/c/Users/sbn/Downloads'
model='rtx830'
sshconfig_hostname='rtx'

cd $download_path
# http://www.rtpro.yamaha.co.jp/RT/FAQ/Install/revision-up.html
checksum=`md5sum $model.bin -c $model.md5`
echo $checksum
if [[ $checksum =~ "OK" ]];
then
    # http://www.rtpro.yamaha.co.jp/RT/docs/sftpd/
    echo "put $model.bin system/exec0" | sftp $sshconfig_hostname
else
    exit 1
fi
