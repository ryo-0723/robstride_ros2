# EDULITE05 エンコーダー確認（2026-10-27）

## 結論と実測

**今回接続したID 33では、モーター電源再投入後に`mechPos`の出力から3回転分が失われた。**
ROS 2の読出しノードとUSB–CANブリッジを起動したまま、ユーザーがモーター電源を
入れ直した試験で確認した。ドライバーの角度復元はまだ実装していない。
この観測だけでは、別の保存領域や明示的な保存・初期角設定による復元がないとは断定できない。
追加調査で公式サンプルの回転数パラメータと、MotorStudioの初期多回転基準角が見つかった。
詳細は末尾の追記を参照。
その後、公式11リポジトリの全公開参照、配布FWの保存表、Type 9による実機読出しまで確認した。
最新の根拠と調査範囲は[保存・復元処理の公開資料調査](edulite05_retention_audit.ja.md)を参照。

| 対象 | 電源断前 `mechPos` [rad] | 再投入後 [rad] | 観測結果 |
|---|---:|---:|---|
| ID 33 | 21.3807964325 | 2.5310683250 | 約3回転分減少 |
| ID 34 | 3.1587648392 | 3.1587648392 | 1回転内の角度を維持 |

ID 33の差は18.8497281075 rad = 3 × 2π + 0.0001721859 rad。
この残差は単回転14 bitの1カウント相当（2π/16384 ≈ 0.0003835 rad）より小さい。
この比較は公称分解能との比較であり、絶対精度を測定したものではない。
応答間隔の最大値はID 33が4.502秒、ID 34が4.515秒だった。
軸を固定して電源を入れ直す手順を依頼したが、軸の固定を独立したセンサーで検証してはいない。

両機とも `run_mode=0`、`zero_sta=0`、`add_offset=0`。
母線電圧は約24.1～24.3 V。停止指令Type 4をそれぞれ送信した後も上表の再投入後角度を維持し、
Type 2のmode=Reset、fault=0を受信した。**停止のReset状態と角度のゼロ設定は別である。**

`iq_test`（0x702D）は両機ともType 17応答の失敗ステータス1を返した。
未対応・読出し不能等の原因は未特定。値0として扱ってはいけない。
ID 1・32・35・127には今回の読出しで応答がなかった。非接続かどうかまでは断定しない。

## 仕様を分けて扱う

| 項目 | 公式資料の記載／今回確認できた範囲 |
|---|---|
| 磁気エンコーダー | 仕様紹介は2個。使用説明書は14 bit・単回転絶対値と記載 |
| 減速比 | EL05は9:1。通信の`mechPos`は負荷側角度なので内蔵減速比をもう一度掛けない |
| Type 2の角度 | 16 bit正規化。新しい仕様は−4π～4πを周期的に循環 |
| `mechPos`、0x7019 | float32の負荷側計数角度。今回21.38 radを読み取れたためType 2の範囲とは異なる |
| `zero_sta=0` | 電源投入時の位置範囲0～2π。今回の再投入後の値も範囲内 |
| `zero_sta=1` | 電源投入時の位置範囲−π～π。今回設定しての確認は未実施 |
| `zero_sta`の保存 | Type 18で変更した場合はType 22で保存するとの明記あり |
| `add_offset`、0x702B | ゼロ位オフセット、float32。今回0を読出し。符号・反映時点・保存後の保持は未実測 |
| Type 6 | 現在位置を機械ゼロに設定。CSP・運動制御モードで対応、PPでは無効 |
| Type 6後の電源断 | 今回の資料は永続化条件を明示しておらず、既存の機械原点を変更する試験も未実施。保持を保証しない |
| Type 22 | パラメータ保存。動的な多回転計数を保持する機能とは確認できない |

単回転絶対値は、無通電中の回転数まで記録することを意味しない。
磁気エンコーダーが2個あることも、不揮発の多回転カウンターの保証にはならない。
`mechPos`についてもfloat32であることから無制限の分解能・無限回転を保証しない。
上位機内部の0x20xx・0x30xxの表と、Type 17/18の0x70xxの表は別に記載されている。
例えば内部表の`rotation`（0x3014）をType 17で読めるとは今回確認していない。

説明書には、古いFWでType 6を送ると目標と実測の差により回転し得ること、
新しいFWでは目標も0へ更新することが書かれている。機械原点の保持を試験する場合は、
既存の原点・オフセットを記録し、駆動を停止した構成で試験を分ける必要がある。

## 公式SDKとの照合

公式`RobStride/EDULITE_A3`のコミット`088b166cf08ec110c1d6c3af42f0a73468b847cb`を確認した。
`set_zero_position()`はType 6を送るだけで、`save_parameters()`（Type 22）とは独立している。
SDKの送信成功を表すboolは、電源再投入後の保持を検証した結果ではない。
`SetZeroPosition()`は制御ループを止め、ゼロ設定後に目標を受信状態へ合わせている。

