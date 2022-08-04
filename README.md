# blacklist

## Purpose / 目的

A project for adding IP addresses to AWS WAF using the AWS CLI.
Block access to the site by registering the client IP with her WAF when there is an access that seems to be an attack.

AWS CLI を使って AWS WAF に IP アドレスを追加するためのプロジェクト。
攻撃と思われるアクセスがあった場合に、クライアント IP を WAF に登録することでサイトへのアクセスをブロックする。

### Prerequisites / 前提条件

Register the client IP in IP Sets named BLACK_LIST.
Therefore, do the following in advance.

クライアント IP は BLACK_LIST という名前の IP Sets に登録する。
そのため、事前に以下を実施しておくこと。

1. Register IP Sets with the name BLACK_LIST / BLACK_LIST という名前で IP Sets を登録する
2. Set the WAF to "block requests from IP addresses registered in BLACK_LIST" / 「BLACK_LIST に登録されている IP アドレスからのリクエストはブロックする」というルールを WAF に設定する

## Advance preparation / 事前準備

### Have the aws command installed / aws コマンドをインストールしておく

The installation method is optional. It can be a Docker image.

インストール方法は任意。Docker イメージでも構わない。

```sh
➜  aws --version
aws-cli/2.4.29 Python/3.9.12 Darwin/19.6.0 source/x86_64 prompt/off
```

### Register a profile / プロファイルを登録しておく

Register your profile using IAM credentials.csv.
Specify this profile as an option in the shell script.

IAM の credentials.csv を使用してプロファイルを登録する。
このプロファイルをシェルスクリプトのオプションに指定する。

## execution / 実行

I prepared the `usage` function. The output is as follows.

`usage` 関数を用意した。出力は以下の通り。

```sh
➜  ./function.sh --help
Description:
    function.sh is a tool that adds an IP address to your AWS WAF. The IP address is added to the IP set called BLACK_LIST.
    [Caution] Please register BLACK_LIST in advance.

    function.sh は AWS WAF に IP アドレスを追加するツールです。この IP アドレスは BLACK_LIST という IP Sets に追加されます。
    【注意】BLACK_LIST は事前に登録しておいてください。

Usage:
    function.sh --profile PROFILE_NAME ip_address

Options:
    --help      print this.
                これを出力します。
    --profile   Specify the profile of the AWS account to which you want to add the IP address.
                IP アドレスを追加したい AWS アカウントのプロファイルを指定します。

Caution:
    ip_address  Since only CIDR addresses of / 8, / 16, / 24, / 32 can be registered, "/ 32" is automatically added to the argument address.
                登録できるアドレスは /8, /16, /24, /32 の CIDR アドレスのみとなるため、引数のアドレスに "/32" を自動で追加します。
```
