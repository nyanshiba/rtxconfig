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

- [bug6to4.sh](bug6to4.sh)  
syslogに、1オクテット目が32.や36.から始まる海外IPが出力されたときに確認できるスクリプト。IPv6プレフィックス先頭2ヘクステットをIPv4アドレス4オクテットに変換。

|IPv4アドレス表記で解釈|対応するIPv6 IPoEプレフィックス|VNE|NTT|
|:-|:-|:-|:-|
|32.1.15.112/30|2001:0f70::/30|VECTANT - ARTERIA Networks Corporation|東|
|32.1.15.116/30|2001:0f74::/30|VECTANT - ARTERIA Networks Corporation|西|
|36.0.36.16/30|2400:2410::/30|GIGAINFRA - SoftBank Corp.|東|
|36.0.38.80/30|2400:2650::/30|GIGAINFRA - SoftBank Corp.|西|
|36.0.64.80/30|2400:4050::/30|OCN - NTT DOCOMO BUSINESS,Inc.|東|
|36.0.65.80/30|2400:4150::/30|OCN - NTT DOCOMO BUSINESS,Inc.|西|
|36.1.77.64/30|2401:4d40::/30|CYBERHOME1 - FAMILY NET JAPAN INCORPORATED|東|
|36.1.77.68/30|2401:4d44::/30|CYBERHOME2 - FAMILY NET JAPAN INCORPORATED|西|
|36.4.122.128/30|2404:7a80::/30|BIGLOBE - BIGLOBE Inc.|東|
|36.4.122.132/30|2404:7a84::/30|BIGLOBE - BIGLOBE Inc.|西|
|36.5.101.128/30|2405:6580::/30|ASAHI-NET - Asahi Net|東|
|36.5.101.132/30|2405:6584::/30|ASAHI-NET - Asahi Net|西|
|36.6.171.72/30|2406:ab48::/30|GSS-NET - Digital Agency|東|
|36.6.171.76/30|2406:ab4c::/30|GSS-NET - Digital Agency|西|
|36.9.0.16/30|2409:0010::/30|MF-NATIVE6-E - INTERNET MULTIFEED CO.|東|
|36.9.2.80/30|2409:0250::/30|MF-NATIVE6-W - INTERNET MULTIFEED CO.|西|
|36.11.0.16/30|240b:0010::/30|KDDI - KDDI CORPORATION|東|
|36.11.2.80/30|240b:0250::/30|KDDI - KDDI CORPORATION|西|
|36.11.192.196/30|240b:c0c4::/30|RMNI-AS-AP - Rakuten Mobile Network, Inc.|東|
|36.11.192.204/30|240b:c0cc::/30|RMNI-AS-AP - Rakuten Mobile Network, Inc.|西|

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">あーこのオープンリゾルバになっているかのようなsyslogが記録されるのも、RTXの潜在的なバグによるものか。<br>2001:db8なら32.1.13.184になるから、Prefixから36.0-15.n.n/32を計算してBogonフィルタといっしょに書いておくと予期せぬ発呼を予防できていいかもね<a href="https://t.co/Hfuy0Xj4nk">https://t.co/Hfuy0Xj4nk</a></p>&mdash; しばにゃん (@shibanyan_1) <a href="https://x.com/shibanyan_1/status/1643104776400560129">April 4, 2023</a></blockquote>