バージョン照会には資料とSDKに相違がある。説明書はType 4に
`00 C4 00 00 00 00 00 00`、SDKは同じデータをType 26で送っている。
**今回の実機は説明書のType 4で応答した。** 両機とも返答は
`00 C4 56 0A 05 00 02 07`。説明書のByte3～6を順に読むと`10.5.0.2`相当。
生のバイト列を一次記録とし、Byte7の意味は今回断定しない。Type 26は未送信。
バージョン応答もType 2を使うため、通常の位置フィードバックと誤認しない必要がある。

## このリポジトリでの対応

現在の`robstride_driver`は受信したType 2の角度に方向・外付け減速比・固定offsetを適用する。
Type 2の折返し補正、`mechPos`の位置状態への利用、電源断後の回転数復元はない。
`set_zero_on_activate`のドライバー既定値はfalseだが、サンプルURDFではtrue。
角度を継続して扱う構成では、activateのたびに原点を変更しない設定が必要になる。

通常の位置・速度・トルク指令は運動制御モード`run_mode=0`で実現している。
内蔵PP/CSP/速度/電流モード、汎用のパラメータ操作API、Type 22保存、詳細故障Type 21、
`zero_sta`・`add_offset`の設定、電源断からの設定再適用・角度復元は利用者向け機能として未搭載。
本調査ではこれらの制御機能や自動復帰を追加していない。

希望する角度継続には、最後の連続角度qと復帰後の単回転角aから
`q_restored = a + 2π × round((q − a) / (2π))`として回転数を選ぶ方法がある。
今回のID 33では、2.5310683250 + 3 × 2π = 21.3806242466 radとなり、
遮断前との差は約0.0001722 radだった。
この復元が一意になるには、通信途絶中の移動量がπ未満である等の前提が必要。
無通電中に何回転でも動く場合は、この方法では元の回転数を特定できない。

実装時は通常時の計数、途絶検出、再接続時の設定確認、角度の復元、指令側の座標変換を一体で扱う。
Type 2の周期（8π）と電源再投入後の単回転の曖昧さ（2π）を混同しない。
1回転内の`mechPos`と`zero_sta`だけでは再起動を必ず検出できるわけではなく、
短い電源断や通信欠落の識別も別途設計する必要がある。

## 再現と記録

Windowsの共有済みCH340（BUSID 1-1、COM5）を`usbipd attach --wsl --busid 1-1`でWSLへ接続。
`/dev/ttyUSB0`、921600 baud、ホストID 253を使用した。
指定された`ros2_robstride_usb_can_bridge`をローカルソースからビルドし、
ROS_DOMAIN_ID=231の検証用コンテナでブリッジと読出しノードを起動した。
既存のシミュレーションとはROSドメインを分けた。

```bash
ros2 run robstride_usb_can_bridge robstride_usb_can_bridge --ros-args -p device:=/dev/ttyUSB0
# 同じROS環境・domainの別ターミナル
ros2 run robstride_examples encoder_probe.py --ids 33 34 --duration 180 > power-cycle.jsonl
```

`encoder_probe.py`が送るのはType 17のみ。
ゼロ設定・保存・有効化・回転は行わない。今回の停止・バージョン照会は別スクリプトで行った。
パッケージのビルド・インストール後の`ros2 run ... --help`、Python構文、実機の送受信を確認した。

生記録は`/tmp/el05-encoder-check/`に保存した。一時領域のため永続保管は別途必要。

- `baseline.jsonl`: ID候補のパラメータ読出し。
- `power-cycle.jsonl`: 同一ノードでの電源断前後の連続記録。
- `stop-version.jsonl`: 停止とType 4バージョン照会の送受信。
- `bridge.log`、`monitor-bridge.log`: USB–CANブリッジのログ。

## 参照資料

