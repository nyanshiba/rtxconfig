(echo 'mkdir sd1/lua'; echo "put $1 /sd1/lua/") | sftp rtx
echo "usage:"
echo "luac -s -o $1c $1"
echo "lua $1c"
