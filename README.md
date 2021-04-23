# rtxconfig

## 解説

YAMAHA RTX830 をSSHで設定する - 俺の外付けHDD  
https://nyanshiba.com/blog/yamahartx-settings

## 目的

- RTX830のconfigをGitで管理する
- [main](https://github.com/nyanshiba/rtxconfig/tree/main) configの更新をconfig -> privateブランチに一方向で反映させ、プライベートな内容を含まないブランチとして、できる限りオープンにする
- [main](https://github.com/nyanshiba/rtxconfig/tree/main) Gitでの管理を容易にするシェルスクリプトを公開する
- private WebGUIでエクスポートしていた古いconfigも記録する

## つかいかた

```sh
# GitHubに公開鍵を置いてない場合・通常
git clone https://github.com/nyanshiba/rtxconfig.git -b main
git clone https://github.com/nyanshiba/rtxconfig.git -b config

# git pullで更新したい場合
git clone git@github.com:nyanshiba/rtxconfig.git -b main
```

- [get-config.sh](get-config.sh)  
sftpでRTXからconfigを取得し、[config.txt](config.txt)に上書きする。  
Gitの操作は行わない。  
sftpでrtxとやり取りする設定及び`~/.ssh/config`の設定、[get-config.sh](get-config.sh)内の設定が行われている前提。デフォルトでは`Host rtx`の設定になっている。

- [add-webgui-config-to-git.sh](add-webgui-config-to-git.sh)  
WebGUIで怠惰にエクスポートしていた古いconfigを連番通り再帰的にGitに記録する。  
`git add .`や`git commit -m "ファイル名"`の操作も行われる。  
WebGUIでエクスポートしたconfigとsftpでgetしたconfigはフォーマットが異なるが関与しない。diffが汚くなる。