- [公式EL05中国語説明書260922](https://github.com/RobStride/Product_Information/blob/main/产品资料/CAN2.0/EL05/EL05使用说明书260922.pdf): 本文p.9、p.31、p.33、p.35～37。PDFのファイル先頭からのページ番号とは異なる。
- [公式EL05英語説明書260713](https://github.com/RobStride/Product_Information/blob/main/Product%20Literature/CAN2.0/EL05/EL05User%20Manual260713.pdf): 中国語版との照合に使用。起動範囲やP_MINの符号に訳抜けがあるため中国語原文も確認した。
- [公式ELシリーズ仕様紹介2026-09-22](https://github.com/RobStride/Product_Information/blob/main/灵足时代EL系列产品规格介绍(2026.09.22）.pdf): エンコーダー2個の記載。
- [公式SDK can_driver.py](https://github.com/RobStride/EDULITE_A3/blob/088b166cf08ec110c1d6c3af42f0a73468b847cb/el_a3_sdk/el_a3_sdk/can_driver.py)
- [公式SDK interface.py](https://github.com/RobStride/EDULITE_A3/blob/088b166cf08ec110c1d6c3af42f0a73468b847cb/el_a3_sdk/el_a3_sdk/interface.py)

## 追加調査：回転数と保存先の候補

「どこかに保存されていないか」という指摘を受け、公式STM32サンプル、ROSサンプル、
Pythonサンプル、MotorStudio説明書を追加確認した。前の試験は`mechPos`の再初期化を示すが、
保存機能全体を否定する試験にはなっていない。

| 候補 | 公式ソースでの状態 | EL05実機の確認 |
|---|---|---|
| `rotation` / 0x701D | STM32・ROSサンプルではint16の読取専用回転数。Pythonではfloat32の定義をコメントアウト | **Type 17で読出し成功**。ID 33=`FA FF 00 00`、ID 34=`04 00 00 00`（値領域4 byte） |
| `MechPos_init` / 0x2006 | MotorStudio説明書241122は「初期多回転時の参考角度」、float、R/W、−50～50と記載 | Type 17では失敗ステータス1。EL05説明書260922では同じアドレスの名称は`status4`、予約項目 |
| `rotation` / 0x3014 | EL05説明書の内部表にある回転数、int16 | Type 17では失敗ステータス1。専用の上位機経路から読めないことまでは示さない |
| Type 22保存 | STM32サンプルのコメントは単一パラメータ書込表のデータを再投入後の既定値として保存すると説明 | 今回は未送信。回転数・初期多回転基準角が保存対象かは未確認 |

0x701Dの値領域をC++サンプルに合わせてlittle-endian int16で読むと、ID 33は−6、ID 34は4。
これは出力軸の絶対回転数として検証した値ではない。ローター側の計数か、初期化による
基準の違いがあるか等は、制御した回転と電源再投入前後の同時記録で確認する必要がある。
このパラメータは前回の電源断試験では読んでいないため、その保持性はまだ判断できない。

公式ROSサンプルは0x701Dを宣言しているが、実際のType 17応答処理はindex番号0～13までで、
14番目の0x701Dを処理していない。定義の存在と動作する復元実装を区別する必要がある。
今回確認した公式コードには、回転数を保存し、電源再投入後に連続角へ戻す処理は見つからなかった。
これは公開ホスト側コードの調査結果であり、モーター内部FWの全保存領域を確認した結果ではない。

`MechOffset`（0x2005）、0x2006、0x201C、0x201D、0x2021、0x2023、
0x3014～0x3016、0x3031～0x3037もType 17で読出しを試みたが、両機とも失敗ステータス1。
読めなかった項目を0や未実装と判定しない。生記録は
`/tmp/el05-encoder-check/internal-parameters.jsonl`に保存した。

調査ツールに`--indices`を追加した。型が未確定の項目は値を自動解釈せず、生フレームを残す。

```bash
ros2 run robstride_examples encoder_probe.py --ids 33 34 \
  --indices 0x7019 0x701D --duration 30 > position-and-rotation.jsonl
```

次に区別すべき試験は、(1)多回転位置へ動かした前後での0x701DとmechPosの関係、
(2)同じ姿勢のまま電源再投入した際の両値、(3)Type 22を明示した場合の違い、
(4)EL05対応の上位機経路で初期基準角を操作できるか、である。
今回の追加試験は読み取りだけで、保存・原点変更・回転は行っていない。

追加参照：

- [公式ROSサンプルのrotation定義](https://github.com/RobStride/robstride_ros_sample/blob/d4751f3f16f3593a4e587738b6e27b949b4999ba/include/motor_ros2/motor_cfg.h#L166)
- [公式ROSサンプルの受信処理](https://github.com/RobStride/robstride_ros_sample/blob/d4751f3f16f3593a4e587738b6e27b949b4999ba/src/motor_cfg.cpp#L87)
- [公式STM32サンプルのType 22保存処理](https://github.com/RobStride/SampleProgram/blob/5f598686b05fcc527ee0fc0ea954f0afd652b234/RS/Robstride01.cpp#L681)
- [公式Pythonサンプルのパラメータ定義](https://github.com/RobStride/Python_Sample/blob/main/robstride_dynamics/protocol.py)
- [公式MotorStudio説明書241122](https://github.com/RobStride/MotorStudio/blob/main/使用说明书-Instructions/灵足时代上位机使用说明书_241122.pdf): 設定表の`MechPos_init`。EL05現行FWでの適用可否は未確認。
