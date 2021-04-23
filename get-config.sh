sshconfig_hostname='rtx'
# ~/.ssh/configの設定でsftpを使ってconfigをダウンロード
echo "get system/config config.txt" | sftp $sshconfig_hostname
